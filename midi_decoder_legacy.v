module midi_decoder(
	input wire clk,
	input wire reset,
	input wire midi_port,
	
	output wire received,
	output reg midi_byte_ready,		//asserts upon recieving all three bytes
	output reg [7:0] midi_byte0,	//status byte
	output reg [7:0] midi_byte1,	//data1 byte
	output reg [7:0] midi_byte2,		//data2 byte
	output wire [3:0] rx_byte_dbg
	
	);
	
	wire [7:0] rx_byte;
	assign rx_byte_dbg = rx_byte[7:4];
	
		
	uart #(.CLOCK_DIVIDE(384))	//CLOCK_DIVIDE = Frequency(clk) / (4 * Baud)
	midi_uart (clk, reset, midi_port,  , 1'b0, 8'b0, received, rx_byte, , , );
	

	reg [7:0] temp_midi_byte [2:0];	//internally stores midi bytes
	
	reg [3:0] state;
	reg [3:0] next_state;
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			state <= 4'b0;
			next_state <= 4'b1;
			
			temp_midi_byte[0] <= 8'b0;
			temp_midi_byte[1] <= 8'b0;
			temp_midi_byte[2] <= 8'b0;			
			
			midi_byte0 <= 8'b0;	  
			midi_byte1 <= 8'b0;
			midi_byte2 <= 8'b0;
			
		end
		

			
		else begin	

			case (state)
				0:
				begin
					midi_byte_ready <= 1'b0;
					if (received)	//wait for a byte
					begin
						state <= next_state;
					end
				end
					

				1:	//status byte
				begin
					if (rx_byte[7] == 1'b1) //if it is a status byte
					begin
						temp_midi_byte[0] <= rx_byte;
						
						if (!received)	//wait to received to deassert
						begin
							next_state <= 2;
							state <= 0;
						end
					
					end
					else begin	//otherwise pass to 'data1 handler' state (running status)
						state <= 2;
					end
					

				end
					
				2:	//data1 handler
				begin
					if (rx_byte[7] == 1'b0)	begin //confirm it is a data byte
						temp_midi_byte[1] <= rx_byte;
					end
					
					if (!received)	//wait to received to deassert
					begin
						next_state <= 3;
						state <= 0;
					end
				end
				
				3:	//data2 handler
				begin
					if (rx_byte[7] == 1'b0)	begin //confirm it is a data byte
						temp_midi_byte[2] <= rx_byte;
					end
					state <= 4;
				end
				
				4:	//assert midi_byte_ready
				begin
					midi_byte_ready <= 1'b1;
					
					midi_byte0 <= temp_midi_byte[0];
					midi_byte1 <= temp_midi_byte[1];
					midi_byte2 <= temp_midi_byte[2];
					
					if (!received)	//make sure received has deasserted before going to idle state
					begin
						next_state <= 1;
						state <= 0;
					end
				end
			endcase

			
		
		end
	end
	
	
endmodule








	