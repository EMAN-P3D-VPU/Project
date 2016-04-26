`timescale 1ns / 1ps
module baud_rate_generator(
	input clk,
	input rst,
	input [7:0] dbLow,
	input [7:0] dbHigh,
	input isReady,
	output reg enable);

// will contain divisor that will be decremented
wire [15:0] divisor;

// temporary divisor until both low and high registers are initialized
wire [15:0] baud9600;
assign baud9600 = 16'h28A;

// insert both high and low divisor buffers into divisor
assign divisor[15:8] = dbHigh;
assign divisor[7:0] = dbLow;

reg [15:0] downCounter;

always @(posedge clk) begin
	// disable enable and set down counter to divisor
	if(rst) begin
		enable <= 1'b0;
		downCounter <= baud9600;
	end
	else begin
		// if it is one, set enable and set divisor back
		if (downCounter == 0) begin
			// only when the divisor is ready should it get loaded on
			if(isReady) begin
				enable <= 1'b1;
				downCounter <= divisor;
			end
			else begin
				enable <= 1'b0;
				downCounter <= baud9600;
			end 
		end
		// decrement every clock cycle and disable until reaching 0
		else begin
			downCounter <= downCounter - 1;
			enable <= 1'b0;
		end
	end
end
endmodule