`timescale 1ns / 1ps
module display_synthesis_test(
					// generic inputs
					input clk_input,
					input rst,

					// display specific outputs
					output hsync,
					output vsync,
					output blank,
					output [11:0] D,
					output dvi_rst,
					output clk_25mhz,
					output clk_25mhz_n,
					inout scl_tri,
					inout sda_tri);

// output clock to all other modules
wire clk_output;
wire fifo_full;

// rasterizer input
wire [2:0] frame_buffer_color_in;
assign frame_buffer_color_in = 3'b1;

// test fifo
wire frame_buffer_fifo_write_enable;
assign frame_buffer_fifo_write_enable = fifo_full != 1'b1;

display_top_level dtl(.clk_input(clk_input),
					.rst(rst),
					.hsync(hsync),
					.vsync(vsync),
					.blank(blank),
					.D(D),
					.dvi_rst(dvi_rst),
					.clk_25mhz(clk_25mhz),
					.clk_25mhz_n(clk_25mhz_n),
					.scl_tri(scl_tri),
					.sda_tri(sda_tri),
					.clk_output(clk_output),
					.frame_buffer_color_in(frame_buffer_color_in),
					.frame_buffer_fifo_write_enable(frame_buffer_fifo_write_enable),
					.fifo_full(fifo_full));

endmodule