//LSE should infer this as true dual port blockram
module dptrueram (dina, write_ena, addra, clka, douta,
  dinb, write_enb, addrb, clkb, doutb);
  parameter addr_width = 8;
  parameter data_width = 8;
  input [addr_width-1:0] addra, addrb;
  input [data_width-1:0] dina, dinb;
  input wire write_ena, clka, write_enb, clkb;
  output [data_width-1:0] douta, doutb;
  reg [data_width-1:0] douta, doutb;
  reg [data_width-1:0] mem [(1<<addr_width)-1:0]
    /* synthesis syn_ramstyle = "no_rw_check" */ ;

  always @(posedge clka) // Using port a.
  begin
    if (write_ena)
      mem[addra] <= dina; // Using address bus a.
    douta <= mem[addra];
  end
  always @(posedge clkb) // Using port b.
  begin
    if (write_enb)
      mem[addrb] <= dinb; // Using address bus b.
    doutb <= mem[addrb];
  end

  //initial

	//begin
	//	integer i;
	//	for (i=0; i<100000; i=i+1) mem[i] <= 256'b0;
	//end
endmodule
