//This module takes midi commands from the midi_decoder and sends appropriate signals to all coresponding modules such as:
//DDS, adsr keyon/off, etc.

module midi_controller(
	input wire clk,
	input wire reset,
	
	input wire  midi_byte_ready,
	input wire [7:0] midi_byte0,	
	input wire [7:0] midi_byte1,	
	input wire [7:0] midi_byte2, 
	
	output wire [127:0] dds_frequency_concat,
	output reg [3:0] key_state
	);
	
	parameter POLYPHONY = 4;
	
	
	reg [31:0] dds_frequency [POLYPHONY-1:0];
	
	
	assign dds_frequency_concat = {dds_frequency[3],dds_frequency[2],dds_frequency[1],dds_frequency[0]};
	
	
	
	
	reg [7:0] midi_byte_converter_input;
	wire [31:0] tuning_code;
	
	tuning_code_lookup tuning_code_lookup(
	.midi_byte(midi_byte_converter_input),
	.tuning_code(tuning_code)
	);
	
	
	
	

	
	
	//dds_frequency assigner
	reg [3:0] note_state;
	reg [3:0] next_note_state;
	
	reg [POLYPHONY-1:0] voice_RAM [127:0];
	reg [7:0] voice_index;
	
	integer i;
	always @(posedge clk) begin
		if (reset) begin
			note_state <=0;
			voice_index <= 8'd0;
			
			//initialize voice_RAM to zero
			
			for (i=0; i<128; i=i+1)
				voice_RAM[i] <= {POLYPHONY{1'b0}};
				
			for (i=0; i<POLYPHONY; i=i+1)
				key_state[i] <= 1'b0;
			
		end
		
		else
			case (note_state)
				0:
					if (midi_byte_ready) begin
						note_state <= 1;
						midi_byte_converter_input <= midi_byte1;
					end
					
				1:	begin
					if (midi_byte0[7:4] == 4'b1001 && (midi_byte2 != 8'b0)) begin	//note on
					
					
						//write params to the voice
						dds_frequency[voice_index] <= tuning_code;
						key_state[voice_index] <= 1;
						
						voice_RAM[midi_byte1] <= voice_RAM[midi_byte1] | (4'b1 << voice_index);
						
						//todo increment voice_index afterwards (new state needed?)
						voice_index <= voice_index + 1'b1;

						
					end
					else if ((midi_byte0[7:4] == 4'b1000) || (midi_byte2 == 8'b0)) begin	//note off or zero velocity
						
						if (voice_RAM[midi_byte1][3] == 1'b1) begin
							voice_RAM[midi_byte1] <= voice_RAM[midi_byte1] & ~(4'd1<<3);
							key_state[3] <= 0;
							voice_index	<= 3;
						end
						else if (voice_RAM[midi_byte1][2] == 1'b1) begin
							voice_RAM[midi_byte1] <= voice_RAM[midi_byte1] & ~(4'd1<<2);
							key_state[2] <= 0;	
							voice_index	<= 2;
						end
						else if (voice_RAM[midi_byte1][1] == 1'b1) begin
							voice_RAM[midi_byte1] <= voice_RAM[midi_byte1] & ~(4'd1<<1);
							key_state[1] <= 0;
							voice_index	<= 1;
						end
						else if (voice_RAM[midi_byte1][0] == 1'b1) begin
							voice_RAM[midi_byte1] <= voice_RAM[midi_byte1] & ~(4'd1<<0);
							key_state[0] <= 0; 
							voice_index	<= 0;
						end
					else begin	
							
							key_state[0] <= 0;
						end
						
					end
					note_state <= 0;
				end
				
				default:
					note_state <= 0;
				
			endcase
	
	
	end
	
	
	
	
	
	
	
endmodule