//`default_nettype none
module voice_controller(
	input wire i_clk,
	input wire i_reset,

	input wire i_SPI_note_status,
	input wire [7:0] i_SPI_voice_index,
	input wire [31:0] i_SPI_tuning_code,
	input wire [6:0] i_SPI_velocity,
	input wire i_SPI_flag,

	output reg signed [23:0] o_mixed_sample
	);

	reg [7:0] voice_index;

	//DDS////////////////////////////////////////
	wire [9:0] phase;
	wire [7:0] dds_voice_index_next;
	reg [1:0] pipeline_state  ;

	dds dds (.i_clk(i_clk),
	.i_reset(i_reset),
	.i_SPI_flag(i_SPI_flag),
	.i_SPI_tuning_code(i_SPI_tuning_code),
	.i_SPI_voice_index(i_SPI_voice_index),
	.i_voice_index(voice_index),
	.i_pipeline_state(pipeline_state),
	.o_phase(phase),
	.o_voice_index_next(dds_voice_index_next)
	);

	//WAVETABLE///////////////////////////////////////////////
	reg [3:0] wave_select;
	wire signed [15:0] wavetable_output;
	wire [7:0] wavetable_voice_index_next;

	wavetable wavetable(.i_clk(i_clk),.i_reset(i_reset),.i_phase(phase),.i_wave_select(wave_select),.i_voice_index(dds_voice_index_next),.i_pipeline_state(pipeline_state),.o_voice_index_next(wavetable_voice_index_next),.o_sample(wavetable_output));

	//ADSR////////////////////////////////////////////////////////////////////
	reg[15:0] attack_amt;
	reg [15:0] decay_amt;
	reg [15:0] sustain_amt;
	reg [15:0] rel_amt;

	wire signed [15:0] adsr_output;

	ADSR ADSR (
    .i_clk(i_clk),
    .i_reset(i_reset),

    .i_SPI_flag(i_SPI_flag),
    .i_SPI_note_status(i_SPI_note_status),
    .i_SPI_voice_index(i_SPI_voice_index),

    .i_voice_index(wavetable_voice_index_next),
    .i_pipeline_state(pipeline_state),
    .i_sample(wavetable_output),

    .i_attack_amt(attack_amt),
    .i_decay_amt(decay_amt),
    .i_sustain_amt(sustain_amt),
    .i_rel_amt(rel_amt),

    .o_sample(adsr_output)
  );
	////////////////////////////////////////////////////////////////////////

	always @(posedge i_clk) begin
		if (i_reset) begin
			pipeline_state <= 2'b0;


			wave_select <= 4'd1;

      attack_amt <= 16'd10000;
      decay_amt <= 16'd10000;
      sustain_amt <= 16'd10000;
      rel_amt <= 16'd10000;

		end
		else begin
			if (pipeline_state < 2'd3)
				pipeline_state <= pipeline_state + 1'b1;
			else
				pipeline_state <= 2'd0;
		end
	end


	reg signed [23:0] mixer_buffer;

	always @(posedge i_clk) begin
		if (i_reset) begin
			o_mixed_sample <= 24'sd0;
			mixer_buffer <= 24'sd0;
			voice_index <= 8'd0;
		end
		else begin
			if (pipeline_state == 2'd0)	//incrementor
				voice_index <= voice_index + 1'b1;

			else if (pipeline_state == 2'd2) begin	//mixer
				if (voice_index == 8'hff) begin
		      o_mixed_sample <= mixer_buffer + adsr_output;  //spit out a mixed sample
		      mixer_buffer <= 24'sd0;   //clear the mixer buffer when voice counter is full to prepare for the next sample
		    end
		    else begin
		      mixer_buffer <= mixer_buffer + adsr_output;
		    end
			end
		end
	end

endmodule
