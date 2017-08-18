// `default_nettype none
module dds(
	input wire clk,
	input wire reset,

	input wire[7:0] voice_index,
	//parameters
	//input wire[63:0] dds_din,
	//input wire[7:0] dds_addr,
	//input wire dds_write_en,
	output wire[63:0] dds_dout,

	//outputs
	output reg[9:0] output_phase,
	output reg[7:0] voice_index_next
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
	//assign dout[31:0] = dout_current_phase;
	assign dout_current_phase= dout[31:0];
	//assign dout[63:32] = dout_delta_phase;
	assign dout_delta_phase = dout[63:32];

	reg [31:0] din_current_phase;
	reg [31:0] din_delta_phase;
	assign din[31:0] = din_current_phase;
	assign din[63:32] = din_delta_phase;

  ram #(.data_width(data_width),.(addr_width(8))) dds_ram(.din(din), .mask(mask),.addr(addr), .write_en(write_en), .clk(clk), .dout(dout));

  /*
  //*two port paramter ram
	//port a is voice_controller side
	//port b is local module side
 	/dds_ram	dds_ram (
		.DataInA(dds_din),
		.WrA(dds_write_en),
		.AddressA(dds_addr),
		.ClockA(clk),
		.ClockEnA(1'b1),
		.QA(dds_dout),
		.DataInB(din),
		.WrB(write_en),
		.AddressB(addr),
		.ClockB(clk),
		.ClockEnB(1'b1),
		.QB(dout),
		.ResetA(reset),
		.ResetB(reset)
	)

  pmi_ram_dp_true #(
    .pmi_addr_depth_a(256),
    .pmi_addr_width_a(8),
    .pmi_data_width_a(data_width),
    .pmi_addr_depth_b(256),
    .pmi_addr_width_b(8),
    .pmi_data_width_b(data_width),
    .pmi_regmode_a("noreg"),
    .pmi_regmode_b("noreg"),
    .pmi_gsr("disable"),
    .pmi_resetmode("sync"),
    .pmi_optimization("speed"),
    .pmi_init_file("none"),
    .pmi_init_file_format("binary"),
    .pmi_write_mode_a("normal"),
    .pmi_write_mode_b("normal"),
    .pmi_family("XO3L"),
    .module_type("pmi_ram_dp_true)")
	)
	dds_ram
    (.DataInA(dds_din),
     .DataInB(din),
     .AddressA(dds_addr),
     .AddressB(addr),
     .ClockA(clk),
     .ClockB(clk),
     .ClockEnA(1'b1),
     .ClockEnB(1'b1),
     .WrA(dds_write_en),
     .WrB(write_en),
     .ResetA(reset),
     .ResetB(reset),
     .QA(dds_dout),
     .QB(dout)
	 )synthesis syn_black_box */


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
