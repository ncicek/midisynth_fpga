module voice_controller(
	input wire clk,
	input wire reset,
	
	
	);		


	reg [31:0] delta_phase;
	reg [31:0] phase_acumulator;
	dds dds(.clk(clk),.reset(reset),.delta_phase(delta_phase),.phase_acumulator(phase_acumulator),.output_phase(output_phase));
	
	reg [3:0] wave_select;
	wavetable wavetable(.clk(clk),.phase(dds_phase),.wave_select(wave_select),.sample(sample));

	
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
					state_ram_we <= 1'b0;
                    parameter_ram_we <= 1'b0;
                    
					state_ram_address <= voice_counter;
                    parameter_ram_address <= voice_counter;
                    
					voice_counter <= voice_counter + 1;
					
					if (voice_counter == 8'hff)
						state <= 4'd3;
					else
						state <= 4'd1;
				end
				
				1:	begin 
					//ram outputs are now showing the ram contents at that address
					//load up all the voice states and parameteres using these ram values
					
                    //TODO complete this section
                    //load parameters
					delta_phase <= parameter_ram_q[31:0];
					wave_select <= parameter_ram_q[35:32];
					attack <= parameter_ram_q[4:2]
                    
                    
                    
                    //load states
					tuning_code <= state_ram_q[4:2]
					
					state <= 4'd2;
				end
						
				2:	begin 
					//by now the modules should have completed their task and updated their state
					//save the state statuses into ram
					state_ram_we <= 1'b1;
                    
                    //TODO write all states here
					state_ram_data[2:3] <= envelope;
					
					
					state <= 4'd0;
				end
									
				3:	begin //PARAMETER UPDATER
					//come here every time the counter is about to overflow
					//grabs new parameter updates from the midi controller and puts it into ram
					parameter_ram_we <= 1'b1;
                    
                    
                    
					state <= 4'd0;
				end
				
			endcase
							
		end
		
	end
	
	
endmodule
	
	
	