`timescale 1ns / 1ps
module frame_cell(
				// General Inputs
				input clk,

				// Writing
				input [9:0] write_frame_width,
				input [8:0] write_frame_height,
				input write_enable,
				input [2:0] write_data,

				// Reading
				// used to determine whether or not to input
				// something to the read address
				input read_enable,
				input [9:0] read_frame_width,
				input [8:0] read_frame_height,
				output [2:0] read_data);

// simple dual port RAM with a common clock
// write width - 3
// write detph - Only need, 307200 (640 x 480), use 2^19 (524288 -> just concatenate width and height)
// initialize everything to 0
frame_cell_block frame_mem(
			.addra({write_frame_width, write_frame_height}),
			.dina(write_data),
			.wea(write_enable),
			.clka(clk),
			.addrb(read_enable ? {read_frame_width, read_frame_height} : 19'bX),
			.clkb(clk),
			.doutb(read_data));

endmodule