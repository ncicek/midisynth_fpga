 //`default_nettype none
module top(
	input wire ref_clk,
	input wire button,

	input wire SPI_sclk,
	input wire SPI_mosi,

	//output wire [15:0] debug_bus,

	output wire [15:0] dac_out,
	output wire [7:0] leds,
	output wire [7:0] leds_2,
	output wire [7:0] leds_3
	);
	
	wire clk;
	wire reset;
	assign reset = ~button;

	GSR GSR_INST (.GSR (reset));
	PUR PUR_INST (.PUR (reset));

	//PLL
	pll pll (.CLKI(ref_clk), .CLKOP(clk));


	midi_synth midi_synth(
	.clk(clk),
	.reset(reset),

	.SPI_sclk(SPI_sclk),
	.SPI_mosi(SPI_mosi),

	.dac_out(dac_out)
	//.leds(leds),
	//.leds_2(leds_2),
	//.leds_3(leds_3)
	);

	//assign debug_bus[0] = clk;
	//assign debug_bus[16:1] = dac_out;

endmodule
