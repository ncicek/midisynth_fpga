module flag_synchronizer(
		input wire clkA,
		input wire FlagIn_clkA,   // this is a one-clock pulse from the clkA domain
		input wire clkB,
		output wire FlagOut_clkB   // from which we generate a one-clock pulse in clkB domain
);

reg FlagToggle_clkA;
always @(posedge clkA) FlagToggle_clkA <= FlagToggle_clkA ^ FlagIn_clkA;  // when flag is asserted, this signal toggles (clkA domain)

reg [2:0] SyncA_clkB;
always @(posedge clkB) SyncA_clkB <= {SyncA_clkB[1:0], FlagToggle_clkA};  // now we cross the clock domains

assign FlagOut_clkB = (SyncA_clkB[2] ^ SyncA_clkB[1]);  // and create the clkB flag
endmodule
