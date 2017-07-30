 `timescale 10ns / 10ns

module adsr_tb;
	reg clk;
	reg reset;

	wire [15:0] attack_amt;
	wire [15:0] decay_amt;
	wire [15:0] sustain_amt;
	wire [15:0] rel_amt;

	reg key_state;
	reg [7:0] voice_index = 0;

	wire signed [15:0] input_sample;
	wire signed [15:0] output_sample;


	wire [9:0] dds_phase;

	//DDS
	dds dds1 (.clk(clk),
	.reset(reset),
	.delta_phase(100000000),
	.voice_index(voice_index),
	.output_phase(dds_phase)
	);


	square_wave square_wave
	(.clk(clk),
	.theta(dds_phase),
	.square_sample(input_sample)
	);


	ADSR ADSR1 (.clk(clk),
	.reset(reset),
	.voice_index(voice_index),
	.attack_amt(attack_amt),
	.decay_amt(decay_amt),
	.sustain_amt(sustain_amt),
	.rel_amt(rel_amt),
	.key_state(key_state),
	.input_sample(input_sample),
	.output_sample(output_sample)
	);

	reg [10-1:0] mem_phase [(1<<8)-1:0];
	reg signed [16-1:0] mem_input [(1<<8)-1:0];
	reg signed [16-1:0] mem_output [(1<<8)-1:0];

	always begin
		#1 clk = !clk;
	end

	always begin
		#4	  
		voice_index = voice_index + 1;
		mem_output[voice_index]=output_sample;
		mem_input[voice_index]=input_sample;
		mem_phase[voice_index]=dds_phase;
		if (voice_index == 254)
			key_state = 1;
		else
      		key_state = 0;  
		

	end


	assign attack_amt = 400;
	assign decay_amt = 200;
	assign sustain_amt = 20000;
	assign rel_amt = 100;

	initial
	begin
		clk = 1;
		key_state = 0;

		reset = 0;
		#10 reset = 1;


		//#20
		//key_state = 1;
		//#25
		//key_state = 1;



	end





endmodule
