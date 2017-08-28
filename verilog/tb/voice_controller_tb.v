`timescale 10ns / 10ns
`default_nettype none
module voice_controller_tb;
	reg clk;
	reg reset;
	reg SPI_flag;
	reg [31:0] SPI_tuning_code;
	reg [7:0] SPI_voice_index;
  reg SPI_note_status;
  wire signed [23:0] mixed_sample;

  voice_controller voice_controller(
  	.i_clk(clk),
  	.i_reset(reset),
  	.i_SPI_note_status(SPI_note_status),
  	.i_SPI_voice_index(SPI_voice_index),
  	.i_SPI_tuning_code(SPI_tuning_code),
  	.i_SPI_velocity(),
  	.i_SPI_flag(SPI_flag),
  	.o_mixed_sample(mixed_sample)
  	);

	always begin
		#1 clk = !clk;
	end


	initial
	begin
    //$dumpfile("dds_tb.vcd");
    //$dumpvars;
    //for (lp=0; lp < 256; lp = lp+1) $dumpvars(0, mem_output[lp]);
    //$dumplimit(1000000000);
		clk = 1;
		reset = 1;
		#10 reset = 0;


    #4//start note
    SPI_flag = 1;
    SPI_tuning_code = 20*1000000;
    SPI_voice_index = 253;
    SPI_note_status = 1'b1;
		#2
    SPI_flag = 0;

/*
    #10000000 //stop note
    SPI_flag = 1;
    SPI_voice_index = 5;
    SPI_note_status = 1'b0;
    #2
    SPI_flag = 0;
*/
		#20//start note
		SPI_flag = 1;
    SPI_tuning_code = 20*1000000;
    SPI_voice_index = 252;
    SPI_note_status = 1'b1;
    #2
    SPI_flag = 0;
		/*
    #10000000 //stop note
    SPI_flag = 1;
    SPI_voice_index = 1;
    SPI_note_status = 1'b0;
    #2
    SPI_flag = 0;

    //#100000000 $finish;
		*/
		#20000000 $finish;

	end

endmodule
