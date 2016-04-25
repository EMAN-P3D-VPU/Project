`timescale 1ns / 1ps
module spart(
	input clk,
	input rst,
	input iocs,
	input iorw,
	output rda,
	output tbr,
	input [1:0] ioaddr,
	inout [7:0] databus,
	output txd,
	input rxd);

wire [7:0] dataIn;

// baud rate generator variables
wire [7:0] dbLow;
wire [7:0] dbHigh;
wire isReady;
wire enable;

// receive buffer
wire [7:0] receiveBuff;

bus_interface busInt(.iocs(iocs),
					.iorw(iorw),
					.ioaddr(ioaddr),
					.rda(rda),
					.tbr(tbr),
					.receive(receiveBuff),
					.databus(databus),
					.dataIn(dataIn));

// baud rate calculation
// make sure to load the low buffer first then the high buffer
db_registers dbReg(.clk(clk),
					.rst(rst),
					.iocs(iocs),
					.iorw(iorw),
					.ioaddr(ioaddr),
					.dataIn(dataIn),
					.dbLow(dbLow),
					.dbHigh(dbHigh),
					.isReady(isReady));

baud_rate_generator baudRate(.clk(clk),
							.rst(rst),
							.dbLow(dbLow),
							.dbHigh(dbHigh),
							.isReady(isReady),
							.enable(enable));

// rx module - receive from the UART port
uart_rx rx(.receive_buffer(receiveBuff),
		.rxd(rxd),
		.rda(rda),
		.clk(clk),
		.rx_en(enable),
		.rst(rst),
		.iocs(iocs),
		.iorw(iorw),
		.ioaddr(ioaddr));

// tx module - send to UART port
uart_tx tx(.transmit_buffer(dataIn),
		.txd(txd),
		.tbr(tbr),
		.clk(clk),
		.tx_en(enable),
		.rst(rst),
		.iocs(iocs),
		.iorw(iorw),
		.ioaddr(ioaddr));

endmodule
