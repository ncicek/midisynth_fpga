module CC_controller(
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




endmodule
