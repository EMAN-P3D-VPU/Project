`timescale 1ns / 1ps
module dvi_framebuffer_synthesis_test(
	// generic
	input clk_input,
	input rst,
	input dont_change,
	input rast_pixel_rdy,

	// display outputs
	output hsync,
	output vsync,
	output blank,
	output [11:0] D,
	output dvi_rst,
	output clk_25mhz,
	output clk_25mhz_n,
	inout scl_tri,
	inout sda_tri);

// clipping unit input
wire next_frame_switch;

// rasterizer inputs
wire [2:0] rast_color_input;
wire [9:0] rast_width;
wire [8:0] rast_height;
wire rast_done;

// rasterizer outputs
wire read_rast_pixel_rdy;

// clock output
wire clk_100mhz;

// fake rasterizer
fake_rasterizer fr(.clk(clk_100mhz),
			.rst(rst),
			.dont_change(dont_change),
			.read_rast_pixel_rdy(read_rast_pixel_rdy),
			.next_frame_switch(next_frame_switch),
			.rast_color_input(rast_color_input),
			.rast_width(rast_width),
			.rast_height(rast_height),
			.rast_done(rast_done));

// dvi framebuffer top level
dvi_framebuffer_top_level dfb_tl(
		.clk_input(clk_input),
		.rst(rst),
		.next_frame_switch(next_frame_switch),
		.rast_pixel_rdy(rast_pixel_rdy),
		.rast_color_input(rast_color_input),
		.rast_width(rast_width),
		.rast_height(rast_height),
		.rast_done(rast_done),
		.read_rast_pixel_rdy(read_rast_pixel_rdy),
		.hsync(hsync),
		.vsync(vsync),
		.blank(blank),
		.D(D),
		.dvi_rst(dvi_rst),
		.clk_25mhz(clk_25mhz),
		.clk_25mhz_n(clk_25mhz_n),
		.scl_tri(scl_tri),
		.sda_tri(sda_tri),
		.clk_output(clk_100mhz));

endmodule