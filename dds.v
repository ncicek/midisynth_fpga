module dds(
	input wire clk,
	input wire reset,

	input wire[31:0] delta_phase,

	output reg[31:0] phase_acumulator
	);


	always @(posedge clk or negedge reset) begin
		if (~reset)
			phase_acumulator <= 32'b0;
		else
			phase_acumulator <= phase_acumulator + delta_phase;
	end
	






endmodule