`timescale 1ns / 1ps
module tb_db_registers();
// inputs
reg clk, rst, iocs, iorw;
reg [1:0] ioaddr;
reg [7:0] dataIn;

// outputs
wire [7:0] dbLow;
wire[7:0] dbHigh;
wire isReady;

// module
db_registers test( .clk(clk),
				.rst(rst),
				.iocs(iocs),
				.iorw(iorw),
				.ioaddr(ioaddr),
				.dataIn(dataIn),
				.dbLow(dbLow),
				.dbHigh(dbHigh),
				.isReady(isReady));

initial begin
	clk = 0;
	rst = 1;
	iocs = 0;
	iorw = 0;
	ioaddr = 2'b0;
	dataIn = 8'b0;
	
	// try standard solution as well as others that should not write to dbLow and dbHigh
	#10
	rst = 0;
	iocs = 1;
	iorw = 0;
	dataIn = 8'hAB;
	ioaddr = 2'b10;
	$display("High: %h, Low: %h, IsReady: %b", dbHigh, dbLow, isReady);
	#10
	iocs = 1;
	iorw = 0;
	dataIn = 8'hAB;
	ioaddr = 2'b11;
	$display("High: %h, Low: %h, IsReady: %b", dbHigh, dbLow, isReady);
	#10
	iocs = 1;
	iorw = 1;
	dataIn = 8'hBC;
	ioaddr = 2'b10;
	$display("High: %h, Low: %h, IsReady: %b", dbHigh, dbLow, isReady);
	#10
	iocs = 0;
	iorw = 0;
	dataIn = 8'hCD;
	ioaddr = 2'b11;
	$display("High: %h, Low: %h, IsReady: %b", dbHigh, dbLow, isReady);

	// try different solutions after reset
	#10
	rst = 1;
	#10
	rst = 0;
	iocs = 0;
	iorw = 0;
	dataIn = 8'hCD;
	ioaddr = 2'b11;
	$display("High: %h, Low: %h, IsReady: %b", dbHigh, dbLow, isReady);
	#10
	iocs = 1;
	iorw = 1;
	$display("High: %h, Low: %h, IsReady: %b", dbHigh, dbLow, isReady);
	#10
	iocs = 1;
	iorw = 0;
	dataIn = 8'h2F;
	ioaddr = 2'b10;
	$display("High: %h, Low: %h, IsReady: %b", dbHigh, dbLow, isReady);
	#10
	iocs = 1;
	iorw = 0;
	dataIn = 8'hA2;
	$display("High: %h, Low: %h, IsReady: %b", dbHigh, dbLow, isReady);

	$stop;
end

always #5 clk = !clk;
endmodule