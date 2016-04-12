module line_gen(clk, rst, x_0, y_0, x_1, y_1, dy, p_or_n, line_color, line_available, frame_ready, Xn, Yn, Px_Color, rd_en);

input clk, rst;
input [9:0] x_0, y_0, x_1, y_1;
input [10:0] dy;
input p_or_n;
input [2:0] line_color;
input line_available;
input frame_ready;

output [9:0] Xn, Yn;
output [2:0] Px_Color;
output reg rd_en;

localparam IDLE = 1'b0;
localparam GEN_POINTS = 1'b1;

reg state, nxt_state;
reg [53:0] CAP_REG;

wire last_point;
wire same_x;
wire same_y;

assign same_x = (CAP_REG[53:44] == CAP_REG[33:24])? 1:0;
assign same_y = (CAP_REG[43:34] == CAP_REG[23:14])? 1:0;
assign last_point = same_x & same_y;

//output stage
assign Xn = CAP_REG[53:44];
assign Yn = CAP_REG[43:34];
assign Px_Color = CAP_REG[2:0];


wire [9:0] new_x, new_y;
reg init, update, same;
//reg that holds outputs
always@(posedge clk, negedge rst)
begin
  if(~rst)
  begin
    CAP_REG <= 0;
  end
  else
  if(init)
  begin
    CAP_REG <= {x_0, y_0, x_1, y_1, dy, line_color};
  end
  else
  if(update)
  begin
    CAP_REG <= {new_x, new_y, x_1, y_1, dy, line_color};
  end
  else
  begin
    CAP_REG <= CAP_REG;
  end
end

point_gen POINT_GEN(.x_i(CAP_REG[53:44]), .x_y(CAP_REG[43:34]), .p_or_n(p_or_n), .Xn(new_x), .Yn(new_y));


always @(posedge clk, negedge rst)
begin
  if(~rst)
    state <= IDLE;
  else
    state <= nxt_state;
end

//combinational block
always @(*)
begin
case(state)
  IDLE:
    begin
      if(line_available) //if frame is ready and line available, commit first point
      begin
        rd_en = 0;
        init = 1;
        update = 0;

        nxt_state = GEN_POINTS;
      end
      else//stay in IDLE
      begin
        rd_en = 0;
        init = 0;
        update = 0;

        nxt_state = IDLE;
      end
    end
  GEN_POINTS:
    begin
      if(~frame_ready)
      begin
        rd_en = 0;
        init = 0;
        update = 0;

        nxt_state = GEN_POINTS;
      end
      else 
      if(frame_ready & ~last_point)
      begin
        rd_en = 1;
        init = 0;
        update = 1;

        nxt_state = GEN_POINTS;
      end
      else
      if(frame_ready & last_point)
      begin
        rd_en = 1;
        init = 0;
        update = 0;

        nxt_state = IDLE;
      end
    end
endcase

end



endmodule