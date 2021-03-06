`timescale 1ns / 1ps
module display_top_level(
					// generic inputs
					input clk,
					input rst,

					// clock gen inputs 
					input clk_25mhz,
					input locked_dcm,

					// display specific outputs
					output hsync,
					output vsync,
					output blank,
					output [11:0] D,
					output dvi_rst,
					inout scl_tri,
					inout sda_tri,

					// rasterizer input
					input [2:0] frame_buffer_color_in,
					input frame_buffer_fifo_write_enable,

					// rasterizer output
					output fifo_full);

wire comp_sync;
wire sda, scl;

// pixel location (x is horizontal, y is vertical)
wire [9:0] pixel_x;
wire [9:0] pixel_y;

// FIFO outputs (data, full and empty signals)
wire fifo_empty;
wire [2:0] fifo_color_out;

// color palette output
wire [23:0] color_translated;

// outputs of time generator
wire stall;
wire fifo_read_enable;

// colors
wire [7:0] pixel_r;
wire [7:0] pixel_g;
wire [7:0] pixel_b;

assign dvi_rst = ~(rst|~locked_dcm);
assign D = (clk_25mhz)? {pixel_g[3:0], pixel_b} : {pixel_r, pixel_g[7:4]};
assign sda_tri = (sda)? 1'bz: 1'b0;
assign scl_tri = (scl)? 1'bz: 1'b0;

dvi_ifc u_dvi(  .Clk           (clk_25mhz),
                .Reset_n       (dvi_rst),
                .SDA           (sda),
                .SCL           (scl),
                .Done          (),
                .IIC_xfer_done (),
                .init_IIC_xfer (1'b0)
            );

// FIFO, data written in from 100 Mhz side and read from 25 Mhz side 
fifo_xclk fifo (
		.rst(rst),
		.wr_clk(clk),
		.din(frame_buffer_color_in),
		.wr_en(frame_buffer_fifo_write_enable),
		.full(fifo_full),
		.rd_clk(clk_25mhz),
		.dout(fifo_color_out),
		.rd_en(fifo_read_enable),
		.empty(fifo_empty));

// translate the color code using the color palette module
color_palette c_palette(
		.color_code(fifo_color_out),
		.color_translated(color_translated));

// Timing Generator Logic
logic_time_wrapper time_wrapper(
		.empty(fifo_empty),
		.fifo_color(color_translated),
		.blank(blank),
		.pixel_r(pixel_r),
		.pixel_g(pixel_g),
		.pixel_b(pixel_b),
		.read_en(fifo_read_enable),
		.stall(stall));

// Determines at which pixel location one is at (Timing Generator)
vga_logic vgal1(
		.clk(clk_25mhz),
		.rst(rst|~locked_dcm),
		.stall(stall),
		.blank(blank),
		.comp_sync(comp_sync),
		.hsync(hsync),
		.vsync(vsync),
		.pixel_x(pixel_x),
		.pixel_y(pixel_y));

endmodule
