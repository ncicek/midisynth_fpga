module dds(
	input wire clk,
	input wire reset,

	//parameters
	input wire[31:0] delta_phase,
	input wire[7:0] voice_index,

	//outputs
	output reg[9:0] output_phase
	);

	reg [31:0] DataInWriter = 32'b0;
	reg [7:0] AddressReader = 8'b0;
	reg [7:0] AddressWriter = 8'b0;
	reg WrEn;
	wire [31:0] QReader;

	dptrueram dds_ram(
	.DataInA(32'b0),	//data in is unused since dataA is a reader port
	.DataInB(DataInWriter),
	.AddressA(AddressReader),
	.AddressB(AddressWriter),
	.ClockA(clk),
	.ClockB(clk),
	.ClockEnA(1'b1),
	.ClockEnB(1'b1),
	.WrA(1'b0),
	.WrB(WrEn),
	.ResetA(reset),
	.ResetB(reset),
	.QA(QReader),
	.QB()
	);

  reg [21:0] temp;
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			DataInWriter <= 32'b0;
			AddressReader <= 32'b0;
			AddressWriter <= 32'b0;
			output_phase <= 32'b0;

		end
		else begin
			AddressReader <= voice_index;

			//verilog makes me want to cry :_(
			temp = QReader + delta_phase;
			output_phase <= temp[21:12];

      //read the data at the current voice index
      //data represents the current voice index's previous phase
      //add this previous phase + the current delta_phase to create the current phase

      //write the current phase to the same voice index adress on the next posedge
			AddressWriter <= voice_index-1;
			DataInWriter <= QReader + delta_phase;
			WrEn <= 1'b1;

		end
	end



endmodule
