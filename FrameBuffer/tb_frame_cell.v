`timescale 1ns / 1ps
module tb_frame_cell();

// test bench for frame_cell

// inputs
reg clk;

// writing
reg [9:0] write_frame_width;
reg [8:0] write_frame_height;
reg write_enable;
reg [2:0] write_data;

// reading
reg [9:0] read_frame_width;
reg [8:0] read_frame_height;

// outputs
wire [2:0] read_data;

frame_cell tb_frame_cell(
			.clk(clk),
			.write_frame_width(write_frame_width),
			.write_frame_height(write_frame_height),
			.write_enable(write_enable),
			.write_data(write_data),
			.read_enable(!write_enable),
			.read_frame_width(read_frame_width),
			.read_frame_height(read_frame_height),
			.read_data(read_data));

integer width_counter;
integer height_counter;

// write every pixel in with a number value ((write_frame_width + write_frame_height) mod 8)
// then read every frame and see if it is the same value
initial begin
	clk = 1'b0;
	write_enable = 1'b1;
	write_data = 3'b0;

	// ensure write and read address are always different
	write_frame_width = 10'b0;
	write_frame_height = 9'b0;
	read_frame_width = 10'b0;
	read_frame_height = 9'b0;

	// begin writing pixels in
	$display("Writing to RAM");
	for (height_counter = 0; height_counter < 480; height_counter = height_counter + 1) begin
		for(width_counter = 0; width_counter < 640; width_counter = width_counter + 1) begin
			#10
			// increment write_data by 1 every address
			write_data = write_data + 3'd1;

			// check if conflicts occur when read and write address is the same
			write_frame_width = width_counter;
			write_frame_height = height_counter;
			read_frame_width = width_counter;
			read_frame_height = height_counter;
		end
	end

	#10
	// begin reading
	write_enable = 1'b0;
	write_data = 3'b0;

	$display("Reading from RAM");
	for (height_counter = 0; height_counter < 480; height_counter = height_counter + 1) begin
		for(width_counter = 0; width_counter < 640; width_counter = width_counter + 1) begin
			#10

			if (write_data != read_data) begin
				$display("For w: %d h: %d, data is %d but should be %d",
					width_counter, height_counter, read_data, write_data);
			end

			// increment write_data by 1 every address
			write_data = write_data + 3'd1;
			write_frame_width = width_counter;
			write_frame_height = height_counter;
			read_frame_width = width_counter;
			read_frame_height = height_counter;
		end
	end

	// check last pixel
	#10
	if (write_data != read_data) begin
		$display("For w: %d h: %d, data is %d but should be %d",
			width_counter, height_counter, read_data, write_data);
	end

	$stop();

end

always
	#5 clk = ~clk;

endmodule