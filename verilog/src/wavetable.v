 //`default_nettype none
module wavetable(
	input wire i_clk,
	input wire i_reset,

	input wire [9:0] i_phase,
	input wire [3:0] i_wave_select,
	input wire [7:0] i_voice_index,
	input wire [1:0] i_pipeline_state,

	output reg [7:0] o_voice_index_next,

	output reg signed [15:0] o_sample
	);


	wire signed [15:0] square_sample;
	wire signed [15:0] sine_sample;

	//sincos sinetable
	//(
	//.Clock (clk),
	//.ClkEn (1'b1),
	//.Reset(reset),
	//.Theta(phase),	//10 bit input
	//.Sine(sine_sample)	//16 bit signed output
	//);
/*
	sine_table sine_table
	(
	.theta(i_phase),
	.sine_sample(sine_sample)
	);
	*/

	square_wave square_wave
	(
	.theta(i_phase),
	.square_sample(square_sample)
	);

	always @(posedge i_clk) begin
		case (i_pipeline_state)
			0:	begin	//read from mem
				//addr <= i_voice_index;
				o_voice_index_next <= i_voice_index;
				//write_en <= 1'b0;
			end

			1:	begin //compute and write back to mem
				//write_en <= 1'b1;
				case (i_wave_select)
					4'd0:	begin
					o_sample <= sine_sample;
					end

					4'd1:	begin
					o_sample <= square_sample;
					end

					4'd2:	begin
					o_sample <= square_sample;
					end

					4'd3:	begin
					o_sample <= square_sample;
					end

					default: begin
					o_sample <= square_sample;
					end
				endcase
			end

			2: begin    //update ram
				//do nothing
				/*write_en <= 1'b1;
				if (new_update_available) begin
						new_update_available <= 1'b0; //clear the bit
						addr <= voice_addr_update;
						mask <= `MASK_DELTA_PHASE;
						din_delta_phase <= delta_phase_update;
				end*/
			end

		endcase

	end

endmodule
