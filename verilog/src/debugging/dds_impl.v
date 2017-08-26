`default_nettype none
module top_dds(
	input wire ref_clk,
	input wire button,

	//output wire [15:0] debug_bus,

	output reg [15:0] dac_out,
	output wire [7:0] leds_0_b,
	output wire [7:0] leds_1_b,
	output reg [7:0] leds_2_b
	);

	//wire clk;
	wire reset;
	assign reset = ~button;

	reg [1:0] pipeline_state;
	reg [7:0] voice_index;

	wire [9:0] o_phase;
	reg SPI_flag;
	reg [7:0] SPI_voice_index;
	reg [31:0] SPI_tuning_code;

	dds dds (.i_clk(ref_clk),
	.i_reset(reset),
	.i_SPI_flag(SPI_flag),
	.i_SPI_tuning_code(SPI_tuning_code),
	.i_SPI_voice_index(SPI_voice_index),
	.i_voice_index(voice_index),
	.i_pipeline_state(pipeline_state),
	.o_phase(o_phase),
	.o_voice_index_next()
	);

	always @(posedge ref_clk) begin
		if (reset) begin
			voice_index <= 8'd0;
		end
		else begin
			if (pipeline_state == 2'd0)	//incrementor
				voice_index <= voice_index + 1'b1;
		end
	end

	always @(posedge ref_clk) begin
		if (reset) begin
			pipeline_state <= 2'b0;
		end
		else begin
			if (pipeline_state < 2'd3)
				pipeline_state <= pipeline_state + 1'b1;
			else
				pipeline_state <= 2'd0;
		end
	end

	reg [9:0] phase_mem [7:0];

	always @(posedge ref_clk) begin	//phase grab into mem
		if (pipeline_state == 2'd1) begin
			phase_mem[voice_index-2]<= o_phase;
		end
	end

	always @(posedge ref_clk) begin	//output phase 5
		if (voice_index == 8'd5) begin
			//dac_out[15:6] <= phase_mem[5];
			//dac_out[5:0] <= 6'b0;
			dac_out <= ledcounter;
		end
	end

	reg [23:0] counter;
	always @(posedge ref_clk) begin//spi comman sender
		if (reset)
			counter <= 24'd0;
		else begin
			if (counter == 24'd12000000) begin
				SPI_flag <=1'b1;
				SPI_tuning_code <= 32'd1000000;
				SPI_voice_index <= 8'd5;
			end
			else begin
				SPI_flag <= 1'b0;
				counter <= counter + 1'b1;
			end
		end
	end

	reg [24:0] ledcounter;
	always @(posedge ref_clk) begin
		if (reset)
			ledcounter <= 24'd0;
		else begin
			ledcounter <= ledcounter +1'b1;
			leds_2_b <= ledcounter[24:17];
		end
	end

endmodule
