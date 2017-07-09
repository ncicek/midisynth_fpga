module spi_controller (
  input wire clk,
  input wire reset,

  input wire SPI_sclk,
  input wire SPI_mosi,

  output reg SPI_note_status,
  output reg [7:0] SPI_voice_index,
  output reg [6:0] SPI_midi_note,
  output reg [6:0] SPI_velocity,
  output reg SPI_ready_flag
  );

  parameter NOTEON = 8'h90;
  parameter NOTEOFF = 8'h80;

  wire [7:0] rdata;
	wire sdout;
	wire done;
	spi_slave spi_slave (reset,1'b1,8'b0,1'b1,1'b0,sclk,mosi,sdout,done,rdata);

  reg state;
  reg [1:0] byte_counter;

  always @(posedge clk, posedge reset) begin
    if (reset == 1'b1) begin
      SPI_note_status <= 1'b1;
      SPI_voice_index <= 8'b0;
      SPI_midi_note <= 7'b0;
      SPI_velocity <= 7'b0;

      state <= 1'b0;
      byte_counter <= 2'd0;
    end
    else begin
      if (state == 1'b0 && done == 1'b1) begin  //posedge of rx_irq(done)
        state <= 1'b1;

        case (byte_counter)
  				0:	//note_status
  				begin
            SPI_ready_flag <= 1'b0;
            if (rdata == NOTEON) begin
              SPI_note_status <= 1'b1;
              byte_counter <= 3'd1
            end
            else if (rdata == NOTEOFF) begin
              SPI_note_status <= 1'b0;
              byte_counter <= //TODO
            end
  				end
  				1:	//voice_index
  				begin
            if (SPI_note_status == 1'b1) begin  //if noteon
              SPI_voice_index <= rdata;
              byte_counter <= 3'd2;
            end
            else if (SPI_note_status == 1'b0) begin  //if noteoff then we are done
              SPI_voice_index <= rdata;
              SPI_midi_note <= 7'b0;  //clear out these guys to avoid confusion
              SPI_velocity <= 7'b0;
              SPI_ready_flag <= 1'b1;
              byte_counter <= 3'd0;
            end
  				end
  				2:	//midi_note
  				begin
            if (rdata[7] == 1'b0) begin //check that msb of midi_note byte should be 0
              SPI_midi_note <= rdata[6:0];
              byte_counter <= 3'd3;
            end
            else
              byte_counter <= 3'd0;
  				end
          3:
          begin
            if (rdata[7] == 1'b0) begin //check that msb of midi_note byte should be 0
              SPI_velocity <= rdata[6:0];
              byte_counter <= 3'd4;
              SPI_ready_flag <= 1'b1;
            end
            else
              byte_counter <= 3'd0;
          end
  			endcase

      end
      else if (state == 1'b1 && done == 1'b0) begin //needed to track edges
        state <= 1'b0;
      end
    end
  end

endmodule