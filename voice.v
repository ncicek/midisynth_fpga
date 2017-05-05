module voice(
	input wire clk,
	input wire reset,
	
	input wire [31:0] tuning_code,
	input wire key_state,
	input wire [3:0] shape_sel,
	output wire signed [15:0] output_sample
	);

	reg [31:0] tuning_code_reg;	//captures the contents of the shared tuning code bus upon key on
	
	reg key_press;
	
	wire signed [15:0] sine_sample;
	wire signed [15:0] square_sample;
	reg signed [15:0] oscilator_shape;
	
	
	always @ (posedge clk or negedge reset) begin
		if (~reset) begin
			tuning_code_reg <= 32'b0;
			key_press <= 1'b0;
		end	
		//toggle key_press upon CHANGE of key_state
		else if (key_state == 1'b1 & key_press == 1'b0) begin
			tuning_code_reg <= tuning_code;
			key_press <= 1'b1;
		end
		else if (key_state == 1'b0 & key_press == 1'b1) begin
			key_press <= 1'b0;
		end

	end
	
	
	
	
	wire [31:0] dds_phase;
	
	//DDS
	dds dds1(
	.clk(clk),
	.reset(reset),
	.delta_phase(tuning_code_reg),
	.phase_acumulator(dds_phase)
	);
	
	
	
	//Phase to amplitude converter
	
	//sincos sinetable
	//(.Clock (clk),
	//.ClkEn (1'b1),
	//.Reset(reset), 
	//.Theta(dds_phase[31:22]),	//10 bit input
	//.Sine(sine_sample)	//16 bit signed output
	//);

	square_wave square_wave
	(.clk(clk),
	.theta(dds_phase[31:22]),
	.square_sample(square_sample)
	);
	
	
	//oscilator_shape mux
	always @ (posedge clk)
	begin
		case (shape_sel)
			4'b0000 : oscilator_shape <= sine_sample;
			4'b0001 : oscilator_shape <= square_sample;
			default : oscilator_shape <= square_sample;
		endcase
	end
	
		
	

	
	ADSR ADSR(
	.clk(clk),
	.reset(reset),
	
	.attack_amt(10000),
	.decay_amt(10000),
	.sustain_amt(40000),
	.rel_amt(1000),
	
	.key_state(key_press),
	.input_sample(oscilator_shape),
	.output_sample(output_sample)
	);



endmodule