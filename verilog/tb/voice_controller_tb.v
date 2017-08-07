`timescale 10ns / 10ns

module voice_controller_tb;
 reg clk;
 reg reset;


 reg SPI_note_status;
 reg [7:0] SPI_voice_index;
 reg [6:0] SPI_midi_note;
 reg [6:0] SPI_velocity;   	
 reg SPI_ready_flag;
 wire signed [15:0] output_sample;		
 voice_controller voice_controller (.clk(clk),
 	.reset(reset),
 	.SPI_note_status(SPI_note_status),
 	.SPI_voice_index(SPI_voice_index),
 	.SPI_midi_note(SPI_midi_note),
 	.SPI_velocity(SPI_velocity),
 	.SPI_ready_flag(SPI_ready_flag),
 	.output_sample(output_sample)
 );

 always begin
   #1 clk = !clk;
 end


 initial
 begin
   clk = 1;
   reset = 0;		 
   #10 reset = 1;


   #20
   SPI_voice_index = 1;
   SPI_midi_note = 40;
   SPI_note_status = 1;
   //key_state = 1;
   //#25
   //key_state = 1;



 end





endmodule
