module ram (din, mask, addr, write_en, clk, dout);
	parameter addr_width = 8;
	parameter data_width = 8;
	input [addr_width-1:0] addr;
	input [data_width-1:0] din;
	input [data_width-1:0] mask;
	input wire write_en;
	input wire clk;
	output wire [data_width-1:0] dout;
	reg [data_width-1:0] mem [(1<<addr_width)-1:0];
		// Define RAM as an indexed memory array.

	always @(posedge clk) // Control with a clock edge.
	begin
		if (write_en) // And control with a write enable.
			mem[(addr)] <= (din & mask) | (mem[(addr)]&~mask);
	end
	assign dout = mem[addr];

integer i;
	initial
	begin

		for (i=0; i<(1<<addr_width); i=i+1) mem[i] <= {data_width{1'b0}};
	end
endmodule
