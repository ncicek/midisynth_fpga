module ADSR(
	input wire clk,
	input wire reset,
	
	
	);			

	//IDEA segragate parameter ram from state ram
	
	
	reg [3:0] state;	
	
	reg [7:0] voice_counter;
	
	always @(posedge clk or negedge reset) begin
		if (~reset) begin
			state <= 4'b0;
			voice_counter <= 8'b0;
		end
		else begin
			
			case (state)
				
				0:	begin 
					//load an address to the ram
					ram_we <= 1'b0;
					ram_address <= voice_counter;
					voice_counter <= voice_counter + 1;
					
					if (voice_counter == 8'hff)
						state <= 4'd3;
					else
						state <= 4'd1;
				end
				
				1:	begin 
					//ram output is now showing the ram contents at that address
					//load up all the controller outputs using these ram values
					
					tuning_code = ram_q[4:2]
					//TODO complete this section
					
					state <= 4'd2;
				end
						
				2:	begin 
					//by now the modules should have completed their task and updated their state
					//save the state statuses into ram
					ram_we <= 1'b1;
					ram_data[2:3] <= a;
					//TODO
					
					state <= 4'd0;
				end
									
				3:	begin 
					//come here every time the counter is about to overflow
					//grabs new parameter updates from the midi controller and puts it into ram
					
					state <= 4'd0;
				end
				
			endcase
							
		end
		
	end
	
	
endmodule
	
	
	