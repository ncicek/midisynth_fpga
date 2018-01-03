//`default_nettype none
//platform agnostic pure verilog below this level
module midi_synth(
	input wire i_clk,
	input wire i_reset,

	input wire i_SPI_sclk,
	input wire i_SPI_mosi,
	//output wire [7:0] debug_bus,

	output wire [15:0] o_dac_out,
	output wire [7:0] leds_0,
	output wire [7:0] leds_1,
	output wire [7:0] leds_2,
	output wire [1:0] byte_counter_debug
	);

	wire SPI_note_status;
	wire [7:0] SPI_voice_index;
	wire [31:0] SPI_tuning_code;
	wire [6:0] SPI_velocity;
	wire SPI_flag_dds;
	wire SPI_flag_adsr;
	wire signed [23:0] output_sample;

	spi_controller spi_controller(.i_clk(i_clk),.i_reset(i_reset),.i_SPI_sclk(i_SPI_sclk),.i_SPI_mosi(i_SPI_mosi),.o_SPI_note_status(SPI_note_status),.o_SPI_voice_index(SPI_voice_index),.o_SPI_tuning_code(SPI_tuning_code),.o_SPI_velocity(SPI_velocity),.o_SPI_flag_dds(SPI_flag_dds),.o_SPI_flag_adsr(SPI_flag_adsr),.leds_0(leds_0),.leds_1(leds_1),.leds_2(leds_2),.byte_counter_debug(byte_counter_debug));
	voice_controller voice_controller(.i_clk(i_clk),.i_reset(i_reset),.i_SPI_note_status(SPI_note_status),.i_SPI_voice_index(SPI_voice_index),.i_SPI_tuning_code(SPI_tuning_code),.i_SPI_velocity(SPI_velocity),.i_SPI_flag_dds(SPI_flag_dds),.i_SPI_flag_adsr(SPI_flag_adsr),.o_mixed_sample(output_sample));

	//assign o_dac_out = output_sample[23:8] + 16'd32768;	 //dc offset into the middle of the dac range
	assign o_dac_out = output_sample[17:2] + 16'sd32768;



endmodule
