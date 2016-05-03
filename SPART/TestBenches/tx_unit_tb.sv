`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    tx_unit_tb 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//	In order to suffienctly test the tx_unit we had to simulate an rx line
//	on the other end by shifting in the current value of the TX at 16x the
//	sampling rate. Since modelsim does not really have notion of skewed clocks
//  there was no point in really simulating at different baud rates. Instead,
//	the sampling rate was used as the true indicator of timing.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module tx_unit_tb();

// Signals //
logic clk, rst;
logic [7:0] tx_data;
logic [1:0] ioaddr;
logic transmit;
logic [7:0] divisor;
logic [9:0] message;

wire tbr;
wire txd;

localparam DATA		= 2'b00;
localparam STATUS	= 2'b01;
localparam DB_LOW	= 2'b10;
localparam DB_HIGH	= 2'b11;

// DUT(s) //
tx_unit txUnit(.clk(clk),
			   .rst(rst),
			   .tx_data(tx_data),
			   .tx_en(en),
			   .transmit(transmit),
			   .tbr(tbr),
			   .txd(txd));

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
	transmit = 0;
	divisor = 8'h33; // doesn't matter for this tb
	tx_data = 8'h84;

	// Test //
	@(negedge clk) rst = 1;
	@(negedge clk) rst = 0;
	@(negedge clk);

	// Note IDLE behavior - Tx should just sit on a single value
	repeat(3) begin
		wait(en === 1);
		repeat(2) @(posedge clk);
		if(txd !== 1)begin
			$display("***ERROR*** TX line is not correct in IDLE state!");
			$stop;
		end
	end

	// Send transmission //
	@(negedge clk) transmit = 1;
	tx_data = 8'hEF;
	message = {1'b1, tx_data, 1'b0};
	@(negedge clk) transmit = 0;

	repeat(9)begin
		repeat(7)begin
			wait(en == 1);
			repeat(2) @(posedge clk);
		end

		if(message[0] !== txd)begin
			$display("***ERROR*** TX line does not match expected value!");
			$stop;
		end
		// Wait til next bit //
		wait(txUnit.shift === 1);
		@(posedge clk)
		message = message >> 1;
	end

	wait(tbr == 1);

	repeat(25) @(posedge clk);
	$display("Testing Finished!");
	$stop;
end

endmodule
