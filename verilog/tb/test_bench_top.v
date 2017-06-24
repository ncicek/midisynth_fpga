 `timescale 10ns / 10ns

module midi_synth_top;
	reg clk;
	reg button;
	
	reg transmit;
	reg	[7:0] tx_byte;
	
	midi_synth midi_synth (.clk(clk),
	.reset(~button),
	.midi_port(midi_port),
	.debug_bus(debug_bus),
	.dac_out(dac_out),
	.leds(leds),
	.leds_2(leds_2),
	.leds_3(leds_3)
	);
	
	
	
	uart #(.CLOCK_DIVIDE(384))	//CLOCK_DIVIDE = Frequency(clk) / (4 * Baud)
	uart (.clk(clk),
	.rst(~button),
	.rx(),
	.tx(midi_port),
	.transmit(transmit),
	.tx_byte(tx_byte),
	.received(),
	.rx_byte(),
	.is_receiving(),
	.is_transmitting(),
	.recv_error()
	);

	
	initial
	begin
		clk = 0;   
		transmit = 0;

		button = 1;
		#10 button = 0;	  
		
		
		#20

		send_key(1,8'd50);
		
		#1000000000 send_key(0,8'd50);
		
		send_key(1,8'd50);	
		send_key(1,8'd54); 
		send_key(0,8'd50); 
		send_key(0,8'd54);

		
	end			 

	always begin
		#1 clk = !clk;
	end
		
	
		
	task send_key;	   
	input state;
	input [7:0] note;
	 begin
	
		//ON KEY//////////////////////////////
		#60000
		tx_byte = 8'b10010001;
		transmit = 1;
		#10
		transmit = 0;
		
		#60000	
		tx_byte = note;
		transmit = 1;
		#10
		transmit = 0; 
		
		#60000
		if (state == 1)
			tx_byte = 8'b00011111;
		else
			tx_byte = 8'b00000000;
		transmit = 1;
		#10
		transmit = 0;
		
	end	

	endtask	

	
endmodule		   		

	