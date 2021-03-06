module raster_input_stage(clk, rst, x_0, x_1, y_0, y_1, EoO, valid, color, changed, line_cap_reg);

input clk, rst, EoO, valid, changed;
input [9:0] x_0, x_1, y_0, y_1;
input [2:0] color;

output reg [43:0] line_cap_reg;
//register that keeps all these values (consider this a pipeline stage)

always @(posedge clk, negedge rst)
  begin 
    if(~rst)
      begin
        line_cap_reg <= 46'h00;
      end
    else
      begin
        line_cap_reg <= {x_0, y_0, x_1, y_1, color, valid};
      end
end

endmodule

