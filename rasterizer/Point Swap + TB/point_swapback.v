module point_swapback(x_gen, y_gen, octant, x_f, y_f);

input [9:0] x_gen;
input [8:0] y_gen;
input [2:0] octant;
output [9:0] x_f;
output [8:0] y_f;

assign x_f = ((octant == 3'b000) || (octant == 3'b011) || (octant == 3'b100) || (octant == 3'b111)) ? y_gen:x_gen;
assign y_f = ((octant == 3'b000) || (octant == 3'b011) || (octant == 3'b100) || (octant == 3'b111)) ? x_gen:y_gen;

endmodule