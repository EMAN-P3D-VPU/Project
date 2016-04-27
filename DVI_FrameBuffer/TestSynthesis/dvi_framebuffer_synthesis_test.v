`timescale 1ns / 1ps
module dvi_framebuffer_synthesis_test(
	// generic
	input clk_input,
	input rst,

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
reg next_frame_switch;

// rasterizer inputs
reg rast_pixel_rdy;
reg [2:0] rast_color_input;
reg [9:0] rast_width;
reg [8:0] rast_height;
reg rast_done;

// rasterizer outputs
wire read_rast_pixel_rdy;

// clock output
wire clk_100mhz;

// dvi framebuffer top level
dvi_framebuffer_top_level(
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