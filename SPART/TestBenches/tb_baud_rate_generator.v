`timescale 1ns / 1ps
module tb_baud_rate_generator();

// inputs
reg clk, rst, isReady;
reg [7:0] dbHigh, dbLow;

// outputs	
wire enable;
reg [15:0] count;

baud_rate_generator test(.clk(clk),
			.rst(rst),
			.isReady(isReady),
			.dbHigh(dbHigh),
			.dbLow(dbLow),
			.enable(enable));

always @(posedge clk) begin
	if (rst) begin
		count <= 0;
	end else if (enable) begin
		$display("Enable Count: %d", count);
		count <= 0;
	end else begin
		count <= count + 1;
	end
end

initial begin
	rst = 1;
	clk = 0;
	isReady = 0;
	dbHigh = 0;
	dbLow = 0;
	
	// no enable should happen since not ready
	#2
	rst = 1;

	// count of 70
	#1298
	rst = 0;
	dbHigh = 8'h00;
	dbLow = 8'h46;
	isReady = 1;
	#500

	// if baud rate was 4800 at 100 MHz
	isReady = 1;
	dbHigh = 8'h05;
	dbLow = 8'h16;
	
	#10000
	$stop;
end

always #1 clk = ~clk;
endmodule
