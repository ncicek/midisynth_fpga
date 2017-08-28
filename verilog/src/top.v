//`default_nettype none
module top(
	input wire ref_clk,
	input wire button,

	input wire SPI_sclk,
	input wire SPI_mosi,

	//output wire [15:0] debug_bus,

	output wire [15:0] dac_out,
	output wire [7:0] leds_0_b,
	output wire [7:0] leds_1_b,
	output wire [7:0] leds_2_b,
	output wire [1:0] byte_counter
	);

	wire clk;
	wire reset;
	assign reset = ~button;

	GSR GSR_INST (.GSR (reset));
	PUR PUR_INST (.PUR (reset));

	//PLL
	pll pll (.CLKI(ref_clk), .CLKOP(clk));


	wire [7:0] leds_0, leds_1, leds_2;
	midi_synth midi_synth(
	.i_clk(clk),
	.i_reset(reset),

	.i_SPI_sclk(SPI_sclk),
	.i_SPI_mosi(SPI_mosi),

	.o_dac_out(dac_out),
	.leds_0(leds_0),
	.leds_1(leds_1),
	.leds_2(leds_2),
	.byte_counter_debug(byte_counter)
	);

	assign leds_0_b = ~leds_0;
	assign leds_1_b = leds_1;
	assign leds_2_b = leds_2;
	//assign debug_bus[0] = clk;
	//assign debug_bus[16:1] = dac_out;

endmodule
