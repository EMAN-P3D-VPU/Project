module point_swapper(x_0, x_1, y_0, y_1, slope_steep, sx_0, sx_1, sy_0, sy_1, line_octant);

input [9:0] x_0, x_1, y_0, y_1;

input [1:0] slope_steep;
output reg [9:0] sx_0, sx_1, sy_0, sy_1;
//output reg //; //technically could be deciphered from octant, but this is easier to understand
               //positive or negative slope...use to trigger math function appropriately
output reg [2:0] line_octant; //needed to reverse the swap

wire [2:0] octant, octant_f;
wire vector_direction;

//determine which octant we're working in to appropriately translate 
//the point forward
assign vector_direction = (x_0 < x_1) ? 0:1;
assign octant = {slope_steep, vector_direction};

//shifting will give the final octant
assign octant_f = octant >> 1'b1;

always @(octant_f)
begin
  line_octant = octant_f;
end

always @(x_0 or x_1 or slope_steep)
case(octant_f)
  0:begin
    //slope in quadrant 0, slope is greater than 1
    //swap(x0, y0) and swap(x1, y1)
    sx_0 = y_0;
    sy_0 = x_0;
    sx_1 = y_1;
    sy_1 = x_1;

    //positive slope
    // = 1'b0;
    end
  1:begin
    //slope in quadrant 0, slope is greater than 0, less/equal to 1
    //no swapping required, in algorithmic bounds
    sx_0 = x_0;
    sy_0 = y_0;
    sx_1 = x_1;
    sy_1 = y_1;

    //positive slope
    // = 1'b0;
    end
  2:begin
    //slope is in quadrant 1, slope is less than 0, greater/equal to -1
    //slope is negative so use the negative verision of the algorithm
    sx_0 = x_0;
    sy_0 = y_0;
    sx_1 = x_1;
    sy_1 = y_1;

    //negative slope
    // = 1'b1;
    end
  3:begin
    //slope is in quadrant 1, slope is less than -1
    //slope is negative so use negative version of the algorithm
    sx_0 = y_1;
    sy_0 = x_1;
    sx_1 = y_0;
    sy_1 = x_0;

    //negative slope
    // = 1'b1;
    end
  4:begin
    //slope is in quadrant 2, slope is greater than 1
    //x1 < x0
    sx_0 = y_1;
    sy_0 = x_1;
    sx_1 = y_0;
    sy_1 = x_0;

    //positive slope
    // = 1'b0;
    end
  5:begin
    //slope is in quadrant 2, slope is greater than 0, less/equal to 1
    //x1 < x0
    //swap point 0 and point 1
    sx_0 = x_1;
    sy_0 = y_1;
    sx_1 = x_0;
    sy_1 = y_0;

    //positive slope
    // = 1'b0;
    end
  6:begin
    //slope is in quadrant 3, slope is less than 0, greater/equal to -1
    //x1 < x0
    //swap point 0 and point 1
    sx_0 = x_1;
    sy_0 = y_1;
    sx_1 = x_0;
    sy_1 = y_0;

    // = 1'b1;
    end
  7:begin
    //slope is in quadrant 3, slope is less than -1
    //x1 < x0
    sx_0 = y_0;
    sy_0 = x_0;
    sx_1 = y_1;
    sy_1 = x_1;

    // = 1'b1;
    end
endcase

endmodule;


