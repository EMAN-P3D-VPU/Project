`timescale 1ns / 1ps
module bus_interface(
	input iocs,
	input iorw,
	input [1:0] ioaddr,
	input rda,
	input tbr,
	input [7:0] receive,
	inout [7:0] databus,
	output [7:0] dataIn);

wire [7:0] dataout;

// dataout will select the right to output
assign dataout = ioaddr == 2'b00 ? receive : 
		(ioaddr == 2'b01 ? {{6'b0}, tbr, rda} : 8'b0);

// set the data in to be from the databus
// also set high impedence if not sending to processor
assign dataIn = databus;
assign databus = (iocs && iorw) ? dataout : 8'bz;

endmodule