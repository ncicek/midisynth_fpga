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


	reg [7:0] voice_counter;
  reg signed [23:0] mixer_buffer = 24'sd0;

	reg [31:0] delta_phase;
	wire [9:0] dds_phase;
	dds dds(.clk(clk),.reset(reset),.delta_phase(delta_phase),.voice_index(voice_counter),.output_phase(dds_phase));

	reg [3:0] wave_select;
	wire signed [15:0] voice_chain_output;
	wavetable wavetable(.clk(clk),.reset(reset),.phase(dds_phase),.wave_select(wave_select),.sample(voice_chain_output));

	wire [31:0] tuning_code;
	reg [6:0] midi_byte;
	tuning_code_lookup tuning_code_lookup(.midi_byte(midi_byte),.tuning_code(tuning_code));


	reg [127:0] parameter_ram_data;
	reg parameter_ram_we;
	reg [7:0] parameter_ram_address;




	reg [3:0] state;


	always @(posedge clk or posedge reset) begin
		if (reset) begin
			state <= 4'b0;
			voice_counter <= 8'd0;
      mixer_buffer <= 24'sd0;
		end
		else begin
			case (state)
				0:	begin
					//load an address to the ram
	        //IDEA this can probably be merged back to back with state 2... gotta think
	        parameter_ram_we <= 1'b0;
	        parameter_ram_address <= voice_counter;
					voice_counter <= voice_counter + 1;
					state <= 4'd1;
				end

				1:	begin
					//ram outputs are now showing the ram contents at that address
					//load up all the voice parameteres using these ram values

	        //TODO complete this section
	        //load parameters
					//delta_phase <= parameter_ram_q[31:0];
					//wave_select <= parameter_ram_q[35:32];
					//attack <= parameter_ram_q[4:2];
					delta_phase <= parameter_ram_q[32:1];
	        wave_select <= 0;
					state <= 4'd2;
				end

				2:	begin
					//by now the modules should have produced a sample
					//mix the buffer contents

					if (voice_counter == 8'hff) begin
	          output_sample <= mixer_buffer + voice_chain_output;  //spit out a mixed sample
	          mixer_buffer <= 24'sd0;   //clear the mixer buffer when voice counter is full to prepare for the next sample
	      	end
					else begin
						mixer_buffer <= mixer_buffer + voice_chain_output;
					end
					state <= 4'd3;
				end

				3:	begin //PARAMETER UPDATER
					//grabs new parameter updates from the midi controller and puts it into ram
		      //IDEA: Why not do this every clock cycle? why do we need to wait for the whole voice index range to exhaust?
		      //maybe use two port ram here?

					parameter_ram_we <= 1'b1;

					if (SPI_note_status == 1'b1) begin	//noteon
						parameter_ram_address <= SPI_voice_index;
						midi_byte <= SPI_midi_note;
						parameter_ram_data[0] <= 1'b1;
						parameter_ram_data[32:1] <= tuning_code;

					end
					else if (SPI_note_status == 1'b0) begin	//noteoff
						parameter_ram_address <= SPI_voice_index;
						midi_byte <= SPI_midi_note;
						parameter_ram_data[0] <= 1'b0;
						parameter_ram_data[32:1] <= tuning_code;

					end

					state <= 4'd0;
				end
			endcase
		end
	end

endmodule
