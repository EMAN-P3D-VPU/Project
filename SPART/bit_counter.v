`timescale 1ns / 1ps
module bit_counter(
			input clk,
			input rst,
			input sample,
			input start,
			output reg [3:0] bits); // bits represents how many bits have been found already

always @(posedge clk) begin
	if (start || rst) begin
		bits <= 4'b0001;
	// add 1 to the counter if sample is asserted
	end else if (sample) begin
		bits <= bits + 1;
	end else begin
		bits <= bits;
	end
end

endmodule