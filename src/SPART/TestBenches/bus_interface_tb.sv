`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    bus_interface_tb 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//	The bus interface has to react to four unique states, however, only two of
//	which change any logic. For this case the DB_LOW and DB_HIGH states are not
//	really useful as they are handled in other units. For the sake of testing 
//	this testbench checks for unwarranted behavior in the interface as well as
//	the correct tristate behavior on the bus.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module bus_interface_tb();

// Signals //
logic clk, rst;
logic [7:0] rx_data;
logic [1:0] ioaddr;
logic iorw, tbr, rda;
logic [7:0] DATABUS;

wire clr_rda;
wire transmit;
wire [7:0] databus;
wire [7:0] tx_data;

localparam DATA		= 2'b00;
localparam STATUS	= 2'b01;
localparam DB_LOW	= 2'b10;
localparam DB_HIGH	= 2'b11;

// DUT(s) //
bus_interface busInt(.databus(databus),
					 .rx_data(rx_data),
					 .ioaddr(ioaddr),
					 .iorw(iorw),
					 .tbr(tbr),
					 .rda(rda),
					 .clr_rda(clr_rda),
					 .transmit(transmit),
					 .tx_data(tx_data));
// Clock //
initial begin
   forever
      #5 clk = ~clk;
end

assign databus = (iorw) ? 8'hZZ : DATABUS;

// Testing //
initial begin
	// Defaults //
	clk = 0;
	DATABUS = 8'h12;
	rst = 0;
	rx_data = 8'hBE;
	ioaddr = DATA;
	iorw = 0;
	rda = 1;
	tbr = 1;
	repeat(2) @(posedge clk);
	
	// TEST //
	// Check driving DATABUS when IORW = 0 //
	@(negedge clk)
	DATABUS = 8'h12;
	ioaddr = DATA;

	@(negedge clk)
	if(tx_data !== databus)begin
		$display("***ERROR*** The tx_data is not routed correctly");
		$stop;
	end

	repeat(2) @(posedge clk);
	@(negedge clk)
	DATABUS = 8'hAB;
	ioaddr = DB_LOW;

	@(negedge clk)
	if(tx_data !== databus)begin
		$display("***ERROR*** The tx_data is not routed correctly");
		$stop;
	end

	repeat(2) @(posedge clk);
	@(negedge clk)
	DATABUS = 8'hFA;
	ioaddr = DB_HIGH;

	@(negedge clk)
	if(tx_data !== databus)begin
		$display("***ERROR*** The tx_data is not routed correctly");
		$stop;
	end

	repeat(2) @(posedge clk);
	@(negedge clk)
	// Check receiving DATABUS when IORW = 1 //
	iorw = 1;
	rx_data = 8'hBE;
	ioaddr = DATA;

	@(negedge clk)
	if(rx_data !== databus)begin
		$display("***ERROR*** The rx_data is not routed correctly");
		$stop;
	end

	repeat(2) @(posedge clk);
	@(negedge clk)

	rx_data = 8'h68;

	@(negedge clk)
	if(rx_data !== databus)begin
		$display("***ERROR*** The rx_data is not routed correctly");
		$stop;
	end

	repeat(2) @(posedge clk);
	@(negedge clk)
	// Read back status bits //
	iorw = 1;
	ioaddr = STATUS;
	rx_data = 8'hFF;
	rda = 1;
	tbr = 1;

	@(negedge clk)
	if({6'h00, tbr, rda} !== databus)begin
		$display("***ERROR*** The status is not routed correctly");
		$stop;
	end

	repeat(2) @(posedge clk);
	@(negedge clk)
	rda = 0;
	tbr = 1;

	@(negedge clk)
	if({6'h00, tbr, rda} !== databus)begin
		$display("***ERROR*** The status is not routed correctly");
		$stop;
	end

	repeat(2) @(posedge clk);
	@(negedge clk)
	rda = 0;
	tbr = 0;

	@(negedge clk)
	if({6'h00, tbr, rda} !== databus)begin
		$display("***ERROR*** The status is not routed correctly");
		$stop;
	end

	repeat(10) @(posedge clk);
	$display("Testing Finished!");
	$stop;
end

endmodule
