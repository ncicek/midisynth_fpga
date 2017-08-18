 `timescale 10ns / 10ns

module dds_tb;
	reg clk;
	reg reset;

	reg [7:0] voice_index = 0;

	
	reg SPI_flag;
	reg [6:0] SPI_midi_note;
	reg [7:0] SPI_voice_index;	 
	wire [9:0] o_phase	;	
	
	wire [7:0] o_voice_index_next;
	
	reg [1:0] pipeline_state  ;
	//DDS
	dds dds (.i_clk(clk),
	.i_reset(reset),
	.i_SPI_flag(SPI_flag),
	.i_SPI_midi_note(SPI_midi_note),
	.i_SPI_voice_index(SPI_voice_index),
	.i_voice_index(voice_index),
	.i_pipeline_state(pipeline_state),
	.o_phase(o_phase),
	.o_voice_index_next(o_voice_index_next)
	);
	

	reg [10-1:0] mem_phase [(1<<8)-1:0];
	reg signed [16-1:0] mem_input [(1<<8)-1:0];
	reg signed [16-1:0] mem_output [(1<<8)-1:0];

	always begin
		#1 clk = !clk;
	end
   	/*
	always begin
		#4 
		voice_index = voice_index + 1;
		mem_output[voice_index]=output_sample;
		mem_input[voice_index]=input_sample;
		mem_phase[voice_index]=dds_phase; 
		

	end	 */
	
	always begin
		#2 
		pipeline_state = 4'd0; 	
		#2
		pipeline_state = 4'd1;
		#2
		pipeline_state = 4'd2;
	end			 
	
	reg send_SPI;
	always @(posedge clk) begin
		if (pipeline_state == 4'd1)
			voice_index = voice_index + 1;	
			
		if (send_SPI) begin
			SPI_flag = 1;  
			SPI_midi_note = 30;
			SPI_voice_index = 3;	 	
		end	
		else begin
			SPI_flag = 0;  	
		end
	end	

	initial
	begin
		clk = 1;
		reset = 1;	
		send_SPI = 0;
		#10 reset = 0;	   
		
		#200
		send_SPI = 1;

		#2
		send_SPI = 0;
		

	end





endmodule
