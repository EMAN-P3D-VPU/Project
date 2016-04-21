`timescale 1ns / 1ps
module tb_frame_buffer();

// test bench for frame_buffer

//inputs
reg clk;
reg rst_n;

//DVI
reg dvi_fifo_full;

//Rasterizer
reg rast_pixel_rdy;
reg [2:0] rast_color_input;
reg [9:0] rast_width;
reg [8:0] rast_height;
reg rast_done;

//Clipping
reg next_frame_switch;

//outputs
wire [2:0] dvi_color_out;
wire dvi_fifo_write_enable;
wire read_rast_pixel_rdy;

frame_buffer tb_frame_buffer(
				.clk(clk),
				.rst_n(rst_n),
				.dvi_fifo_full(dvi_fifo_full),
				.dvi_color_out(dvi_color_out),
				.dvi_fifo_write_enable(dvi_fifo_write_enable),
				.rast_pixel_rdy(rast_pixel_rdy),
				.rast_color_input(rast_color_input),
				.rast_width(rast_width),
				.rast_height(rast_height),
				.rast_done(rast_done),
				.read_rast_pixel_rdy(read_rast_pixel_rdy),
				.next_frame_switch(next_frame_switch));

integer width_counter;
integer height_counter;

initial begin
	clk = 1'b0;
	rst_n = 1'b0;
	
	// DVI
	dvi_fifo_full = 1'b0;

	// Rasterizer
	rast_pixel_rdy = 1'b1;
	rast_color_input 3'b0;
	rast_width = 10'b0;
	rast_height = 9'b0;
	rast_done = 1'b0;

	// Clipping
	next_frame_switch = 1'b0;

	
end


always
	#5 clk = ~clk;

endmodule