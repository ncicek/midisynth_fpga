//This module takes midi commands from the midi_decoder and sends appropriate signals to all coresponding modules such as:
//DDS, adsr keyon/off, etc.

module midi_controller(
	input wire clk,
	input wire reset,

	input wire  midi_byte_ready,
	input wire [7:0] midi_byte0,
	input wire [7:0] midi_byte1,
	input wire [7:0] midi_byte2,

	output reg [31:0] dds_frequency_bus,
	output reg [3:0] key_state
	);

	parameter POLYPHONY = 4;


	//VOICE RAM////////////////////////
	reg [6:0] voice_RAM_addr;	//addresses correspond to pitch values
	reg [POLYPHONY-1:0] voice_RAM_din;
	wire [POLYPHONY-1:0] voice_RAM_dout;
	reg voice_RAM_write_en;
	ram #(
		.addr_width(7),
		.data_width(POLYPHONY)
	)
	voice_RAM (
		.din(voice_RAM_din),
		.addr(voice_RAM_addr),
		.write_en(voice_RAM_write_en),
		.clk(clk),
		.dout(voice_RAM_dout)
	);
	//////////////////////////////////

	reg [6:0] midi_byte_converter_input;
	wire [31:0] tuning_code;

	tuning_code_lookup tuning_code_lookup(
	.midi_byte(midi_byte_converter_input),
	.tuning_code(tuning_code)
	);

	//dds_frequency assigner
	reg [1:0] note_state;
	reg [3:0] voice_index;	//size to fit POLYPHONY value

	integer i;
	always @(posedge clk or negedge reset) begin
		if (~reset) begin
			note_state <=0;
			voice_index <= 8'd0;
			voice_RAM_addr <=7'b0;
			voice_RAM_write_en <= 1'b0;

			for (i=0; i<POLYPHONY; i=i+1) begin
				key_state[i] <= 1'b0;
				voice_RAM_din[i] <= 1'b0;
			end

		end

		else
			case (note_state)
				2'd0: begin

					voice_RAM_write_en <= 1'b0;

					if (midi_byte_ready) begin
						note_state <= 2'd1;
						midi_byte_converter_input <= midi_byte1[6:0];

						//read voice_RAM
						voice_RAM_addr <= midi_byte1[6:0];	//only take lower 7 bits as the 8th bit should be zero for a note pitch
					end
				end

				2'd1:	begin
					voice_RAM_addr <= midi_byte1[6:0];
					if (midi_byte0[7:4] == 4'b1001 && (midi_byte2 != 8'b0)) begin	//note on

						//write params to the voice
						dds_frequency_bus <= tuning_code;

						//if the voice we are about to turn on is already on
						if (key_state[voice_index] == 1'b1) begin
							key_state[voice_index] <= 1'b0;
							note_state <= 2'd2;	//toggler state
						end



						voice_RAM_din <= voice_RAM_dout | (1'b1 << voice_index);
						voice_RAM_write_en <= 1'b1;

						if (voice_index<POLYPHONY)
							voice_index <= voice_index + 1'b1;
						else
							voice_index <= {POLYPHONY{1'b0}};

					end
					else if ( (midi_byte0[7:4] == 4'b1000) || ((midi_byte0[7:4] == 4'b1001) && (midi_byte2 == 8'b0)) ) begin	//note off or a note on w/zero velocity

							if (voice_RAM_dout[3] == 1'b1) begin
								voice_RAM_din <= voice_RAM_dout & ~(4'd1<<3);
								voice_RAM_write_en <= 1'b1;
								key_state[3] <= 1'b0;
								voice_index	<= 3;
							end
							else if (voice_RAM_dout[2] == 1'b1) begin
								voice_RAM_din <= voice_RAM_dout & ~(4'd1<<2);
								voice_RAM_write_en <= 1'b1;
								key_state[2] <= 1'b0;
								voice_index	<= 2;
							end
							else if (voice_RAM_dout[1] == 1'b1) begin
								voice_RAM_din <= voice_RAM_dout & ~(4'd1<<1);
								voice_RAM_write_en <= 1'b1;
								key_state[1] <= 1'b0;
								voice_index	<= 1;
							end
							else if (voice_RAM_dout[0] == 1'b1) begin
								voice_RAM_din <= voice_RAM_dout & ~(4'd1<<0);
								voice_RAM_write_en <= 1'b1;
								key_state[0] <= 1'b0;
								voice_index	<= 0;
							end
					end

					note_state <= 2'd0;
				end

				2'd2: 	begin
					key_state[voice_index] <= 1'b1;
					note_state <= 2'd0;
				end

				default:
					note_state <= 2'd0;
			endcase
	end

endmodule
