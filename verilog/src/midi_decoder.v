module midi_decoder(
	input wire clk,
	input wire reset,
	input wire midi_port,
	
	output wire received,
	output reg midi_byte_ready,		//asserts upon recieving all three bytes
	output reg [7:0] midi_byte0,	//status byte
	output reg [7:0] midi_byte1,	//data1 byte
	output reg [7:0] midi_byte2,		//data2 byte
	output wire [3:0] rx_byte_dbg
	);
	
	wire [7:0] rx_byte;
	assign rx_byte_dbg = rx_byte[7:4];
		
	//uart #(.CLOCK_DIVIDE(384))	//CLOCK_DIVIDE = Frequency(clk) / (4 * Baud)
	//midi_uart (clk, reset, midi_port,  , 1'b0, 8'b0, received, rx_byte, , , );
	
	uart_rx #(
    .DATA_WIDTH(8)
	)
	midi_uart (
		.clk(clk),
		.rst(~reset),
		// axi output
		.output_axis_tdata(rx_byte),
		.output_axis_tvalid(received),
		.output_axis_tready(1'b1),
		// input
		.rxd(midi_port),
		// status
		.busy(),
		.overrun_error(),
		.frame_error(),
		// configuration
		.prescale(192)
	);

	reg [7:0] temp_midi_byte [2:0];	//internally stores midi bytes	
	reg [2:0] state;
	
	parameter FIRST_DATA_BYTE = 0, SECOND_DATA_BYTE = 1;
	reg data_byte_state;	//which data byte are we expecting next
	
	parameter SINGLE_DATA_BYTE = 0, TWO_DATA_BYTES = 1;
	reg data_byte_type;		//what type of data bytes this status command uses
	
	always @(posedge clk or negedge reset) begin
		if (~reset) begin
			state <= 4'b0;
			
			data_byte_state <= FIRST_DATA_BYTE;
			data_byte_type <= TWO_DATA_BYTES;
			
			temp_midi_byte[0] <= 8'b0;
			temp_midi_byte[1] <= 8'b0;
			temp_midi_byte[2] <= 8'b0;			
			
			midi_byte0 <= 8'b0;	  
			midi_byte1 <= 8'b0;
			midi_byte2 <= 8'b0;
			
			midi_byte_ready <= 1'b0;
			
		end
		
		else begin	
			case (state)
				0:	//idle state
				begin
					midi_byte_ready <= 1'b0;
					if (received)	//wait for a byte
						state <= 1;
				end
					
				1:	//parser state
				begin
					state <= 0;	//gonna go back to 0 unless something changes state
					if (rx_byte[7] == 1'b1) //if it is a status byte
					begin				
						temp_midi_byte[0] <= rx_byte;
						data_byte_state <= FIRST_DATA_BYTE; 
						
						if (rx_byte[7:4] == 4'b1100 || //program change
							rx_byte[7:4] == 4'b1101 || //channel pressure (global aftertouch)
							rx_byte[7:4] == 4'b1111    //time code quarter
							)
							data_byte_type <= SINGLE_DATA_BYTE;
						else
							data_byte_type <= TWO_DATA_BYTES;
					end
					else begin	//if it is a data byte			
						if (data_byte_state == FIRST_DATA_BYTE) begin
							temp_midi_byte[1] <= rx_byte;
							if (data_byte_type == TWO_DATA_BYTES)
								data_byte_state <= SECOND_DATA_BYTE;
							else begin	//otherwise the byte is ready
								temp_midi_byte[2] <= 8'b0;	//clear 2nd data byte if this is a single dbyte message
								state <= 2;
							end
						end		
						else begin	//else if (data_byte_state == SECOND_DATA_BYTE)
							temp_midi_byte[2] <= rx_byte;
							data_byte_state <= FIRST_DATA_BYTE;
							state <= 2;
						end
					end
				end
				
				2:	//done state
				begin
					midi_byte_ready <= 1'b1;
					
					midi_byte0 <= temp_midi_byte[0];
					midi_byte1 <= temp_midi_byte[1];
					midi_byte2 <= temp_midi_byte[2];
					
					if (!received)	//make sure received has deasserted before going to idle state
						state <= 0;
				end
			endcase
		end
	end	
endmodule