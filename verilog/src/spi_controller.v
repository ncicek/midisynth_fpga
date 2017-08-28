//`default_nettype none
module spi_controller (
	input wire i_clk,
	input wire i_reset,

	input wire i_SPI_sclk,
	input wire i_SPI_mosi,

	output reg o_SPI_note_status,
	output reg [7:0] o_SPI_voice_index,
	output reg [31:0] o_SPI_tuning_code,
	output reg [6:0] o_SPI_velocity,
	output reg o_SPI_flag,//acts as a strobe to show when SPI data is valid

	output reg [7:0] leds_0,leds_1,leds_2,
  output wire [1:0] byte_counter_debug
	);

	parameter NOTEON = 8'h90;
	parameter NOTEOFF = 8'h80;

	wire [7:0] rdata;
	wire sdout;
	wire SPI_done;
	spi_slave spi_slave (i_reset,1'b1,8'b0,1'b1,1'b0,i_SPI_sclk,i_SPI_mosi,sdout,SPI_done,rdata);

	//need to synchronize rdata and done into the fpga clk domain
	wire SPI_done_meta_stable;
	wire done_sync;

	two_flop_cdc two_flop_cdc(.i_clk(i_clk), .i_sig(SPI_done), .o_sig(SPI_done_meta_stable));
	pos_edge_det pos_edge_det (.sig(SPI_done_meta_stable), .clk(i_clk), .pe(done_sync));

	reg [1:0] byte_counter;
  assign byte_counter_debug[0] = done_sync;
  assign byte_counter_debug[1] = SPI_done;

	wire [31:0] tuning_code;
	reg [6:0] midi_byte;

	always @(posedge i_clk) begin
		if (i_reset == 1'b1) begin
			o_SPI_note_status <= 1'b1;
			o_SPI_voice_index <= 8'b0;
			o_SPI_tuning_code <= 7'b0;
			o_SPI_velocity <= 7'b0;
			o_SPI_flag <= 1'b0;

			byte_counter <= 2'd0;
		end
		else begin
			case (byte_counter)
				0:	//note_status
				begin
					o_SPI_flag <= 1'b0;
          if (done_sync) begin	//posedge of rx_irq(done) begin
  					if (rdata == NOTEON) begin
  						o_SPI_note_status <= 1'b1;
  						byte_counter <= 2'd1;
  					end
  					else if (rdata == NOTEOFF) begin
  						o_SPI_note_status <= 1'b0;
  						byte_counter <= 2'd1;
  					end
          end
				end
				1:	//voice_index
				begin
          if (done_sync) begin	//posedge of rx_irq(done)
  					if (o_SPI_note_status == 1'b1) begin	//if noteon
  						o_SPI_voice_index <= rdata;
  						byte_counter <= 2'd2;
  					end
  					else if (o_SPI_note_status == 1'b0) begin	 //if noteoff then we are done
  						o_SPI_voice_index <= rdata;
  						o_SPI_tuning_code <= 31'b0;  //clear out these guys to avoid confusion
              midi_byte <= 7'b0;
  						o_SPI_velocity <= 7'b0;
  						o_SPI_flag <= 1'b1;
  						byte_counter <= 2'd0;
  					end
          end
				end
				2:	//midi_note
				begin
          if (done_sync) begin	//posedge of rx_irq(done)
  					if (rdata[7] == 1'b0) begin //check that msb of midi_note byte should be 0
  						midi_byte <= rdata[6:0];
  						byte_counter <= 2'd3;
  					end
  					else
  						byte_counter <= 2'd0;
          end
				end
				3:
        begin
          if (done_sync) begin	//posedge of rx_irq(done)
  					if (rdata[7] == 1'b0) begin //check that msb of midi_note byte should be 0
  						o_SPI_tuning_code <= tuning_code;
  						o_SPI_velocity <= rdata[6:0];
  						byte_counter <= 2'd0;
  						o_SPI_flag <= 1'b1;
  					end
  					else
  						byte_counter <= 2'd0;
          end
				end
			endcase
		end
	end

	tuning_code_lookup tuning_code_lookup(.i_clk(i_clk),.midi_byte(midi_byte),.tuning_code(tuning_code));

	//debug leds
	always @(posedge i_clk) begin
		if (o_SPI_flag) begin
			leds_0 <= midi_byte;
			leds_2 <= o_SPI_velocity;
		end
	end

endmodule
