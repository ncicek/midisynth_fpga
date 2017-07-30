module dds(
	input wire clk,
	input wire reset,

	//parameters
	input wire[31:0] delta_phase,
	input wire[7:0] voice_index,

	//outputs
	output reg[9:0] output_phase
	);

	reg [31:0] din = 32'b0;
	reg [7:0] addr = 8'b0;
	reg [7:0] AddressWriter = 8'b0;
	reg write_en;
	wire [31:0] dout;

	ram #(
		.addr_width(8),
		.data_width(32)
	)
	dds_ram(
	.din(din), .addr(addr), .write_en(write_en), .clk(clk), .dout(dout)
	);

  	reg [31:0] temp;
	reg cycle; //read or write cycle

	always @(posedge clk or negedge reset) begin
		if (~reset) begin
			din <= 32'b0;
			addr <= 32'b0;
			output_phase <= 10'b0;
			cycle <= 1'b0;
			write_en <= 1'b0;
		end
		else begin
			case (cycle)
				0:	begin	//read from mem
					addr <= voice_index;
					write_en <= 1'b0;

					cycle <= 1'b1;
				end

				1:	begin //compute and write back to mem
					//addr <= voice_index;
					write_en <= 1'b1;

					//verilog makes me want to cry :_(
					temp = dout + delta_phase;
					output_phase <= temp[31:22];

					din <= dout + delta_phase;

					cycle <= 1'b0;
				end
			endcase
		end
	end



endmodule
