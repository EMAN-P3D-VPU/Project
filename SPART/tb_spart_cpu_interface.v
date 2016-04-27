`timescale 1ns / 1ps
module tb_spart_cpu_interface();

// inputs
reg clk;
reg rst;

// spart module
reg rda;
reg [7:0] databus;

// outputs
wire [4:0] bit_mask;
wire bit_mask_ready;

spart_cpu_interface test(.clk(clk),
			.rst(rst),
			.rda(rda),
			.databus(databus),
			.bit_mask(bit_mask),
			.bit_mask_ready(bit_mask_ready));

initial begin
	clk = 1'b0;
	rst = 1'b1;
	rda = 1'b0;
	databus = 8'bz;

	$display("Initializing...");
	#10
	
	if (bit_mask != 5'b0 && bit_mask_ready != 1'b0) begin
		$display("Incorrect bitmask: %d, bit_mask_ready %d", bit_mask, bit_mask_ready);
	end

	rst = 1'b0;
	databus = 8'h11;
	rda = 1'b1;
	$display("Try and put in the character");

	#10

	if (bit_mask != 5'b0 && bit_mask_ready != 1'b0) begin
		$display("Incorrect bitmask: %d, bit_mask_ready %d", bit_mask, bit_mask_ready);
	end

	rda = 1'b0;
	databus = 8'h77;

	#10
	if (bit_mask != 5'b0 && bit_mask_ready != 1'b0) begin
		$display("Incorrect bitmask: %d, bit_mask_ready %d", bit_mask, bit_mask_ready);
	end

	rda = 1'b1;
	$display("Emulate Pressing W");
	#10

	if (bit_mask != 5'b10000 && bit_mask_ready != 1'b1) begin
		$display("Incorrect bitmask: %d, bit_mask_ready %d", bit_mask, bit_mask_ready);
	end


	$display("Check one more clock cycle");
	#10
	if (bit_mask_ready != 1'b0) begin
		$display("Incorrect bit_mask_ready %d", bit_mask_ready);
	end

	rda = 1'b0;
	databus = 8'h6A;

	#10

	if (bit_mask_ready != 1'b0) begin
		$display("Incorrect bit_mask_ready %d", bit_mask_ready);
	end

	$display ("Emulate Pressing J");
	rda = 1'b1;

	#10
	if (bit_mask != 5'b10001 && bit_mask_ready != 1'b1) begin
		$display("Incorrect bitmask: %d, bit_mask_ready %d", bit_mask, bit_mask_ready);
	end

	#10

	$display("Check one more clock cycle");
	if (bit_mask_ready != 1'b0) begin
		$display("Incorrect bit_mask_ready %d", bit_mask_ready);
	end

	$finish();
end

always
	#5 clk = ~clk;

endmodule