`timescale 1ns / 1ps
module dvi_framebuffer_top_level(
	// generic
	input clk_input,
	input rst,

	// clipping unit input
	input next_frame_switch,

	// rasterizer inputs
	input rast_pixel_rdy,
	input [2:0] rast_color_input,
	input [9:0] rast_width,
	input [8:0] rast_height,
	input rast_done,

	// rasterizer outputs
	output read_rast_pixel_rdy,

	// display outputs
	output hsync,
	output vsync,
	output blank,
	output [11:0] D,
	output dvi_rst,
	output clk_25mhz,
	output clk_25mhz_n,
	inout scl_tri,
	inout sda_tri,

	// clock output 
	output clk_output);

// frame buffer outputs
wire [2:0] dvi_color_out;
wire dvi_fifo_write_enable;

// display outputs
wire dvi_fifo_full;

// not reset
wire rst_n;

assign rst_n = ~rst;

frame_buffer fb(.clk(clk_output),
			.rst_n(rst_n),
			.dvi_fifo_full(dvi_fifo_full),
			.dvi_color_out(dvi_color_out),
			dvi_fifo_write_enable(dvi_fifo_write_enable),
			rast_pixel_rdy(rast_pixel_rdy),
			rast_color_input(rast_color_input),
			rast_width(rast_width),
			rast_height(rast_height),
			rast_done(rast_done),
			read_rast_pixel_rdy(read_rast_pixel_rdy),
			next_frame_switch(next_frame_switch));

display_top_level display(.clk_input(clk_input),
			.rst(rst),
			.hsync(hysnc),
			.vsync(vsync),
			.blank(blank),
			.D(D),
			.dvi_rst(dvi_rst),
			.clk_25mhz(clk_25mhz),
			.clk_25mhz_n(clk_25mhz_n),
			.scl_tri(scl_tri),
			.sda_tri(sda_tri),
			.clk_output(clk_output),
			.frame_buffer_color_in(dvi_color_out),
			.frame_buffer_fifo_write_enable(dvi_fifo_write_enable),
			.fifo_full(dvi_fifo_full));

endmodule