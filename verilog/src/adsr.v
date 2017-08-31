//`default_nettype none

//memory write masks
`define	MASK_KEYSTATE 38'b1
`define	MASK_STATE 38'b11110
`define	MASK_ENVELOPE 38'b11111111111111111111111111111111100000


module ADSR(

	input wire i_clk,
	input wire i_reset,

	input wire i_SPI_flag,
	input wire i_SPI_note_status,
	input wire [7:0] i_SPI_voice_index,

	input wire[7:0] i_voice_index,
	input wire[1:0] i_pipeline_state,
	input wire signed [15:0] i_sample,

	input wire [23:0] i_attack_amt,
	input wire [23:0] i_decay_amt,
	input wire [23:0] i_sustain_amt,
	input wire [23:0] i_rel_amt,

	output reg [7:0] o_voice_index_next,
	output reg signed [15:0] o_sample
	);

	localparam data_width = 38;	//update this with the assignments below

	wire [data_width-1:0] din;
	reg [data_width-1:0] mask;
	reg [7:0] addr = 8'b0;
	reg write_en;
	wire [data_width-1:0] dout;

	//data bus assignments
	wire [32:0] dout_envelope;
	wire [3:0] dout_state;
	wire dout_keystate;
	assign dout_envelope = dout[37:5];
	assign dout_state = dout[4:1];
	assign dout_keystate = dout[0];

	reg [32:0] din_envelope;
	reg [3:0] din_state;
	reg din_keystate;
	assign din[37:5] = din_envelope;
	assign din[4:1] = din_state;
	assign din[0] = din_keystate;

	ram #(.addr_width(8),.data_width(data_width))
	adsr_ram(.din(din), .mask(mask),.addr(addr), .write_en(write_en), .clk(i_clk), .dout(dout));


	//inernal wire. required to convert unsigned to signed before multiplying
	wire signed [15:0] envelope_truncated;
	assign envelope_truncated = dout_envelope[32:17];	//should i use din or dout envelope here?

	reg new_update_available;
	reg keystate_update; //buffers incoming updates for the above state machine to service
	reg [7:0] voice_addr_update;    //buffers incoming voice index updates "
	reg signed [31:0] output_temp;

	always @(posedge i_clk) begin
		if (i_reset == 1'b1) begin
			addr <= 8'b0;
			write_en <= 1'b0;
			o_voice_index_next <= 8'b0;
		end
		else begin
			case (i_pipeline_state)
				0:	begin	//read from mem
					addr <= i_voice_index;
					o_voice_index_next <= i_voice_index;
					write_en <= 1'b0;
				end
				1:	begin //compute and write back to mem
					write_en <= 1'b1;

					//perform envelope modulation
					//output upper 16 bits signed
					output_temp = envelope_truncated * i_sample;
					o_sample <= output_temp[31:16];

					//adsr state machine
					case (dout_state) // state
						0:	begin //note off
							if (dout_keystate == 1'b1) begin
								mask <= (`MASK_ENVELOPE|`MASK_STATE);
								din_state <= 4'd1;	//state
								din_envelope <= 33'd0;
							end
							else begin
								mask <= `MASK_ENVELOPE;
								din_envelope <= 33'd0;
							end
						end
						1:	begin //attack
							if (dout_keystate == 1'b0) begin
								mask <= `MASK_STATE;
								din_state <= 4'd3;	//state
							end
							else if (dout_envelope < (33'h100000000 - i_attack_amt)) begin
								mask <= `MASK_ENVELOPE;
								din_envelope <= dout_envelope + i_attack_amt;
							end
							else begin
								mask <= `MASK_STATE;
								din_state <= 4'd2;//state
							end
						end

						2:	begin //decay to sustain level
							if (dout_keystate == 1'b0) begin
								mask <= `MASK_STATE;
								din_state <= 4'd3;
							end
							else if (dout_envelope > (i_sustain_amt)) begin
								mask <= `MASK_ENVELOPE;
								din_envelope <= dout_envelope - i_decay_amt;
							end
						end

						3:	begin //release
							if (dout_envelope > 33'd0 + i_rel_amt) begin
								mask <= `MASK_ENVELOPE;
								din_envelope <= dout_envelope - i_rel_amt;
							end
							else begin
								mask <= `MASK_STATE;
								din_state <= 4'd0;
							end
						end
					endcase
				end
				2: begin    //update ram
					if (new_update_available) begin
							//new_update_available <= 1'b0; //clear the bit
							addr <= voice_addr_update;
							write_en <= 1'b1;
							mask <= `MASK_KEYSTATE;
							din_keystate <= keystate_update;
					end
					else
						write_en <= 1'b0;
				end
			endcase
		end
	end

	//check every clock edge if a new update is avaible and buffer it
	always @(posedge i_clk) begin
		if (i_reset)
			new_update_available <= 1'b0;
		else begin
			if (i_SPI_flag & ~new_update_available) begin
				keystate_update <= i_SPI_note_status;
				voice_addr_update <= i_SPI_voice_index;
				new_update_available <= 1'b1;
			end
			else if (new_update_available & i_pipeline_state==2'd2) //state2 is when we can reset because that is when above block samples new_update_available
				new_update_available <= 1'b0;
		end
	end


endmodule
