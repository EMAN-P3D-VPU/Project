module fake_rasterizer(input clk,
				input rst,
				input read_rast_pixel_rdy,
				output next_frame_switch,
				output rast_pixel_rdy,
				output [2:0] rast_color_input,
				output reg [9:0] rast_width,
				output reg [8:0] rast_height,
				output rast_done);

parameter one_second = 26'd100000000;

// determines if we are in the corner of the screen
wire last_pixel;
assign last_pixel = rast_height == 10'd639 && rast_width == 9'd479;

// switch frames when counter == 1 sec (100000000)
assign rast_done = counter == one_second;
assign next_frame_switch = rast_done;

assign rast_pixel_rdy = 1'b1;

// depending on mode, switch between two colors
// the colors should be red and blue
assign rast_color_input = mode == 1'b0 ? 3'd1 : 3'd5;

reg mode;
reg [26:0] counter;

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
		mode <= 1'b0;
	end else if (last_pixel && read_rast_pixel_rdy == 1'b1 && counter >= one_second) begin
		counter <= 26'd0;
		mode <= !mode;
	end else if (last_pixel && read_rast_pixel_rdy == 1'b1) begin
		counter <= counter + 26'd1;
		mode <= mode;
	end else begin
		counter <= counter;
		mode <= mode;
	end
end

endmodule