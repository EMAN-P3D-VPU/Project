`timescale 1ns / 1ps
module find_rising_edge(
				input clk,
				input rst,
				input enable,
				output rising_edge);

// stores the previous enable value
reg previous_enable;

// store the current enable into register on posedge
always @(posedge clk) begin
	if (rst) begin
		previous_enable <= 1'b0;
	end else begin
		previous_enable <= enable;
	end
end

// only is asserted when there is a rising edge
assign rising_edge = ((~previous_enable) & (enable));

endmodule