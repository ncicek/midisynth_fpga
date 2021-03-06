//`default_nettype none
`timescale 10ns / 10ns

//memory write masks
`define	MASK_CURRENT_PHASE 64'h00000000FFFFFFFF
`define	MASK_DELTA_PHASE 64'hFFFFFFFF00000000

module dds(
	input wire i_clk,
	input wire i_reset,

	input wire i_SPI_flag,
	input wire [31:0] i_SPI_tuning_code,
	input wire [7:0] i_SPI_voice_index,

	input wire[7:0] i_voice_index,
	input wire[1:0] i_pipeline_state,

	output reg[9:0] o_phase,
	output reg[7:0] o_voice_index_next
	);

	localparam  data_width = 64;

	wire [data_width-1:0] din;
	reg [data_width-1:0] mask;
	reg [7:0] addr = 8'b0;
	reg write_en = 1'b0;
	wire [data_width-1:0] dout;

	//memory bus bit assignments
	wire [31:0] dout_current_phase;
	wire [31:0] dout_delta_phase;
	assign dout_current_phase= dout[31:0];
	assign dout_delta_phase = dout[63:32];

	reg [31:0] din_current_phase;
	reg [31:0] din_delta_phase;
	assign din[31:0] = din_current_phase;
	assign din[63:32] = din_delta_phase;

	ram #(.addr_width(8),.data_width(data_width))
	dds_ram(.i_clk(i_clk), .i_reset(i_reset), .din(din), .mask(mask),.addr(addr), .write_en(write_en), .dout(dout));


	reg new_update_available;
	reg [31:0] delta_phase_update;  //buffers incoming delta phase updates for the above state machine to service
	reg [7:0] voice_addr_update;    //buffers incoming voice index updates "
	reg [31:0] temp;

	always @(posedge i_clk) begin
		if (i_reset == 1'b1) begin
			addr <= 8'b0;
			o_phase <= 10'b0;
			write_en <= 1'b0;
		end
		else begin
			case (i_pipeline_state)
				2'd0:	begin	//read from mem
					addr <= i_voice_index;
					o_voice_index_next <= i_voice_index;
					write_en <= 1'b0;
				end

				2'd1:	begin //compute and write back to mem
					write_en <= 1'b1;

					//verilog makes me want to cry :_(
					temp = dout_current_phase + dout_delta_phase;
					o_phase <= temp[31:22];
					mask <= `MASK_CURRENT_PHASE;
					din_current_phase <= temp;
				end

				2'd2: begin    //update ram
					write_en <= 1'b1;
					if (new_update_available) begin
						//new_update_ack <= 1'b0; //clear the bit
						addr <= voice_addr_update;
						mask <= `MASK_DELTA_PHASE;
						din_delta_phase <= delta_phase_update;
					end
				end
			endcase
		end
	end

	//check every clock edge if a new update is avaible and buffer it
	always @(posedge i_clk) begin
		if (i_reset)
			new_update_available <= 1'b0;
		else begin
			if (i_SPI_flag & ~new_update_available) begin
				delta_phase_update <= i_SPI_tuning_code;
				voice_addr_update <= i_SPI_voice_index;
				new_update_available <= 1'b1;
			end
			else if (new_update_available & i_pipeline_state==2'd2) //state2 is when we can reset because that is when above block samples new_update_available
				new_update_available <= 1'b0;
		end
	end

endmodule
