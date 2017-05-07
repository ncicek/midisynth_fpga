module ADSR(
	input wire clk,
	input wire reset,

	//parameters
	input wire [15:0] attack_amt,
	input wire [15:0] decay_amt,
	input wire [15:0] sustain_amt,
	input wire [15:0] rel_amt,
	input wire key_state,	//0=key unpressed, 1=key pressed

	//inputs
	input wire signed [15:0] input_sample,



	//state inputs
	input reg [3:0] state_current; //0=off, 1=attack, 2=decay, 3=release
	input reg [32:0] envelope_current;

	//state outputs
	output reg [3:0] state_next;
	output reg [32:0] envelope_next;

	//outputs
	output reg signed [15:0] output_sample
	);

	reg [15:0] attack_amt_reg;
	reg [15:0] decay_amt_reg;
	reg [15:0] sustain_amt_reg;
	reg [15:0] rel_amt_reg;


	//inernal wire. required to convert unsigned to signed before multiplying
	wire signed [15:0] envelope_truncated;
	assign envelope_truncated = envelope_current[32:17];



	always @(posedge clk or negedge reset) begin
		if (~reset) begin
			state_next <= 4'b0;

			envelope_next <= 33'd0;
		end
		else begin

			//perform envelope modulation
			//output upper 16 bits signed
			output_sample <= (envelope_truncated * input_sample)[31:16];

			//adsr state machine
			case (state_current)

				0:	begin //note off
					envelope_next <= 33'd0;

					if (key_state == 1'b1) begin

						//capture adsr params into reg before begining the sequence
						attack_amt_reg <= attack_amt;
						decay_amt_reg <= decay_amt;
						sustain_amt_reg <= sustain_amt;
						rel_amt_reg <= rel_amt;

						state_next <= 4'd1;
					end

				end

				1:	begin //attack
					if (key_state == 1'b0)
						state_next <= 4'd3;
					else if (envelope_current < (33'h100000000 - attack_amt_reg))
						envelope_next <= envelope_current + attack_amt_reg;
					else
						state_next <= 4'd2;
				end

				2:	begin //decay to sustain level
					if (key_state == 1'b0)
						state_next <= 4'd3;
					else if (envelope_current > (sustain_amt_reg<<16))
						envelope_next <= envelope_current - decay_amt_reg;
				end

				3:	begin //release
					if (envelope_current > 33'd0+rel_amt_reg)
						envelope_next <= envelope_current - rel_amt_reg;
					else
						state_next <= 4'd0;
				end

			endcase

		end

	end


endmodule
