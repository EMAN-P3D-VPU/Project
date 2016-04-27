`timescale 1ns / 1ps
module frame_buffer(
				// General Inputs
				input clk,
				input rst_n,

				// DVI Inputs
				input dvi_fifo_full,

				// DVI Outputs
				output [2:0] dvi_color_out,
				output dvi_fifo_write_enable,

				// Rasterizer Inputs
				input rast_pixel_rdy,
				input [2:0] rast_color_input,
				input [9:0] rast_width,
				input [8:0] rast_height,
				input rast_done,

				// Rasterizer Outputs
				output read_rast_pixel_rdy,

				// Clipping Unit Input
				input next_frame_switch);


// mode determines which frame cell is being written into and read from
reg mode;
reg next_mode;

// address needed to determine which pixel is being read out into the DVI module
reg [9:0] dvi_width;
reg [8:0] dvi_height;

// check if the rasterizer is indicating it is for the other frame
// that is currently in read mode
assign read_rast_pixel_rdy = mode == next_mode; 

// last pixel to write
wire last_pixel;
assign last_pixel = (dvi_width == 10'd639 && dvi_height == 9'd479);

// wires to read and write enable for frame_cell
wire frame0_write_enable;
wire [2:0] frame0_read_data;
assign frame0_write_enable = mode == 1'b0 && rast_pixel_rdy && read_rast_pixel_rdy;

wire frame1_write_enable;
wire [2:0] frame1_read_data;
assign frame1_write_enable = mode == 1'b1 && rast_pixel_rdy && read_rast_pixel_rdy;

// dvi color output is determined by which frame cell is currently being read
assign dvi_color_out = mode == 1'b1 ? frame0_read_data : frame1_read_data;
assign dvi_fifo_write_enable = !dvi_fifo_full;

// mode is determined by switching modes
always @(posedge clk) begin
	if (!rst_n) begin
		mode <= 1'b0;
	end else if((next_mode != mode) && last_pixel) begin
		mode <= next_mode;
	end else if (next_frame_switch && rast_done && last_pixel) begin
		mode <= mode == 1'b0 ? 1'b1 : 1'b0;
	end else begin
		mode <= mode;
	end
end

// next mode - needed because next frame switch can happen before the frame is done outputting to dvi fifo
always @(posedge clk) begin
	if (!rst_n) begin
		next_mode <= 1'b0;
	// should only happen once before switching to the next frmae
	end else if (next_frame_switch && rast_done) begin
		next_mode <= mode == 1'b0 ? 1'b1 : 1'b0;
	// repeat last frame since rasterizer is not done drawing
	end else if (next_frame_switch && !rast_done) begin
		next_mode <= mode;
	end else begin
		next_mode <= next_mode;
	end
end

// figure out what the read address should be
// width
always @(posedge clk) begin
	if (!rst_n) begin
		dvi_width <= 10'd0;
	end else if (dvi_fifo_full) begin
		dvi_width <= dvi_width;
	end else if (dvi_width == 10'd639) begin
		dvi_width <= 10'd0;
	end else begin
		dvi_width <= dvi_width + 10'd1;
	end
end

// height
always @(posedge clk) begin
	if (!rst_n) begin
		dvi_height <= 9'd0;
	end else if (dvi_fifo_full) begin
		dvi_height <= dvi_height;
	end else if (dvi_height == 9'd479 && dvi_width == 10'd639) begin
		dvi_height <= 9'd0;
	end else if (dvi_width == 10'd639) begin
		dvi_height <= dvi_height + 9'd1;
	end else begin
		dvi_height <= dvi_height;
	end
end

// frame modules
frame_cell frame0(
		.clk(clk),
		.write_frame_width(rast_width),
		.write_frame_height(rast_height),
		.write_enable(frame0_write_enable),
		.write_data(rast_color_input),
		.read_frame_width(dvi_width),
		.read_frame_height(dvi_height),
		.read_data(frame0_read_data));

frame_cell frame1(
		.clk(clk),
		.write_frame_width(rast_width),
		.write_frame_height(rast_height),
		.write_enable(frame1_write_enable),
		.write_data(rast_color_input),
		.read_frame_width(dvi_width),
		.read_frame_height(dvi_height),
		.read_data(frame1_read_data));

endmodule