 `default_nettype none
module dds(
	input wire clk,
	input wire reset,

	input wire[7:0] voice_index,
	//parameters
	input wire[63:0] dds_din,
	input wire[7:0] dds_addr,
	input wire dds_write_en,
	output wire[63:0] dds_dout,

	//outputs
	output reg[9:0] output_phase,
	output reg[7:0] voice_index_next
	);

	localparam  data_width = 64;

	wire [data_width-1:0] din;
	reg [7:0] addr = 8'b0;
	reg write_en = 1'b0;
	wire [data_width-1:0] dout;

	//memory bus bit assignments
	wire [31:0] dout_current_phase;
	wire [31:0] dout_delta_phase;
	assign dout[31:0] = dout_current_phase;
	assign dout[63:32] = dout_delta_phase;

	reg [31:0] din_current_phase;
	reg [31:0] din_delta_phase;
	assign din[31:0] = din_current_phase;
	assign din[63:32] = din_delta_phase;

	//two port paramter ram
	//port a is voice_controller side
	//port b is local module side
	dptrueram #(
		.addr_width(8),
		.data_width(data_width)
	)
	dds_ram (
		.dina(dds_din),
		.write_ena(dds_write_en),
		.addra(dds_addr),
		.clka(clk),
		.douta(dds_dout),
		.dinb(din),
		.write_enb(write_en),
		.addrb(addr),
		.clkb(clk),
		.doutb(dout)
	);


  reg [31:0] temp;
	reg cycle; //read or write cycle

	always @(posedge clk) begin
		if (reset == 1'b1) begin
			addr <= 8'b0;
			output_phase <= 10'b0;
			cycle <= 1'b0;
			write_en <= 1'b0;
		end
		else begin
			//default do not modify ram contents
			//in state machine below, some of these will be overidden as part of the RMW sequnece
			din_current_phase <= dout_current_phase;
			din_delta_phase <= dout_delta_phase;
			case (cycle)
				0:	begin	//read from mem
					addr <= voice_index;
					voice_index_next <= voice_index;
					write_en <= 1'b0;

					cycle <= 1'b1;
				end

				1:	begin //compute and write back to mem
					//addr <= voice_index;
					write_en <= 1'b1;

					//delta_phase = dout[63:32];
					//verilog makes me want to cry :_(
					temp = dout_current_phase + dout_delta_phase;
					output_phase <= temp[31:22];

					din_current_phase <= temp;
					cycle <= 1'b0;
				end

				2: begin
					//TODo
					//stop state
					//halts ram writes to allow voice controller to write a parameter
				end
			endcase
		end
	end



endmodule
