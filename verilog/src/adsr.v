//This is an implementation of Nigel Redmon's ADSR C++ code found at:
//http://www.earlevel.com/main/2013/06/01/envelope-generators/

//The envelope logic/equations are all his work. I incorporated it into a synthesizable verilog statemachine

`default_nettype none
`define ENV_BITDEPTH 24

//memory write masks
`define	MASK_KEYSTATE 29'b1
`define	MASK_STATE 29'b11110
`define	MASK_ENVELOPE { {`ENV_BITDEPTH{1'b1}}, {5{1'b0}} }


module ADSR(
	i_clk,
	i_reset,
	i_SPI_flag,
	i_SPI_note_status,
	i_SPI_voice_index,
	i_voice_index,
	i_pipeline_state,
	i_sample,
	o_voice_index_next,
	o_sample
	);
	parameter env_bitdepth = `ENV_BITDEPTH;	//adsr envelope resolution

	input wire i_clk;
	input wire i_reset;

	input wire i_SPI_flag;
	input wire i_SPI_note_status;
	input wire [7:0] i_SPI_voice_index;

	input wire[7:0] i_voice_index;
	input wire[1:0] i_pipeline_state;
	input wire signed [15:0] i_sample;

	output reg [7:0] o_voice_index_next;
	output reg signed [15:0] o_sample;

	reg [env_bitdepth-1:0] attackCoef = 24'd16775986;
	reg [env_bitdepth-1:0] decayCoef = 24'd16769492;
	reg [env_bitdepth-1:0] sustainLevel = 24'd11744051;
	reg [env_bitdepth-1:0] releaseCoef = 24'd16769492;

	reg [env_bitdepth-1:0] attackBase = 24'd1599;
	reg [env_bitdepth-1:0] decayBase = 24'd5406;
	reg signed [env_bitdepth-1:0] releaseBase = -24'sd1;

	localparam data_width = env_bitdepth + 5;	//update this with the assignments below

	wire [data_width-1:0] din;
	reg [data_width-1:0] mask;
	reg [7:0] addr = 8'b0;
	reg write_en;
	wire [data_width-1:0] dout;

	//data bus assignments
	wire [env_bitdepth-1:0] dout_envelope;
	wire [3:0] dout_state;
	wire dout_keystate;
	assign dout_envelope = dout[env_bitdepth+4:5];
	assign dout_state = dout[4:1];
	assign dout_keystate = dout[0];

	reg [env_bitdepth-1:0] din_envelope;
	reg [3:0] din_state;
	reg din_keystate;
	assign din[env_bitdepth+4:5] = din_envelope;
	assign din[4:1] = din_state;
	assign din[0] = din_keystate;

	ram #(.addr_width(8),.data_width(data_width))
	adsr_ram(.din(din), .mask(mask),.addr(addr), .write_en(write_en), .clk(i_clk), .dout(dout));

	reg signed[2*env_bitdepth-1:0] multiplied_envelope;
	reg signed [env_bitdepth+1:0] envelope_calculation; //lenght=bitdepth + 1

	//inernal wire. required to convert unsigned to signed before multiplying
	wire signed [16:0] envelope_truncated;
	assign envelope_truncated[15:0] = dout_envelope[env_bitdepth-1:env_bitdepth-16];	//take upper 16 bits of envelope
	assign envelope_truncated[16] = 1'b0;	//signed multiplication requires envelope_truncated to be signed but really its not so set the sign bit to 0;

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
								din_envelope <= {env_bitdepth{1'b0}};	//reset envelope to 0
							end
							else begin
								mask <= `MASK_ENVELOPE;
								din_envelope <= {env_bitdepth{1'b0}};	//reset envelope to 0
							end
						end
						1:	begin //attack
							if (dout_keystate == 1'b0) begin
								mask <= `MASK_STATE;
								din_state <= 4'd3;	//state
							end
							else begin
								multiplied_envelope = dout_envelope * attackCoef;
							  envelope_calculation = attackBase + multiplied_envelope[(2*env_bitdepth-1):env_bitdepth];

								if (envelope_calculation >= ((1'b1 << env_bitdepth)-1)) begin
									mask <= `MASK_STATE|`MASK_ENVELOPE;
									din_envelope <= (1'b1 << env_bitdepth)-1; //saturate at 1.0
									din_state <= 4'd2;//state
								end
								else begin
									mask <= `MASK_ENVELOPE;
									din_envelope <= envelope_calculation;
								end
							end
						end

						2:	begin //decay to sustain level and stay in this state until noteoff
							if (dout_keystate == 1'b0) begin
								mask <= `MASK_STATE;
								din_state <= 4'd3;
							end
							else begin
								multiplied_envelope = dout_envelope * decayCoef;
								envelope_calculation = decayBase + multiplied_envelope[(2*env_bitdepth-1):env_bitdepth];

								if (envelope_calculation <= sustainLevel) begin
									mask <= `MASK_ENVELOPE;
									din_envelope <= sustainLevel; //saturate at sustainLevel
								end
								else begin
									mask <= `MASK_ENVELOPE;
									din_envelope <= envelope_calculation;
								end
							end
						end

						3:	begin //release
							multiplied_envelope = dout_envelope * releaseCoef;
							envelope_calculation = releaseBase + multiplied_envelope[(2*env_bitdepth-1):env_bitdepth];

							if (envelope_calculation <= 26'sd0) begin	//if we have slipped into a negative envelope region
								mask <= `MASK_STATE|`MASK_ENVELOPE;
								din_state <= 4'd0;
								din_envelope <= {env_bitdepth{1'b0}};
							end
							else begin
								mask <= `MASK_ENVELOPE;
								din_envelope <= envelope_calculation;
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
