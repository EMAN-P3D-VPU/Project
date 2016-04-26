`timescale 1ns / 1ps
module db_registers(
	input clk,
	input rst,
	input iocs,
	input iorw,
	input [1:0] ioaddr,
	input [7:0] dataIn,
	output reg [7:0] dbLow,
	output reg [7:0] dbHigh,
	output reg isReady);

// it will be ready once high buffer has been loaded in
always @(posedge clk) begin
	if(rst) begin
		dbLow <= 8'b0;
		dbHigh <= 8'b0;
		isReady <= 1'b0;
	end else begin
		// store dbLow
		if(iocs && ~iorw && ioaddr == 2'b10) begin
			isReady <= isReady;
			dbLow <= dataIn;
			dbHigh <= dbHigh;
		// store dbHigh (and assert isReady as both have now been loaded)
		end else if (iocs && ~iorw && ioaddr == 2'b11) begin
			isReady <= 1'b1;
			dbLow <= dbLow;
			dbHigh <= dataIn;
		end else begin
			dbHigh <= dbHigh;
			dbLow <= dbLow;
			isReady <= isReady;
		end
	end
end

endmodule