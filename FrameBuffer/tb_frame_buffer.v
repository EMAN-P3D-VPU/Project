`timescale 1ns / 1ps
module tb_frame_buffer();

// test bench for frame_buffer

//inputs
reg clk;
reg rst_n;

//DVI
reg dvi_fifo_full;

//Rasterizer
reg rast_pixel_rdy;
reg [2:0] rast_color_input;
reg [9:0] rast_width;
reg [8:0] rast_height;
reg rast_done;

//Clipping
reg next_frame_switch;

//outputs
wire [2:0] dvi_color_out;
wire dvi_fifo_write_enable;
wire read_rast_pixel_rdy;

frame_buffer tb_frame_buffer(
				.clk(clk),
				.rst_n(rst_n),
				.dvi_fifo_full(dvi_fifo_full),
				.dvi_color_out(dvi_color_out),
				.dvi_fifo_write_enable(dvi_fifo_write_enable),
				.rast_pixel_rdy(rast_pixel_rdy),
				.rast_color_input(rast_color_input),
				.rast_width(rast_width),
				.rast_height(rast_height),
				.rast_done(rast_done),
				.read_rast_pixel_rdy(read_rast_pixel_rdy),
				.next_frame_switch(next_frame_switch));

integer width_counter;
integer height_counter;

initial begin
	clk = 1'b0;
	rst_n = 1'b0;
	
	// DVI
	dvi_fifo_full = 1'b0;

	// Rasterizer
	rast_pixel_rdy = 1'b1;
	rast_color_input = 3'b0;
	rast_width = 10'b0;
	rast_height = 9'b0;
	rast_done = 1'b0;

	// Clipping
	next_frame_switch = 1'b0;

	#10
	rst_n = 1'b1;

	// begin writing to RAM
	for (height_counter = 0; height_counter < 480; height_counter = height_counter + 1) begin
		for(width_counter = 0; width_counter < 640; width_counter = width_counter + 1) begin
			
			// set width and height
			rast_width = width_counter;
			rast_height = height_counter;

			if(height_counter == 479 && width_counter == 639) begin
				rast_done = 1'b1;
				next_frame_switch = 1'b1;
			end

			#10
			rast_color_input = rast_color_input + 3'd1;
		end
	end

	// ensures that the mode stays the same
	rast_done = 1'b0;
	next_frame_switch = 1'b1;
	rast_pixel_rdy = 1'b0;

	// check reading
	rast_color_input = 3'b0;

	for (height_counter = 0; height_counter < 480; height_counter = height_counter + 1) begin
		for(width_counter = 0; width_counter < 640; width_counter = width_counter + 1) begin
			#10
			if(rast_color_input != dvi_color_out) begin
				$display("FIRST ITERATION: For w: %d h: %d, data is %d but should be %d",
					width_counter, height_counter, dvi_color_out, rast_color_input);
			end

			rast_color_input = rast_color_input + 3'd1;
		end
	end

	// check again
	rast_color_ionput = 3'b0;
	for (height_counter = 0; height_counter < 480; height_counter = height_counter + 1) begin
		for(width_counter = 0; width_counter < 640; width_counter = width_counter + 1) begin
			
			// switch frames
			if(height_counter == 470 && width_counter == 639) begin
				rast_done = 1'b1;
				next_frame_switch = 1'b1;	
			end

			#10
			if(rast_color_input != dvi_color_out) begin
				$display("SECOND ITERATION: For w: %d h: %d, data is %d but should be %d",
					width_counter, height_counter, dvi_color_out, rast_color_input);
			end

			rast_color_input = rast_color_input + 3'd1;
		end
	end


	for (height_counter = 0; height_counter < 480; height_counter = height_counter + 1) begin
		for(width_counter = 0; width_counter < 640; width_counter = width_counter + 1) begin
			#10
			if(3'b0 != dvi_color_out) begin
				$display("Check other frame: For w: %d h: %d, data is %d but should be %d",
					width_counter, height_counter, dvi_color_out, rast_color_input);
			end
		end
	end
	
	$finish();
end

always
	#5 clk = ~clk;

endmodule