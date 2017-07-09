module ADSR(
	input wire clk,
	input wire reset,

	input wire[7:0] voice_index,

	//parameters
	input wire [15:0] attack_amt,
	input wire [15:0] decay_amt,
	input wire [15:0] sustain_amt,
	input wire [15:0] rel_amt,
	input wire key_state,	//0=key unpressed, 1=key pressed

	input wire signed [15:0] input_sample,

	output reg signed [15:0] output_sample
	);

	reg [127:0] DataInWriter = 127'b0;
	reg [7:0] AddressReader = 8'b0;
	reg [7:0] AddressWriter = 8'b0;
	reg WrEn;
	wire [127:0] QReader;

	reg [3:0] state;
	reg signed [32:0] envelope;

	dptrueram (
		.addr_width(8),
		.data_width(128)
	)
	dds_ram(
	.dina(128'b0),	//data in is unused since dataA is a reader port
	.dinb(DataInWriter),
	.addra(AddressReader),
	.addrb(AddressWriter),
	.clka(clk),
	.clkb(clk),
	.write_ena(1'b0),
	.write_enb(WrEn),
	.douta(QReader),
	.doutb()
	);

	reg [15:0] attack_amt_reg;
	reg [15:0] decay_amt_reg;
	reg [15:0] sustain_amt_reg;
	reg [15:0] rel_amt_reg;


	//inernal wire. required to convert unsigned to signed before multiplying
	wire signed [15:0] envelope_truncated;
	assign envelope_truncated = envelope[32:17];



	always @(posedge clk or negedge reset) begin
		if (~reset) begin
			DataInWriter <= 128'b0;
			AddressReader <= 128'b0;
			AddressWriter <= 128'b0;

			attack_amt_reg <= 16'b0;
			decay_amt_reg <= 16'b0;
			sustain_amt_reg <= 16'b0;
			rel_amt_reg <= 16'b0;

			state <= 4'b0;

			envelope <= 33'd0;
		end
		else begin
			AddressReader <= voice_index;
			state <= QReader[3:0];




			//perform envelope modulation
			//output upper 16 bits signed
			output_sample <= (envelope_truncated * input_sample)[31:16];

			//adsr state machine
			case (state)
				0:	begin //note off
					envelope <= 33'd0;
					if (key_state == 1'b1) begin
						//capture adsr params into reg before begining the sequence
						attack_amt_reg <= attack_amt;
						decay_amt_reg <= decay_amt;
						sustain_amt_reg <= sustain_amt;
						rel_amt_reg <= rel_amt;

						state <= 4'd1;
					end
				end
				1:	begin //attack
					if (key_state == 1'b0)
						state <= 4'd3;
					else if (envelope < (33'h100000000 - attack_amt_reg))
						envelope <= envelope + attack_amt_reg;
					else
						state <= 4'd2;
				end

				2:	begin //decay to sustain level
					if (key_state == 1'b0)
						state <= 4'd3;
					else if (envelope > (sustain_amt_reg<<16))
						envelope <= envelope - decay_amt_reg;
				end

				3:	begin //release
					if (envelope > 33'd0+rel_amt_reg)
						envelope <= envelope - rel_amt_reg;
					else
						state <= 4'd0;
				end

			endcase

		end

	end


endmodule
