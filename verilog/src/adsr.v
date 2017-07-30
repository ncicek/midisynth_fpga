module ADSR(
	input wire clk,
	input wire reset,

	input wire[7:0] voice_index,

	//parameters
	input wire [15:0] attack_amt,
	input wire [15:0] decay_amt,
	input wire [15:0] sustain_amt,
	input wire [15:0] rel_amt,
	input wire key_state,	//0=key unpressed, 1=key pressed

	input wire signed [15:0] input_sample,

	output reg signed [15:0] output_sample
	);

	reg [127:0] din = 127'b0;
	reg [7:0] addr = 8'b0;
	reg write_en;
	wire [127:0] dout;

	ram #(
		.addr_width(8),
		.data_width(128)
	)
	adsr_ram(
	.din(din), .addr(addr), .write_en(write_en), .clk(clk), .dout(dout)
	);


	//reg [15:0] attack_amt_reg;
	//reg [15:0] decay_amt_reg;
	//reg [15:0] sustain_amt_reg;
	//reg [15:0] rel_amt_reg;


	//inernal wire. required to convert unsigned to signed before multiplying
	wire signed [15:0] envelope_truncated;
	assign envelope_truncated = din[37:22];

	reg signed [31:0] output_temp;
	reg cycle;
	reg key_state_reg;

	always @(posedge clk or negedge reset) begin
		if (~reset) begin
			din <= 128'b0;
			addr <= 128'b0;

			//attack_amt_reg <= 16'b0;
			//decay_amt_reg <= 16'b0;
			//sustain_amt_reg <= 16'b0;
			//rel_amt_reg <= 16'b0;

			//state <= 4'b0;
			cycle <= 1'b0;
			//envelope <= 33'd0;
		end
		else begin

			case (cycle)
				0:	begin	//read from mem
					addr <= voice_index;
					write_en <= 1'b0;
					//syncronize key_state
					key_state_reg <= key_state;
					//state <= dout[3:0];
					//key_state <= dout[4];
					//envelope <= dout[37:5];

					//attack_amt_reg <= dout[53:38];
					//decay_amt_reg <= dout[69:54];
					//sustain_amt_reg <= dout[85:70];
					//rel_amt_reg <= dout[101:86];

					cycle <= 1'b1;
				end

				1:	begin //compute and write back to mem
					//addr <= voice_index;
					write_en <= 1'b1;

					//perform envelope modulation
					//output upper 16 bits signed
					output_temp = envelope_truncated * input_sample;
					output_sample <= output_temp[31:16];

					//adsr state machine
					case (dout[3:0])
						0:	begin //note off
							din[37:5] <= 33'd0;
							if (key_state_reg == 1'b1) begin
								//capture adsr params into reg before begining the sequence
								din[53:38] <= attack_amt;
								din[69:54] <= decay_amt;
								din[85:70] <= sustain_amt;
								din[101:86] <= rel_amt;

								din[3:0] <= 4'd1;
							end
						end
						1:	begin //attack
							if (key_state_reg == 1'b0)
								din[3:0] <= 4'd3;
							else if (din[37:5] < (33'h100000000 - dout[53:38]))
								din[37:5] <= din[37:5] + dout[53:38];
							else
								din[3:0] <= 4'd2;
						end

						2:	begin //decay to sustain level
							if (key_state_reg == 1'b0)
								din[3:0] <= 4'd3;
							else if (din[37:5] > (dout[85:70]<<16))
								din[37:5] <= din[37:5] - dout[69:54];
						end

						3:	begin //release
							if (din[37:5] > 33'd0 + dout[101:86])
								din[37:5] <= din[37:5] - dout[101:86];
							else
								din[3:0] <= 4'd0;
						end
					endcase

					cycle <= 1'b0;
				end
			endcase

		end

	end


endmodule
