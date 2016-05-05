`timescale 1ns / 1ps
module tb_display_plane();

// inputs
reg clk, rst, fifo_full;

// outputs
wire [12:0] addr;
wire write_enable;

display_plane test(
			.clk(clk),
			.rst(rst),
			.fifo_full(fifo_full),
			.addr(addr),
			.write_enable(write_enable));


integer i;
integer j;

wire [12:0] final_result;
assign final_result = (j * 80) + (i % 80);

initial begin
	//initial positions
	rst = 1;
	clk = 0;
	fifo_full = 0;

	#5;

	// check if stall works
	rst = 0;
	fifo_full = 1;

	#10;

	fifo_full = 0;

	// Test all values
	for (j = 0; j < 60; j = j + 1) begin
		for (i = 0; i < (80 * 8); i = i + 1) begin
			if (addr != final_result) begin
				$display("Addr incorrect!: %d %d", addr, final_result);
			end
			#10;
		end
	end

	$finish();
end

always
	#5 clk = ~clk;

endmodule