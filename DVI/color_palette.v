`timescale 1ns / 1ps
module color_palette(input [2:0] color_code,
					output reg [23:0] color_translated);

// translates the 3 bit color code to a 24 bit color based on hardcoded values
always @(color_code) begin
	case (color_code)
		0: color_translated = 24'h000000;
		1: color_translated = 24'hFF0000;
		2: color_translated = 24'hFF8000;
		3: color_translated = 24'hFFFF00;
		4: color_translated = 24'h00FF00;
		5: color_translated = 24'h0000FF;
		6: color_translated = 24'h7F00FF;
		7: color_translated = 24'hFFFFFF;
		default: color_translated = 24'h000000;
	endcase
end

endmodule