module dds(
	input wire clk,
	input wire reset,

	//parameters
	input wire[31:0] delta_phase,

	//states
	input wire[31:0] phase_acumulator,

	//outputs
	output reg[31:0] output_phase
	);


	always @(posedge clk or negedge reset) begin
		if (~reset)
			output_phase <= 32'b0;
		else
			output_phase <= phase_acumulator + delta_phase;
	end



endmodule
