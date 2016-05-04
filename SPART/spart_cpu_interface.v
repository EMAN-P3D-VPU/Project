`timescale 1ns / 1ps
module spart_cpu_interface(
	input clk,
	input rst,

	// spart module
	input rda,
	input [7:0] databus,

	// cpu interface
	output [12:0] bit_mask,
	output reg bit_mask_ready);

// get both upper case and lower case characters
parameter w = 8'h77;
parameter a = 8'h61;
parameter s = 8'h73;
parameter d = 8'h64;
parameter y = 8'h79;
parameter u = 8'h75;
parameter i = 8'h69;
parameter o = 8'h6F;
parameter h = 8'h68;
parameter j = 8'h6A;
parameter k = 8'h6B;
parameter l = 8'h6C;
parameter sp = 8'h20;

// boolean wires determining when databus is wasdj
assign bit_mask[12] = (databus == sp);
assign bit_mask[11] = (databus == l);
assign bit_mask[10] = (databus == k);
assign bit_mask[9] = (databus == j);
assign bit_mask[8] = (databus == h);
assign bit_mask[7] = (databus == o);
assign bit_mask[6] = (databus == i);
assign bit_mask[5] = (databus == u);
assign bit_mask[4] = (databus == y);
assign bit_mask[3] = (databus == d);
assign bit_mask[2] = (databus == s);
assign bit_mask[1] = (databus == a);
assign bit_mask[0] = (databus == w);

// only a one when rda has a new signal
wire rda_edge;

// find the rising edge of rda to figure out
find_rising_edge rda_find_rising_edge(.clk(clk),
					.rst(rst),
					.enable(rda),
					.rising_edge(rda_edge));

// outputs a 1 when a key we care about is pressed (delay for 1 clock cycle)
always @(posedge clk) begin
	bit_mask_ready <= rda_edge;
end

endmodule
