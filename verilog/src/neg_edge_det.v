module neg_edge_det(
  input wire sig,
  input wire clk,
  output wire pe
);

  reg sig_dly;
  always @ (posedge clk) begin
    sig_dly <= sig;
  end

  assign pe = ~sig & sig_dly;
endmodule
