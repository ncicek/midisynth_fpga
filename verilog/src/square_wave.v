module square_wave(
	input wire clk,
	
	input wire [9:0] theta,
	output reg signed [15:0] square_sample
	);
	
	always @(posedge clk) begin
		if (theta >= 10'd512)
			square_sample <= 16'sd32767;
		else
			square_sample <= -16'sd32767;
	end
	
endmodule