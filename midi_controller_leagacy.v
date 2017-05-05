//This module takes midi commands from the midi_decoder and sends appropriate signals to all coresponding modules such as:
//DDS, adsr keyon/off, etc.

module midi_controller(
	input wire clk,
	input wire reset,
	
	input wire  midi_byte_ready,
	input wire [7:0] midi_byte0,	
	input wire [7:0] midi_byte1,	
	input wire [7:0] midi_byte2, 
	
	output reg [127:0] dds_frequency,
	output reg [3:0] key_state
	);
	
	
	
	
	
	reg [7:0] midi_byte_converter_input;
	wire [31:0] tuning_code;
	
	tuning_code_lookup tuning_code_lookup(
	.midi_byte(midi_byte_converter_input),
	.tuning_code(tuning_code)
	);
	
	
	
	
	//note handler
	reg [3:0] note_state;
	reg [3:0] next_note_state;
	always @(posedge clk) begin
		if (reset)
			note_state <=0;
		else
			case (note_state)
				0:
					if (midi_byte_ready) begin
						note_state <= 1;
						midi_byte_converter_input <= midi_byte1;
					end
					
				1:	begin
					if (midi_byte0[7:4] == 4'b1001 && (midi_byte2 != 8'b0)) begin	//note on
						dds_frequency [31:0] <= tuning_code;
						key_state[0] <= 1;
					end
					else if ((midi_byte0[7:4] == 4'b1000) || (midi_byte2 == 8'b0)) begin	//note off or zero velocity
						key_state[0] <= 0;
					
					end
					note_state <= 0;
				end
				
				default:
					note_state <= 0;
				
			endcase
	
	
	end
	
	
	
	
	
	
	
endmodule