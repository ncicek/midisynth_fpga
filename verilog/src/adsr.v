 `default_nettype none
module ADSR(
	input wire clk,
	input wire reset,

	input wire[7:0] voice_index,
	input wire signed [15:0] input_sample,

	input wire [15:0] attack_amt,
	input wire [15:0] decay_amt,
	input wire [15:0] sustain_amt,
	input wire [15:0] rel_amt,

	input wire[127:0] adsr_din,
	input wire[7:0] adsr_addr,
	input wire adsr_write_en,
	output wire[127:0] adsr_dout,

	output reg signed [15:0] output_sample
	);

	localparam data_width = 38;	//update this with the assignments below

	wire [data_width-1:0] din;
	reg [7:0] addr = 8'b0;
	reg write_en;
	wire [data_width-1:0] dout;

	//data bus assignments
	wire [32:0] dout_envelope;
	wire [3:0] dout_state;
	wire dout_keystate;
	assign dout[37:5] = dout_envelope;
	assign dout[4:1] = dout_state;
	assign dout[0] = dout_keystate;

	reg [32:0] din_envelope;
	reg [3:0] din_state;
	reg din_keystate;
	assign din[37:5] = din_envelope;
	assign din[4:1] = din_state;
	assign din[0] = din_keystate;

	//two port paramter ram
	//port a is voice_controller side
	//port b is local module side
	dptrueram #(
		.addr_width(8),
		.data_width(data_width)
	)
	adsr_ram (
		.dina(adsr_din),
		.write_ena(adsr_write_en),
		.addra(adsr_addr),
		.clka(clk),
		.douta(adsr_dout),
		.dinb(din),
		.write_enb(write_en),
		.addrb(addr),
		.clkb(clk),
		.doutb(dout)
	);

	//inernal wire. required to convert unsigned to signed before multiplying
	wire signed [15:0] envelope_truncated;
	assign envelope_truncated = dout_envelope[32:17];	//should i use din or dout envelope here?

	reg signed [31:0] output_temp;
	reg cycle;
	//reg key_state_reg;

	always @(posedge clk or negedge reset) begin
		if (~reset) begin
			addr <= 8'b0;
			cycle <= 1'b0;
		end
		else begin
			din_envelope <= dout_envelope;
			din_state <= dout_state;

			case (cycle)
				0:	begin	//read from mem
					addr <= voice_index;
					write_en <= 1'b0;
					cycle <= 1'b1;
				end
				1:	begin //compute and write back to mem
					write_en <= 1'b1;

					//perform envelope modulation
					//output upper 16 bits signed
					output_temp = envelope_truncated * input_sample;
					output_sample <= output_temp[31:16];

					//adsr state machine
					case (dout_state) // state
						0:	begin //note off
							din_envelope <= 33'd0;	//envelope
							if (dout_keystate == 1'b1) begin	//keystate
								din_state <= 4'd1;	//state
							end
						end
						1:	begin //attack
							if (dout_keystate == 1'b0) //keystate
								din_state <= 4'd3;	//state
							else if (dout_envelope < (33'h100000000 - attack_amt))//envelope less than 10000-atackreg
								din_envelope <= dout_envelope + attack_amt;
							else
								din_state <= 4'd2;//state
						end

						2:	begin //decay to sustain level
							if (dout_keystate == 1'b0)
								din_state <= 4'd3;
							else if (dout_envelope > (sustain_amt<<16))
								din_envelope <= dout_envelope - decay_amt;
						end

						3:	begin //release
							if (dout_envelope > 33'd0 + rel_amt)
								din_envelope <= dout_envelope - rel_amt;
							else
								din_state <= 4'd0;
						end
					endcase

					cycle <= 1'b0;
				end
			endcase

		end

	end


endmodule
