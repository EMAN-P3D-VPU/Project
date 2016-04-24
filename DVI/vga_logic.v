`timescale 1ns / 1ps
module vga_logic(clk, rst, stall, blank, comp_sync, hsync, vsync, pixel_x, pixel_y);
input clk;
input rst;
input stall;
output blank;
output comp_sync;
output hsync;
output vsync;
output [9:0] pixel_x;
output [9:0] pixel_y;
 
reg [9:0] pixel_x;
reg [9:0] pixel_y;

// pixel_count logic
wire [9:0] next_pixel_x;
wire [9:0] next_pixel_y;
assign next_pixel_x = (pixel_x == 10'd799) ? 0 : pixel_x+1;
assign next_pixel_y = (pixel_x == 10'd799) ? 
 								((pixel_y == 10'd520) ? 0 : pixel_y+1)
									: pixel_y;
 
always@(posedge clk, posedge rst) begin
	if(rst) begin
		pixel_x <= 10'h0;
		pixel_y <= 10'h0;
	// Need to stall if there is no pixel available yet
	end else if(stall) begin
		pixel_x <= pixel_x;
		pixel_y <= pixel_y;
	end else begin
		pixel_x <= next_pixel_x;
		pixel_y <= next_pixel_y;
	end
end
	
assign hsync = (pixel_x < 10'd656) || (pixel_x > 10'd751); // 96 cycle pulse
assign vsync = (pixel_y < 10'd490) || (pixel_y > 10'd491); // 2 cycle pulse
assign blank = ~((pixel_x > 10'd639) | (pixel_y > 10'd479));
assign comp_sync = 1'b0; // don't know, dont use
	 
endmodule