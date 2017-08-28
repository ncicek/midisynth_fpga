module two_flop_cdc(
		input wire i_clk,
		input wire i_sig,
		output wire o_sig
);

  reg [1:0] cdc;

  always @(posedge i_clk) begin
    cdc[0] <= i_sig;
    cdc[1] <= cdc[0];
  end

  assign o_sig = cdc[1];

endmodule
