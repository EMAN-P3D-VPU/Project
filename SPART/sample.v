`timescale 1ns / 1ps
module sample(
		input clk,
		input rst,
		input enable,
		input start_from_middle,
		output sample);

// need a special counter to count to 16 but only sample at 8
reg [3:0] counter;

// sample only is 1 when counter is at 8, 0 otherwise
assign sample = (counter == 4'b1000) ? 1'b1 : 1'b0;

always @(posedge clk) begin
	// reset to the 15 (as this counter goes from 15 -> 0)
	if(rst) begin
		counter <= 4'b1111;
	// reset counter to 9 so there is a full 16 counts until it hits 8 again
	end else if(start_from_middle) begin
		counter <= 4'b1001;
	// increment when seeing the enable asserted
	end else if(enable) begin
		counter <= counter + 1;
	end else begin
		counter <= counter;
	end
end

endmodule