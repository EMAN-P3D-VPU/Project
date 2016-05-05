`timescale 1ns / 1ps
module display_plane(
			input clk,
			input rst,
			input fifo_full,
			output [12:0] addr,
			output write_enable);

// this will count what x value we are at
reg [12:0] counter_x;

// counts how many times x has repeated already
reg [2:0] repeated_x;

// counts what y position we are at
reg [12:0] counter_y;

// base address needs 
reg [12:0] base_addr;

// neede for when it is right after rst
reg after_reset;

assign addr = counter_x + base_addr;

assign write_enable = (fifo_full || after_reset) ? 1'b0 : 1'b1;

// write enable logic
always @(posedge clk) begin
	if (rst) begin
		after_reset <= 1;
	end else begin
		after_reset <= 0;
	end
end

// x position logic
always @(posedge clk) begin
	if (rst) begin
		counter_x <= 0;
		repeated_x <= 0;
	end else if (fifo_full) begin
		counter_x <= counter_x;
		repeated_x <= repeated_x;
	// see if at the end of the row
	end else if (counter_x == 13'd79) begin
		counter_x <= 0;
		repeated_x <= repeated_x + 1;
	end else begin
		counter_x <= counter_x + 1;
		repeated_x <= repeated_x;
	end
end

// y position logic
always @(posedge clk) begin
	if (rst) begin
		counter_y <= 0;
		base_addr <= 0;
	end else if (fifo_full) begin
		counter_y <= counter_y;
		base_addr <= base_addr;
	// add another one to repeated y once x has reached the end of the complete image
	end else if (counter_x == 13'd79 && repeated_x == 3'd7 && counter_y == 13'd59) begin
		counter_y <= 0;
		base_addr <= 0;
	// next check if it just has completed a row
	end else if (counter_x == 13'd79 && repeated_x == 3'd7) begin
		counter_y <= counter_y + 1;
		base_addr <= base_addr + 13'd80;
	// keep the same vertically if counter_x is not at the end
	end else begin
		counter_y <= counter_y;
		base_addr <= base_addr;
	end
end

endmodule