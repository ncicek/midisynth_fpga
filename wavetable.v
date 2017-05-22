module wavetable(
	input wire clk,

  //input
	input wire [9:0] phase,

  //parameters
  input wire [3:0] wave_select,

  //output
	output reg signed [15:0] sample
	);




  sincos sinetable
  (
  .Clock (clk),
  .ClkEn (1'b1),
  .Reset(reset),
  .Theta(phase),	//10 bit input
  .Sine(sine_sample)	//16 bit signed output
  );

  square_wave square_wave
  (
  .clk(clk),
  .theta(phase),
  .square_sample(square_sample)
  );





	always @(posedge clk) begin

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

endmodule
