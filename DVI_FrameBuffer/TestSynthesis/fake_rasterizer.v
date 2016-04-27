`timescale 1ns / 1ps
module fake_rasterizer(input clk,
				input rst,
				input read_rast_pixel_rdy,
				output next_frame_switch,
				output rast_pixel_rdy,
				output reg [2:0] rast_color_input,
				output reg [9:0] rast_width,
				output reg [8:0] rast_height,
				output rast_done);

parameter one_second = 27'd100000000;

// helper functions
reg [26:0] counter;

// determines if we are in the corner of the screen
wire last_pixel;
assign last_pixel = (rast_height == 10'd639) && (rast_width == 9'd479);

// switch frames when counter == 1 sec (100000000) and on the last pixel
assign rast_done = last_pixel & read_rast_pixel_rdy & (counter == one_second);
assign next_frame_switch = rast_done;

assign rast_pixel_rdy = 1'b1;

// width
always @(posedge clk) begin
	if (rst) begin
		rast_width <= 10'd0;
	// if not ready to read, don't change
	end else if (read_rast_pixel_rdy == 1'b0) begin
		rast_width <= rast_width;
	end else if (rast_width == 10'd639) begin
		rast_width <= 10'd0;
	end else begin
		rast_width <= rast_width + 10'd1;
	end
end

// height
always @(posedge clk) begin
	if(rst) begin
		rast_height <= 9'd0;
	// if not ready to read, don't change
	end else if (read_rast_pixel_rdy == 1'b0) begin
		rast_height <= rast_height;
	// corner
	end else if (last_pixel) begin
		rast_height <= 9'd0;
	// go to next row
	end else if (rast_width == 10'd639) begin
		rast_height <= rast_height + 9'd1;
	end else begin
		rast_height <= rast_height;
	end
end

// change mode and counter
// get counter to one_second before switching modes
always @(posedge clk) begin
	if(rst) begin
		counter <= 26'd0;
		rast_color_input <= 3'd2;
	end else if (last_pixel & read_rast_pixel_rdy & (counter == one_second)) begin
		counter <= 26'd0;

		// the colors should alternate through all
		rast_color_input <= rast_color_input + 3'b1;
	end else if (last_pixel & read_rast_pixel_rdy) begin
		counter <= counter + 26'd1;
		rast_color_input <= rast_color_input;
	end else begin
		counter <= counter;
		rast_color_input <= rast_color_input;
	end
end

endmodule