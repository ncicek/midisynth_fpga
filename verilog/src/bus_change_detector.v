//outputs a 1 clk long pulse after a change in the bus is detected
module bus_change_detector #(
  parameter BUS_WIDTH = 8
)
(
	input wire i_clk,
	input wire [BUS_WIDTH-1:0] i_bus,
	output wire o_bus_change
);

reg [BUS_WIDTH-1:0] previous_bus;
reg bus_change = 0;

always @(posedge i_clk) begin
	previous_bus <= i_bus;
	if (i_bus != previous_bus) begin
		bus_change <= ~bus_change;
	end
end

wire pos_edge_strobe;
wire neg_edge_strobe;
pos_edge_det pos_edge_det (.sig(bus_change), .clk(i_clk), .pe(pos_edge_strobe));
neg_edge_det neg_edge_det (.sig(bus_change), .clk(i_clk), .pe(neg_edge_strobe));

assign o_bus_change = pos_edge_strobe | neg_edge_strobe;

endmodule
