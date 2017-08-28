//`default_nettype none
module top_dds(
	input wire ref_clk,
	input wire button,

	//output wire [15:0] debug_bus,

	output reg signed [15:0] dac_out,
	output wire [7:0] leds_0_b,
	output reg [7:0] leds_1_b,
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
	wire [7:0] dds_voice_index_next;

	dds dds (.i_clk(ref_clk),
	.i_reset(reset),
	.i_SPI_flag(SPI_flag),
	.i_SPI_tuning_code(SPI_tuning_code),
	.i_SPI_voice_index(SPI_voice_index),
	.i_voice_index(voice_index),
	.i_pipeline_state(pipeline_state),
	.o_phase(o_phase),
	.o_voice_index_next(dds_voice_index_next)
	);


	//WAVETABLE///////////////////////////////////////////////
	reg [3:0] wave_select = 4'd1;
	wire signed [15:0] wavetable_output;
	wire [7:0] wavetable_voice_index_next;

	wavetable wavetable(.i_clk(ref_clk),.i_reset(reset),.i_phase(o_phase),.i_wave_select(wave_select),.i_voice_index(dds_voice_index_next),.i_pipeline_state(pipeline_state),.o_voice_index_next(wavetable_voice_index_next),.o_sample(wavetable_output));


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

	reg signed [15:0] phase_mem [7:0];

	always @(posedge ref_clk) begin	//phase grab into mem
		if (pipeline_state == 2'd2) begin
			phase_mem[voice_index-2]<= wavetable_output; //whatever is on the output right now is voice_index 2 cycles ago
		end
	end

	always @(posedge ref_clk) begin	//output phase 5
		if (voice_index == 8'd7 & pipeline_state == 2'd3) begin
			//ac_out[15:6] <= phase_mem[5];
			//dac_out[5:0] <= 6'b0;
			dac_out <= phase_mem[5] + 16'd32768;
		end
		/*if (pipeline_state == 2'd0) begin
			dac_out[15:6] <= phase_mem[5];
			dac_out[5:0] <= 6'b0;
		end*/
		//dac_out[5:0] <= 6'b0;
		//dac_out[15:14] <= pipeline_state;
	end

	reg [23:0] counter;
	always @(posedge ref_clk) begin//spi comman sender
		if (reset) begin
			counter <= 24'd0;
			SPI_flag <= 1'b0;
			SPI_tuning_code <= 32'd0;
		end
		else begin
			if (counter == 24'd12000000) begin
				SPI_flag <=1'b1;
				SPI_tuning_code <= 32'd100000000;
				SPI_voice_index <= 8'd5;
			end
			else begin
				SPI_flag <= 1'b0;
				counter <= counter + 1'b1;
			end
		end
	end

	always @(posedge ref_clk) begin//spi comman sender
		if (SPI_flag)
			leds_2_b <= 8'b1;
		else
			leds_2_b <= 8'b0;
	end

	reg [24:0] ledcounter;
	always @(posedge ref_clk) begin
		if (reset)
			ledcounter <= 24'd0;
		else begin
			ledcounter <= ledcounter +1'b1;
			leds_1_b <= ledcounter[24:17];
		end
	end

endmodule
