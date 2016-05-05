`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    top_level 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//	Top level hierarchy for project 1, in which the SPART along with the driver
//	module interact to echo back characters to the serial console. This is done
//	by hardwiring the driver to read a character each time it is received, and
//	placing it in the tx buffer as soon at tbr is asserted.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module spart_top_level(
	input clk,		 // clock
	input rst,		 // Synchronous reset, tied to dip switch 0
	output txd,		// RS232 Transmit Data
	input rxd,		 // RS232 Recieve Data
	input [1:0] br_cfg, // Baud Rate Configuration, Tied to dip switches 2 and 3

	// cpu interface
	output [12:0] bit_mask,
	output bit_mask_ready);
	
	wire iocs;
	wire iorw;
	wire rda;
	wire tbr;
	wire [1:0] ioaddr;
	wire [7:0] databus;
	
	// Instantiate your SPART here //
	spart spart0( 	.clk(clk),
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

	// interface with the cpu
	spart_cpu_interface spartcpu(.clk(clk),
					.rst(rst),
					.rda(rda),
					.databus(databus),
					.bit_mask(bit_mask),
					.bit_mask_ready(bit_mask_ready));

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
					 
endmodule

