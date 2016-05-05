`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    spart_tb 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//	The testbench incorporates all modules involved in the SPART as well as the
//	driver unit which echoes back data via TX line. The main purpose of this
//	test bench is to determine whether data is echoed back correctly at the
//	same rate it was received. By simulating an RX line driving data, the entire
//	SPART mechanism was kicked off.
//
//  For more robust testing the procedure can be repeated multiple times, but
//	it was found unneccesary in this case to simulate in ModelSim.
//
//	Finally the unit tests for setting the unique divisor values based on dip
//	switches. This is a fairly basic test case.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module spart_tb();

// Signals //
logic clk, rst;
logic rxd;
logic [1:0] br_cfg;

wire txd;
wire iocs;
wire iorw;
wire rda;
wire tbr;
wire [1:0] ioaddr;
wire [7:0] databus;

logic [7:0] tx_data;
logic [7:0] rx_data;
logic [10:0] rx_message; // {STOP, DATA, START, 1'b1} //

// DUT(s) //
spart spart0(	.clk(clk),
                .rst(rst),
				.iocs(iocs),
				.iorw(iorw),
				.rda(rda),
				.tbr(tbr),
				.ioaddr(ioaddr),
				.databus(databus),
				.txd(txd),
				.rxd(rxd)
				);

// Instantiate your driver here //
driver driver0( .clk(clk),
	            .rst(rst),
				.br_cfg(br_cfg),
				.iocs(iocs),
				.iorw(iorw),
				.rda(rda),
				.tbr(tbr),
				.ioaddr(ioaddr),
				.databus(databus)
				);
					 
// Clock //
initial begin
   forever
      #5 clk = ~clk;
end

// Feed the LSB to RX line //
assign rxd = rx_message[0];

// Testing //
initial begin
	// Defaults //
	clk = 0;
	rst = 1;
	br_cfg = 2'b01;
	tx_data = 8'h00;
	rx_data = 8'h99;
	rx_message = {1'b1, rx_data, 1'b0, 1'b1};
	// TEST //
	@(negedge clk) rst = 1;
	@(negedge clk) rst = 0;
	@(negedge clk);

	// Let the system IDLE for a couple cycles //
	repeat(10)begin
		wait(spart0.baudGn_en === 1);
		repeat(2) @(posedge clk);
	end

	// Simulate the RX line, everything else should fall in place //
	repeat(9)begin
		@(negedge clk)
		rx_message = rx_message >> 1;
		repeat(15)begin
			wait(spart0.baudGn_en === 1);
			repeat(2) @(posedge clk);	
		end
	end

	wait(spart0.rda === 1);

	// Read in TX data to check versus RX //
	// First bit is 1.5 bauds away //
	repeat(23)begin
		wait(spart0.baudGn_en === 1)
		repeat(2) @(posedge clk);
	end

	tx_data = {txd, tx_data[7:1]};	
	// remaining are evenly spaced
	repeat(7)begin
		repeat(15)begin
			wait(spart0.baudGn_en === 1)
			repeat(2) @(posedge clk);
		end
		
		tx_data = {txd, tx_data[7:1]};
	end

	wait(spart0.tbr === 1);
	
	// Compare //
	if(tx_data !== rx_data)begin
		$display("***ERROR*** The character sent was not echoed correctly!");
		$stop;
	end

	////////////////////////////////////////////////////////////////
	// You could repeat this process for a while - echo back data //
	////////////////////////////////////////////////////////////////

	// Test setting baud rate // How without FPGA?
	br_cfg = 2'b00;
	repeat(5)begin
		wait(spart0.baudGn_en === 1)
		repeat(2) @(posedge clk);
	end

	br_cfg = 2'b10;
	repeat(5)begin
		wait(spart0.baudGn_en === 1)
		repeat(2) @(posedge clk);
	end

	br_cfg = 2'b11;
	repeat(5)begin
		wait(spart0.baudGn_en === 1)
		repeat(2) @(posedge clk);
	end

	br_cfg = 2'b01;
	repeat(5)begin
		wait(spart0.baudGn_en === 1)
		repeat(2) @(posedge clk);
	end

	repeat(25) @(posedge clk);
	$display("Testing Finished!");
	$stop;
end

endmodule
