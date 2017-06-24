module midi_synth(
	input wire clk,
	input wire reset,
	input wire midi_port,
	
	//output wire [7:0] debug_bus,
	
	output wire [15:0] dac_out,
	output wire [7:0] leds,
	output wire [7:0] leds_2,
	output wire [7:0] leds_3
	);	
	
	
	wire received;
	wire midi_byte_ready;
	
	parameter POLYPHONY = 4;
	
	//Debug bus
	wire [7:0] debug_bus;
	wire [1:0] midi_decoder_state;
	wire [3:0] midi_rx_byte;
	//assign debug_bus[0] = clk;
	assign debug_bus[1] = received;
	assign debug_bus[2] = midi_port;
	assign debug_bus[3] = midi_byte_ready;
	//assign debug_bus[1] = key_state[0];
	//assign debug_bus [7:6] = midi_decoder_state;
	assign debug_bus[7:4] = midi_rx_byte;
	
	
	
	
	
	
	
	//generate the voice instances
	wire [31:0] dds_frequency_bus;
	wire [POLYPHONY-1:0] key_state;
	wire [3:0] shape_sel [POLYPHONY-1:0];
	wire signed [15:0] output_sample [POLYPHONY-1:0];
	
	assign shape_sel[0] = 4'd1;	//make sine waves
	assign shape_sel[1] = 4'd1;	//make sine waves
	assign shape_sel[2] = 4'd1;	//make sine waves
	assign shape_sel[3] = 4'd1;	//make sine waves
	
	
	generate
	  genvar i;
	  for (i=0; i<POLYPHONY; i=i+1) begin : voice_gen
		voice voice_i(
		  .clk(clk),
		  .reset(reset),
		  
		  .tuning_code(dds_frequency_bus),
		  .key_state(key_state[i]),
		  .shape_sel(shape_sel[i]),
		  .output_sample(output_sample[i])
		  
		  );
	  end
	endgenerate

		
		
		
		
	
	
	
	//Mixer
	reg signed [20:0] mixed_voices;
	reg signed [15:0] mixed_voices_dc_offset;
	always@(posedge clk or negedge reset) begin
	
		if (~reset) begin
			mixed_voices <= 21'b0;
			mixed_voices_dc_offset <= 16'b0;
		end
		
		else begin
			mixed_voices <= output_sample[0] + output_sample[1] + output_sample[2] + output_sample[3];
			mixed_voices_dc_offset <= mixed_voices[20:5] + 16'sd32768;
		end
		
	
	end

	assign dac_out = mixed_voices_dc_offset;









	//MIDI DECODER
	wire [7:0] midi_byte [2:0];
	
	midi_decoder midi_decoder(
	.clk(clk),
	.reset(reset),
	.midi_port(midi_port),
	
	.received(received),
	.midi_byte_ready(midi_byte_ready),
	.midi_byte0(midi_byte[0]),
	.midi_byte1(midi_byte[1]),
	.midi_byte2(midi_byte[2]),
	.rx_byte_dbg(midi_rx_byte)
	);
	
	assign leds = ~key_state;
	assign leds_2 = midi_byte[1];
	assign leds_3 = midi_byte[2];
	

	//MIDI CONTROLLER
	midi_controller midi_controller(
	.clk(clk),
	.reset(reset),
	
	.midi_byte_ready(midi_byte_ready),
	.midi_byte0(midi_byte[0]),	
	.midi_byte1(midi_byte[1]),
	.midi_byte2(midi_byte[2]),	
	
	.dds_frequency_bus(dds_frequency_bus),
	.key_state(key_state)
	);
	
	
	
endmodule