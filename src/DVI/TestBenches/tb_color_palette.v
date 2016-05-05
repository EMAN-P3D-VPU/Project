`timescale 1ns / 1ps
module tb_color_palette();

// inputs
reg [2:0] color_code;

// outputs
wire [23:0] color_translated;

color_palette test(.color_code(color_code),
			.color_translated(color_translated));

initial begin
	color_code = 3'd0;
	#1
	if (color_translated != 24'h000000) begin
		$display("Color Code 0 is incorrect");
	end

	color_code = 3'd1;
	#1
	if (color_translated != 24'hFF0000) begin
		$display("Color Code 1 is incorrect");
	end

	color_code = 3'd2;
	#1
	if (color_translated != 24'hFF8000) begin
		$display("Color Code 2 is incorrect");
	end

	color_code = 3'd3;
	#1
	if (color_translated != 24'hFFFF00) begin
		$display("Color Code 3 is incorrect");
	end

	color_code = 3'd4;
	#1
	if (color_translated != 24'h00FF00) begin
		$display("Color Code 4 is incorrect");
	end

	color_code = 3'd5;
	#1
	if (color_translated != 24'h0000FF) begin
		$display("Color Code 5 is incorrect");
	end

	color_code = 3'd6;
	#1
	if (color_translated != 24'h7F00FF) begin
		$display("Color Code 6 is incorrect");
	end

	color_code = 3'd7;
	#1
	if (color_translated != 24'hFF00FF) begin
		$display("Color Code 7 is incorrect");
	end

	$finish();
end

endmodule