`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    rx_unit_tb 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//	In order to test the RX unit, this testbench incorporated the baud generator.
//	The TX line was simulated by shifting at the middle of each sampling rate
//  which on average should be the behavior of the SPART on both end of the
//  RS232 line. With a simple shift operation it appears to work just as the
//	hardware would in a real situation.
//
//	This procedure can be repeated several times, but again there is no reason
//	to beat a dead horse.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module rx_unit_tb();

// Signals //
logic clk, rst;
logic rx_en;
logic iocs;
logic rxd;
logic clr_rda;
logic [1:0] ioaddr;
logic [7:0] divisor;
logic [9:0] message;

wire [7:0] rx_data;
wire rda;
wire en;

localparam DATA		= 2'b00;
localparam STATUS	= 2'b01;
localparam DB_LOW	= 2'b10;
localparam DB_HIGH	= 2'b11;

// DUT(s) //
rx_unit rxUnit(.clk(clk),
			   .rst(rst),
			   .rx_en(en),
			   .iocs(iocs),
			   .rxd(rxd),
			   .clr_rda(clr_rda),
			   .rx_data(rx_data),
			   .rda(rda));

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
	rst = 1;
	ioaddr = DATA;
	clr_rda = 0;
	rx_en = 0;
	iocs = 1;
	rxd = 1;
	divisor = 8'h33; // doesn't matter for this tb

	// Test //
	@(negedge clk) rst = 1;
	@(negedge clk) rst = 0;
	@(negedge clk);

	// Note IDLE behavior - everything should be 0's pretty much
	repeat(3) begin
		wait(en === 1);
		repeat(2) @(posedge clk);
	end

	// Example transmission //
	repeat(10) begin
		@(negedge clk) rxd = ~rxd; //just alternate 0's and 1's

		repeat(15) begin
			wait(en === 1)
			repeat(2) @(posedge clk);
		end
	end

	wait(rda);
	if(rx_data !== 8'h55)begin
		$display("***ERROR*** RX transmission was not correct: %h expected 0x55", rx_data);
		$stop;
	end

	// Varify Dropped Packet //
	// rx_buffer should not change at the end but the RX protocol should execute //
	// Example transmission //
	message = 10'b1_1100_1111_0; // xCF

	repeat(10) begin
		@(negedge clk) rxd = message[0];

		repeat(15) begin
			wait(en === 1)
			repeat(2) @(posedge clk);
		end

		// simulate Rx line //
		message = message >> 1;
	end

	wait(rda);
	if(rx_data !== 8'h55)begin
		$display("***ERROR*** RX transmission was not correct: %h expected 0x55", rx_data);
		$stop;
	end

	// Verify Packet after clearing rda //
	@(negedge clk) clr_rda = 1;
	message = 10'b1_1100_1111_0; // xCF
	@(negedge clk) clr_rda = 0;

	repeat(10) begin
		@(negedge clk) rxd = message[0];

		repeat(15) begin
			wait(en === 1)
			repeat(2) @(posedge clk);
		end

		// simulate Rx line //
		message = message >> 1;
	end

	wait(rda);
	if(rx_data !== 8'hCF)begin
		$display("***ERROR*** RX transmission was not correct: %h expected 0xCF", rx_data);
		$stop;
	end


	repeat(25) @(posedge clk);
	$display("Testing Finished!");
	$stop;
end

endmodule
