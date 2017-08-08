 `default_nettype none

module midi_synth(
	input wire clk,
	input wire reset,

	input wire SPI_sclk,
	input wire SPI_mosi,
	//output wire [7:0] debug_bus,

	output wire [15:0] dac_out,
	output wire [7:0] leds,
	output wire [7:0] leds_2,
	output wire [7:0] leds_3
	);

	wire SPI_note_status;
	wire [7:0] SPI_voice_index;
	wire [6:0] SPI_midi_note;
	wire [6:0] SPI_velocity;
	wire SPI_ready_flag;
	wire signed [23:0] output_sample;

	spi_controller spi_controller(.clk(clk),.reset(reset),.SPI_sclk(SPI_sclk),.SPI_mosi(SPI_mosi),.SPI_note_status(SPI_note_status),.SPI_voice_index(SPI_voice_index),.SPI_midi_note(SPI_midi_note),.SPI_velocity(SPI_velocity),.SPI_ready_flag(SPI_ready_flag));
	voice_controller voice_controller(.clk(clk),.reset(reset),.SPI_note_status(SPI_note_status),.SPI_voice_index(SPI_voice_index),.SPI_midi_note(SPI_midi_note),.SPI_velocity(SPI_velocity),.SPI_ready_flag(SPI_ready_flag),.output_sample(output_sample));

	assign dac_out = output_sample[23:8] + 16'd32768;




endmodule
