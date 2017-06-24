 `timescale 10ns / 10ns

module adsr_tb;
	reg clk;
	reg reset;

	wire [15:0] attack_amt;
	wire [15:0] decay_amt;
	wire [15:0] sustain_amt;
	wire [15:0] rel_amt;
	
	reg key_state;
	
	wire signed [15:0] input_sample;
	wire signed [15:0] output_sample;
	

	wire [31:0] dds_phase;
	
	//DDS
	dds dds1(
	.clk(clk),
	.reset(reset),
	.delta_phase(1000000),
	.phase_acumulator(dds_phase)
	);

	square_wave square_wave
	(.clk(clk),
	.theta(dds_phase[31:22]),
	.square_sample(input_sample)
	);


	ADSR ADSR(
	.clk,
	.reset,
	
	.attack_amt,
	.decay_amt,
	.sustain_amt,
	.rel_amt,
	
	.key_state,	//0=key unpressed, 1=key pressed
	
	.input_sample,
	
	.output_sample
	);	
	

	always begin
		#1 clk = !clk;
	end
	
	
	assign attack_amt = 400;
	assign decay_amt = 200;
	assign sustain_amt = 20000;
	assign rel_amt = 100;
	
	initial
	begin
		clk = 0;   
		key_state = 0;

		reset = 0;
		#10 reset = 1;	  
		
		
		#20
		key_state = 1;


		
	end			 

	
		

	
endmodule		   		

	