module steep_calculator(line_cap_reg, dy, dx, steep_value);

input [43:0] line_cap_reg;
output [1:0] steep_value;
output signed [10:0] dy, dx;

wire [9:0] x_0, y_0, x_1, y_1;
wire signed [10:0] dy_, dx_;
wire signed [10:0] abs_dy, abs_dx; //2'sc for slope/steep determination
wire [1:0] steep_value;
wire [1:0] octant_select;
wire slope_steep;
wire slope_polarity; 


//output assigns
assign dy = dy_;
assign dx = dx_;


assign x_0 = line_cap_reg[43:34];
assign y_0 = line_cap_reg[33:24];
assign x_1 = line_cap_reg[23:14];
assign y_1 = line_cap_reg[13:4];


//deterimine change in height/width for slope
assign dy_ = y_1 - y_0;
assign dx_ = x_1 - x_0;
assign abs_dy = (dy[10]) ? (~dy + 1'b1) : dy;
assign abs_dx = (dx[10]) ? (~dx + 1'b1) : dx;

//inversion tree to assign absolute values

//determine polarity/quadrant (is slope + or -?)
assign slope_polarity = dy_[10] ^ dx_[10];
//deterimine if dy <= dx (relational op evaluates to 1/0)
assign slope_steep = (abs_dy <= abs_dx);
//custom truth table
assign octant_select = {slope_polarity, slope_steep};
assign steep_value = (octant_select == 2'b10) ? 2'b11:
                      (octant_select == 2'b11) ? 2'b10: octant_select;

//to find steep quadrant 
endmodule
