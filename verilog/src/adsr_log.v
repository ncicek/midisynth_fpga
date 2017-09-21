
module ADSR_log;
  parameter bit_depth = 24;

  reg [bit_depth-1:0] envelope = {bit_depth{1'b0}};
  reg [bit_depth-1:0] attackCoef = 24'd16776829;
  reg [bit_depth-1:0] attackBase = 24'd391;

  reg clk = 0;
  reg [47:0] multiplied;
  always @(posedge clk) begin
	  multiplied = envelope * attackCoef;
	  envelope <= attackBase + (multiplied[47:24]);
	end

  always begin
		#1 clk = ~clk;
	end

endmodule
