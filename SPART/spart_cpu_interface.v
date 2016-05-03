`timescale 1ns / 1ps
module spart_cpu_interface(
	input clk,
	input rst,

	// spart module
	input rda,
	input [7:0] databus,

	// cpu interface
	output [4:0] bit_mask,
	output bit_mask_ready);

// get both upper case and lower case characters
parameter w = 8'h77;
parameter W = 8'h57;
parameter a = 8'h61;
parameter A = 8'h41;
parameter s = 8'h73;
parameter S = 8'h53;
parameter d = 8'h64;
parameter D = 8'h44;
parameter j = 8'h6A;
parameter J = 8'h4A;

// boolean wires determining when databus is wasdj
assign bit_mask[4] = (databus == w) | (databus == W);
assign bit_mask[3] = (databus == a) | (databus == A);
assign bit_mask[2] = (databus == s) | (databus == S);
assign bit_mask[1] = (databus == d) | (databus == D);
assign bit_mask[0] = (databus == j) | (databus == J);

// only a one when rda has a new signal
wire rda_edge;

// find the rising edge of rda to figure out
find_rising_edge rda_find_rising_edge(.clk(clk),
					.rst(rst),
					.enable(rda),
					.rising_edge(rda_edge));

// outputs a 1 when a key we care about is pressed
assign bit_mask_ready = rda_edge & (bit_mask != 5'b0);

endmodule
