`timescale 1ns / 1ps
module spart_cpu_interface(
	input clk,
	input rst,

	// spart module
	input rda,
	input [7:0] databus,

	// cpu interface
	input cpu_read,
	output reg [4:0] bit_mask,
	output reg bit_mask_ready);

parameter w = 8'h77;
parameter a = 8'h61;
parameter s = 8'h73;
parameter d = 8'h64;
parameter j = 8'h6A;

// boolean wires determining when databus is wasdj
wire [4:0] databus_mask;

assign databus_mask[4] = databus == w;
assign databus_mask[3] = databus == a;
assign databus_mask[2] = databus == s;
assign databus_mask[1] = databus == d;
assign databus_mask[0] = databus == j;

// only a one when rda has a new signal
wire rda_edge;

// find the rising edge of rda to figure out
find_rising_edge rda_find_rising_edge(.clk(clk),
					.rst(rst),
					.enable(rda),
					.rising_edge(rda_edge));

// outputs a 1 when a key we care about is pressed
wire edge_and_key;
assign edge_and_key = rda_edge == 1'b1 && databus_mask != 5'b0;

// once rising edge of rda is found, set bit_mask
always @(posedge clk) begin
	if (rst) begin
		bit_mask <= 5'b0;
		bit_mask_ready <= 1'b0;
	// if cpu reads but there is a new key coming in 
	end else if (bit_mask_ready && cpu_read && edge_and_key) begin
		bit_mask <= databus_mask;
		bit_mask_ready <= 1'b1;
	// if cpu reads and no new key is coming in
	end else if (bit_mask_ready && cpu_read && !edge_and_key) begin
		bit_mask <= 5'b0;
		bit_mask_ready <= 1'b0;
	// when there is something already ready but new key comes in
	// cpu has not read yet
	end else if (bit_mask_ready && !cpu_read && edge_and_key) begin
		bit_mask <= bit_mask | databus_mask;
		bit_mask_ready <= bit_mask_ready;
	// when bit mask is not ready and a new key comes in
	end else if (!bit_mask_ready && edge_and_key) begin
		bit_mask <= databus_mask;
		bit_mask_ready <= 1'b1;
	// every other case
	end else begin
		bit_mask <= bit_mask;
		bit_mask_ready <= bit_mask_ready;
	end
end

endmodule;