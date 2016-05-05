`timescale 1ns / 1ps
module logic_time_wrapper(empty, fifo_color, pixel_r, pixel_g, pixel_b, read_en, stall, blank);
input empty; //The signal comming from the FIFO, meaning FIFO is empty if high
input [23:0] fifo_color; //The color signal reading from the ROM through the FIFO
input blank; //if blank is 0, meaning the color grabbed from FIFO is out of boundry

output [7:0] pixel_r; 
output [7:0] pixel_g;
output [7:0] pixel_b;
//stall is 1 when reading from FIFO should be stopped; 
//In the meantime, read_en should be 0 to disable the reading
output stall, read_en; 

assign read_en = (empty || ~blank) ? 1'b0 : 1'b1;
assign stall = (empty) ? 1'b1 : 1'b0;

assign pixel_r = read_en ? fifo_color[23:16] : 8'd0;
assign pixel_g = read_en ? fifo_color[15:8] : 8'd0;
assign pixel_b = read_en ? fifo_color[7:0] : 8'd0;

endmodule