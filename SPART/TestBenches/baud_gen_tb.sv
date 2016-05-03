`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    baud_gen 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//	The baud divisor needs to be set based on the ioaddr, and kept the same
//	in the remaining states. Although this was not a complicated unit it
//	warranted basic testing in setting the divisor value.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module baud_gen_tb();

// Signals //
logic clk, rst;
logic [7:0] divisor;
logic [1:0] ioaddr;

wire en;

// DUT(s) //
// Baud Rate Generator //
baud_gen baudGn(.clk(clk),
				.rst(rst),
				.divisor(divisor),
				.ioaddr(ioaddr),
				.en(en));

// Clock //
initial begin
   forever
      #5 clk = ~clk;
end

// Testing //
initial begin
	// Defaults //
	clk = 0;
	divisor = 8'hFF;
	ioaddr = 2'h0;
	
	// TEST //

	@(negedge clk) rst = 1;
	ioaddr = 2'h0;
	repeat(2) @(posedge clk);
	@(negedge clk) rst = 0;
	
	// @ioaddr == 00 divisor should be default
	repeat(2) @(posedge clk);
	wait(en == 1);

	@(negedge clk) rst = 1;
	ioaddr = 2'h1;
	repeat(2) @(posedge clk);
	@(negedge clk) rst = 0;

	// @ioaddr == 01 divisor should be default
	repeat(2) @(posedge clk);
	wait(en == 1);

	// Load Lower 8-bits
	@(negedge clk);
	ioaddr = 2'h2;
	divisor = 8'hAB;
	@(negedge clk)

	if(divisor !== baudGn.divisor_buf[7:0])begin
		$display("***ERROR*** The divisor failed to load for lower 8 bits");
		$stop;
	end

	// Load Lower 8-bits
	@(negedge clk);
	ioaddr = 2'h3;
	divisor = 8'h54;
	@(negedge clk)

	if(divisor !== baudGn.divisor_buf[15:8])begin
		$display("***ERROR*** The divisor failed to load for upper 8 bits");
		$stop;
	end

	ioaddr = 2'h0;
	repeat(2) @(posedge clk);
	wait(en == 1);

	repeat(10) @(posedge clk);
	$display("Testing Finished!");
	$stop;
end

endmodule
