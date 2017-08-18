// `default_nettype none
module voice_controller(
	input wire clk,
	input wire reset,

	input wire SPI_note_status,
	input wire [7:0] SPI_voice_index,
	input wire [6:0] SPI_midi_note,
	input wire [6:0] SPI_velocity,
	input wire SPI_ready_flag,

	output reg signed [23:0] output_sample
	);

	//DDS////////////////////////////////////////
	localparam  dds_data_width = 64;

  reg [7:0] voice_counter;

	wire [dds_data_width-1:0] dds_din;
	reg [7:0] dds_addr = 8'b0;
	reg dds_write_en = 1'b0;
	wire [dds_data_width-1:0] dds_dout;

	//memory bus bit assignments
	wire [31:0] dds_dout_current_phase;
	wire [31:0] dds_dout_delta_phase;
	assign dds_dout_current_phase = dds_dout[31:0];
	assign dds_dout_delta_phase = dds_dout[63:32];

	reg [31:0] dds_din_current_phase = 32'b0;
	reg [31:0] dds_din_delta_phase = 32'b0;
	assign dds_din[31:0] = dds_din_current_phase;
	assign dds_din[63:32] = dds_din_delta_phase;

	wire [7:0] dds_voice_index_next;
	wire [9:0] dds_output_phase;
	dds dds (.clk(clk),
	.reset(reset),
	.voice_index(voice_counter),
	.dds_din(dds_din),
	.dds_addr(dds_addr),
	.dds_write_en(dds_write_en),
	.dds_dout(dds_dout),
	.output_phase(dds_output_phase),
	.voice_index_next(dds_voice_index_next)
	);
	////////////////////////////////////////////////

	reg [3:0] wave_select = 4'd1;
	wire signed [15:0] wavetable_output;
	wire [7:0] wavetable_voice_index_next;
	wavetable wavetable(.clk(clk),.reset(reset),.phase(dds_output_phase),.wave_select(wave_select),.sample(wavetable_output),.voice_index(dds_voice_index_next),.voice_index_next(wavetable_voice_index_next));






	//ADSR////////////////////////////////////////////////////////////////////
	reg[15:0] attack_amt;
	reg [15:0] decay_amt;
	reg [15:0] sustain_amt;
	reg [15:0] rel_amt;

	localparam adsr_data_width = 38;	//update this with the assignments below

	wire [adsr_data_width-1:0] adsr_din;
	reg [7:0] adsr_addr = 8'b0;
	reg adsr_write_en;
	wire [adsr_data_width-1:0] adsr_dout;

	//data bus assignments
	wire [32:0] adsr_dout_envelope;
	wire [3:0] adsr_dout_state;
	wire adsr_dout_keystate;
	assign adsr_dout_envelope = adsr_dout[37:5];
	assign adsr_dout_state = adsr_dout[4:1];
	assign adsr_dout_keystate = adsr_dout[0];

	reg [32:0] adsr_din_envelope = 33'b0;
	reg [3:0] adsr_din_state = 4'b0;
	reg adsr_din_keystate = 1'b0;
	assign adsr_din[37:5] = adsr_din_envelope;
	assign adsr_din[4:1] = adsr_din_state;
	assign adsr_din[0] = adsr_din_keystate;

	wire signed [15:0] voice_chain_output;

	ADSR ADSR (.clk(clk),
	.reset(reset),
	.voice_index(wavetable_voice_index_next),
	.input_sample(wavetable_output),
	.attack_amt(attack_amt),
	.decay_amt(decay_amt),
	.sustain_amt(sustain_amt),
	.rel_amt(rel_amt),
	.adsr_din(adsr_din),
	.adsr_addr(adsr_addr),
	.adsr_write_en(adsr_write_en),
	.adsr_dout(adsr_dout),
	.output_sample(voice_chain_output)
	);
	////////////////////////////////////////////////////////////////////////


	wire [31:0] tuning_code;
	reg [6:0] midi_byte;
	tuning_code_lookup tuning_code_lookup(.midi_byte(midi_byte),.tuning_code(tuning_code));

  reg signed [23:0] mixer_buffer = 24'sd0;
	reg [3:0] state;

	reg [10-1:0] mem_phase [(1<<8)-1:0];//SIM ONLY

	always @(posedge clk) begin
		if (reset == 1'b1) begin
			state <= 4'b0;
			voice_counter <= 8'd0;
      mixer_buffer <= 24'sd0;
			//midi_byte <= 7'b0;
			wave_select <= 4'd1;

      dds_addr <= 8'b0;
      adsr_addr <= 8'b0;
      dds_write_en <= 1'b0;
      adsr_write_en <= 1'b0;
      dds_din_current_phase <= 32'b0;
      dds_din_delta_phase <= 32'b0;
      adsr_din_envelope <= 33'b0;
      adsr_din_state <= 4'b0;
      adsr_din_keystate <= 1'b0;

      attack_amt <= 16'd10000;
      decay_amt <= 16'd10000;
      sustain_amt <= 16'd10000;
      rel_amt <= 16'd1000;

		end
		else begin
			//defaults do not modify a read data row in ram
			dds_din_delta_phase <= dds_dout_delta_phase;
			dds_din_current_phase <= dds_dout_current_phase;
			adsr_din_state <= adsr_dout_state;
			adsr_din_keystate <= adsr_dout_keystate;
			adsr_din_envelope <= adsr_dout_envelope;

			case (state)
				0: begin
					//idle state
					state <= 4'd1;
					dds_write_en <= 1'b0;
					adsr_write_en <= 1'b0;

				end
				1: begin
					dds_write_en <= 1'b0;
					adsr_write_en <= 1'b0;
					//increment voice counter
					//check for rollover and handle new spi cmds
					//JUST FOR SIM
					mem_phase[voice_counter] <= dds_output_phase;
					//END OF SIM STUFF

					if (voice_counter == 8'hff) begin
	          output_sample <= mixer_buffer + voice_chain_output;  //spit out a mixed sample
	          mixer_buffer <= 24'sd0;   //clear the mixer buffer when voice counter is full to prepare for the next sample
						voice_counter <= 8'h0;
						state <= 4'd2;
					end
					else begin
						voice_counter <= voice_counter + 1'b1;
						mixer_buffer <= mixer_buffer + voice_chain_output;
						state <= 4'd0;
					end
				end

				//STATES 2 AND 3 PERFORM A READ-MODIFY-WRITE OP ON ALL MEMORIES
				2: begin
					//read all rams at the address of the spi cmd recieved
					dds_write_en <= 1'b0;
					adsr_write_en <= 1'b0;
					//TODo need to syncronize these and probably put spi commands into a fifo
					dds_addr <= SPI_voice_index;
					adsr_addr <= SPI_voice_index;
					state <= 4'd3;
				end

				3: begin
					//update and write back all rams
					dds_write_en <= 1'b1;
					adsr_write_en <= 1'b1;
					if (SPI_note_status == 1'b1) begin	//noteon
						midi_byte = SPI_midi_note;	//blocking i think?
						dds_din_delta_phase <= tuning_code;
						adsr_din_keystate <= 1'b1;
					end
					else if (SPI_note_status == 1'b0) begin	//noteoff
						adsr_din_keystate <= 1'b0;
						//adsr keyoff
					end

					//copying this stuff over from state 1
					//we need to keep voice counter action continous
					voice_counter <= voice_counter + 1'b1;
					mixer_buffer <= mixer_buffer + voice_chain_output;
					mem_phase[voice_counter] <= dds_output_phase;

					state <= 4'd0	;
				end
			endcase
		end
	end

endmodule
