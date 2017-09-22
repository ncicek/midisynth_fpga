`timescale 1ns / 1ns
`default_nettype none
module voice_controller_tb;
	reg clk;
	reg reset;
	reg SPI_flag_dds;
	reg SPI_flag_adsr;
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
  	.i_SPI_flag_dds(SPI_flag_dds),	
	.i_SPI_flag_adsr(SPI_flag_adsr),
  	.o_mixed_sample(mixed_sample)
  	);

	wire [15:0] o_dac_out;
	//assign o_dac_out = mixed_sample[23:8] + 16'd32768;	 //dc offset into the middle of the dac range
	assign o_dac_out = mixed_sample[18:3] + 16'sd32768;	 //dc offset into the middle of the dac range

	always begin
		#1 clk = ~clk;
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


    #400//start note
    SPI_flag_dds = 1;	   	 
	SPI_flag_adsr = 1;
    SPI_tuning_code = 20*1000000;
    SPI_voice_index = 253;
    SPI_note_status = 1'b1;
	#2
    SPI_flag_dds = 0;	   	 
	SPI_flag_adsr = 0;


    #1000000 //stop note		   
    SPI_flag_adsr = 1;
    SPI_voice_index = 253;
    SPI_note_status = 1'b0;
    #2
    SPI_flag_adsr = 0;
 /*
		#20//start note
		SPI_flag = 1;
    SPI_tuning_code = 20*1000000;
    SPI_voice_index = 252;
    SPI_note_status = 1'b1;
    #2
    SPI_flag = 0;

    #500000 //stop note
    SPI_flag = 1;
    SPI_voice_index = 252;
    SPI_note_status = 1'b0;
    #2
    SPI_flag = 0;

    //#100000000 $finish;

		//#20000000 $finish;
*/
	end

endmodule
