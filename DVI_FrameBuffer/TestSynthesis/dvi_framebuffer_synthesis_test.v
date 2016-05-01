`timescale 1ns / 1ps
module dvi_framebuffer_synthesis_test(
	// generic
	input clk_input,
	input rst,

	//fake inputs from raster
	input fake_fifo_empty,
	
	input fake_EoO,
	input fake_object_change,


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

// frame buffer inputs
wire [2:0] rast_color_input;
wire [9:0] rast_width;
wire [8:0] rast_height;
wire rast_done;
wire rast_pixel_rdy;

// frame buffer outputs
wire read_rast_pixel_rdy;

// clock output
wire clk_100mhz;

// fifo_rd_en doesn't actually read from a fifo
wire useless;

// clipping unit input
reg next_frame_switch;
reg [20:0] counter;

// next frame switch test
always @(posedge clk_100mhz) begin
	if(rst) begin
		next_frame_switch <= 1'b0;
		counter <= 20'b0;
	end else if (counter == 20'd1666667) begin
		next_frame_switch <= 1'b1;
		counter <= 20'b0;
	end else begin
		next_frame_switch <= 1'b0;
		counter <= counter + 20'b1;
	end
end

wire [68:0] constant_data;
assign constant_data = {10'd0, 10'd0, 10'd500, 10'd200, 11'd200, 11'd500, 3'b000, 1'b1, 3'b000};
LINE_GENERATOR line_gen(/*global inputs*/      .clk(clk_100mhz), .rst(~rst),
	              /*raster inputs*/      .fifo_data(constant_data), .fifo_empty(fake_fifo_empty),
	              /*raster self-out*/    .fifo_rd_en(useless),
				  /*input from clipper*/ .end_of_objects(fake_EoO), .frame_start(next_frame_switch), 
				  /*input from object*/  .obj_change(fake_object_change),
				  /*input from matrix*/  .bk_color(3'b001),
				  /*input from f_buff*/  .frame_ready(read_rast_pixel_rdy),
				  /*output to f_buff*/   .raster_done(rast_done), .frame_rd_en(rast_pixel_rdy), .frame_x(rast_width), .frame_y(rast_height), .px_color(rast_color_input));


/*
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
			*/

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