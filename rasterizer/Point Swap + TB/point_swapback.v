module point_swapback(x_gen, y_gen, octant, clr_color, x_f, y_f);

input [9:0] x_gen;
input [8:0] y_gen;
input [2:0] octant;
input clr_color;
output [9:0] x_f;
output [8:0] y_f;

assign x_f = (((octant == 3'b000) || (octant == 3'b011) || (octant == 3'b100) || (octant == 3'b111)) & ~clr_color) ? y_gen:x_gen;
assign y_f = (((octant == 3'b000) || (octant == 3'b011) || (octant == 3'b100) || (octant == 3'b111)) & ~clr_color) ? x_gen:y_gen;

endmodule
