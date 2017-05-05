module ADSR(
	input wire clk,
	input wire reset,
	
	input wire [15:0] attack_amt,
	input wire [15:0] decay_amt,
	input wire [15:0] sustain_amt,
	input wire [15:0] rel_amt,
	
	input wire key_state,	//0=key unpressed, 1=key pressed
	
	input wire signed [15:0] input_sample,
	
	output reg signed [15:0] output_sample
	);				  			
	
	reg [15:0] attack_amt_reg;
	reg [15:0] decay_amt_reg;
	reg [15:0] sustain_amt_reg;
	reg [15:0] rel_amt_reg;
	
	
	reg [3:0] state;	//0=off, 1=attack, 2=decay, 3=release
	
	//reg signed [31:0] temp_buffer;
	
	reg signed [32:0] envelope;

	wire signed [15:0] envelope_truncated;
	
	assign envelope_truncated = envelope[32:17];
	
	always @(posedge clk or negedge reset) begin
		if (~reset) begin
			//temp_buffer <= 32'b0;
			state <= 4'b0;
			
			envelope <= 33'd0;
		end
		else begin
			//temp_buffer <= input_sample;
			//temp_buffer <= envelope_truncated * input_sample;
			//perform envelope modulation
			
			//output upper 16 bits signed
			output_sample <= (envelope_truncated * input_sample)[31:16];
		
			//adsr state machine
			case (state)
				
				0:	begin //note off
					//temp_buffer <= 66'b0;
					envelope <= 33'd0; 
					
					if (key_state == 1'b1) begin
						
						//capture adsr params into reg before begining the sequence
						attack_amt_reg <= attack_amt;
						decay_amt_reg <= decay_amt;
						sustain_amt_reg <= sustain_amt;
						rel_amt_reg <= rel_amt;   
						
						state <= 4'd1;
					end
					
				end
				
				1:	begin //attack 
					if (key_state == 1'b0)
						state <= 4'd3;
					else if (envelope < (33'h100000000 - attack_amt_reg))
						envelope <= envelope + attack_amt_reg;
					else
						state <= 4'd2; 
				end
						
				2:	begin //decay to sustain level 
					if (key_state == 1'b0)
						state <= 4'd3;
					else if (envelope > (sustain_amt_reg<<16))
						envelope <= envelope - decay_amt_reg;
				end
									
				3:	begin //release
					if (envelope > 33'd0+rel_amt_reg)
						envelope <= envelope - rel_amt_reg;
					else
						state <= 4'd0;
				end
				
			endcase
							
		end
		
	end
	
	
endmodule
	
	
	