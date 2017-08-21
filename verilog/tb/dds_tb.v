`timescale 10ns / 10ns
`default_nettype none
module dds_tb;
	reg clk;
	reg reset;

	reg [7:0] voice_index = 0;


	reg SPI_flag;
	reg [31:0] SPI_tuning_code;
	reg [7:0] SPI_voice_index;
	wire [9:0] phase;

	wire [7:0] o_voice_index_next;

	reg [1:0] pipeline_state  ;
	//DDS
	dds dds (.i_clk(clk),
	.i_reset(reset),
	.i_SPI_flag(SPI_flag),
	.i_SPI_tuning_code(SPI_tuning_code),
	.i_SPI_voice_index(SPI_voice_index),
	.i_voice_index(voice_index),
	.i_pipeline_state(pipeline_state),
	.o_phase(phase),
	.o_voice_index_next(o_voice_index_next)
	);

  reg [3:0] wave_select = 4'd1;
	wire signed [15:0] wavetable_output;
	wire [7:0] wavetable_voice_index_next;
	wavetable wavetable(.i_clk(clk),.i_reset(reset),.i_phase(phase),.i_wave_select(wave_select),.i_voice_index(o_voice_index_next),.i_pipeline_state(pipeline_state),.o_voice_index_next(wavetable_voice_index_next),.o_sample(wavetable_output));

  wire signed [15:0] voice_chain_output;
  reg SPI_note_status;
  ADSR ADSR (
    .i_clk(clk),
    .i_reset(reset),

    .i_SPI_flag(SPI_flag),
    .i_SPI_note_status(SPI_note_status),
    .i_SPI_voice_index(SPI_voice_index),

    .i_voice_index(wavetable_voice_index_next),
    .i_pipeline_state(pipeline_state),
    .i_sample(wavetable_output),

    .i_attack_amt(16'd10000),
    .i_decay_amt(16'd10000),
    .i_sustain_amt(16'd10000),
    .i_rel_amt(16'd1000),

    .o_sample(voice_chain_output)
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

  reg signed [23:0] output_sample;
  reg signed [23:0] mixer_buffer;
	always begin
		#2
		pipeline_state = 4'd0;
		#2
		pipeline_state = 4'd1;
		#2
		pipeline_state = 4'd2;
    mem_phase[voice_index]=phase;
    mem_input[voice_index]=wavetable_output;
    mem_output[voice_index]=voice_chain_output;


    if (voice_index == 8'hff) begin
      output_sample <= mixer_buffer + voice_chain_output;  //spit out a mixed sample
      mixer_buffer <= 24'sd0;   //clear the mixer buffer when voice counter is full to prepare for the next sample
    end
    else begin
      mixer_buffer <= mixer_buffer + voice_chain_output;
    end

	end

	reg send_SPI;
	always @(posedge clk) begin
		if (pipeline_state == 4'd0)
			voice_index = voice_index + 1;

	end

  integer lp;

	initial
	begin
    //$dumpfile("dds_tb.vcd");
    //$dumpvars;
    //for (lp=0; lp < 256; lp = lp+1) $dumpvars(0, mem_output[lp]);
    //$dumplimit(1000000000);
		clk = 1;
		reset = 1;
		send_SPI = 0;
		#10 reset = 0;


    #4
    SPI_flag = 1;
    SPI_tuning_code = 20*1000000;
    SPI_voice_index = 5;
    SPI_note_status = 1'b1;
    #2
    SPI_flag = 0;
    #10000000
    SPI_flag = 1;
    SPI_voice_index = 5;
    SPI_note_status = 1'b0;
    #2
    SPI_flag = 0;


    //#100000000 $finish;

	end






endmodule
