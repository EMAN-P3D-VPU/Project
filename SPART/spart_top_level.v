`timescale 1ns / 1ps
module spart_top_level(
	input clk,		 // clock
	input rst,		 // Synchronous reset, tied to dip switch 0
	output txd,		// RS232 Transmit Data
	input rxd,		 // RS232 Recieve Data
	input [1:0] br_cfg, // Baud Rate Configuration, Tied to dip switches 2 and 3

	// cpu interface
	output [4:0] bit_mask,
	output bit_mask_ready);
	
	// chip select
	wire iocs;

	// 0 when processor writing to SPART, 1 when SPART writing to processor
	wire iorw;

	// indicates when SPART has a received byte ready to be ready to processor
	wire rda;

	// indicates SPART is ready to receive a byte that will then be transmitted
	// through txd
	wire tbr;

	// which address is being interfaced
	wire [1:0] ioaddr;

	// used to communicate between SPART and processor
	wire [7:0] databus;
	
	// Instantiate your SPART here
	spart spart0( .clk(clk),
					.rst(rst),
					.iocs(iocs),
					.iorw(iorw),
					.rda(rda),
					.tbr(tbr),
					.ioaddr(ioaddr),
					.databus(databus),
					.txd(txd),
					.rxd(rxd));

	// interface with the cpu
	spart_cpu_interface spartcpu(.clk(clk),
					.rst(rst),
					.rda(rda),
					.databus(databus),
					.bit_mask(bit_mask),
					.bit_mask_ready(bit_mask_ready));

	// Instantiate your driver here
	driver driver0( .clk(clk),
					.rst(rst),
					.br_cfg(br_cfg),
					.iocs(iocs),
					.iorw(iorw),
					.rda(rda),
					.tbr(tbr),
					.ioaddr(ioaddr),
					.databus(databus));
					 
endmodule