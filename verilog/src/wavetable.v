 `default_nettype none
module wavetable(
	input wire clk,
	input wire reset,

	input wire [9:0] phase,
  input wire [3:0] wave_select,
	input wire [7:0] voice_index,

	output reg [7:0] voice_index_next,

	output reg signed [15:0] sample
	);



	wire signed [15:0] square_sample;
	wire signed [15:0] sine_sample;

  //sincos sinetable
  //(
  //.Clock (clk),
  //.ClkEn (1'b1),
  //.Reset(reset),
  //.Theta(phase),	//10 bit input
  //.Sine(sine_sample)	//16 bit signed output
  //);

  square_wave square_wave
  (
  .clk(clk),
  .theta(phase),
  .square_sample(square_sample)
  );

	reg cycle;

	always @(posedge clk) begin
		if (reset == 1'b1)
			cycle <= 1'b0;
		else begin
			case (cycle)
				1'b0: begin
					voice_index_next <= voice_index;
				end
				1'b1: begin
					case (wave_select)
						4'd0:	begin
						sample <= sine_sample;
						end

						4'd1:	begin
						sample <= square_sample;
						end

						4'd2:	begin
						sample <= square_sample;
						end

						4'd3:	begin
						sample <= square_sample;
						end

						default: begin
						sample <= square_sample;
						end

					endcase
				end
			endcase
		end

	end

endmodule
