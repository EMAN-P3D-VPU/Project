
module point_gen(x_i, y_i, dy, dx, p_or_n, Xn, Yn);

input signed [9:0] x_i, y_i;
input signed [10:0] dy, dx;
input p_or_n;
output signed [9:0] Xn, Yn;


//21 bits for entire range of algorithm
wire signed [21:0] del_X, del_Xf, del_Y, y_dir, dy_xi, dx_yi, diff, Yn_sel;

assign del_X = x_i + x_i + 22'd2;
assign del_Xf = ~del_X + 22'b1;
assign del_Y = (p_or_n)? (y_i + y_i - 22'b1) :( y_i + y_i + 22'b1);
// assign dy_xi = (dy * del_Xf);
// assign dx_yi = (dx * del_Y);
assign diff =  dy_xi + dx_yi;

rast_mult multdy_xi(.a(dy), .b(del_Xf), .p(dy_xi));
rast_mult multdx_yi(.a(dx), .b(del_Y), .p(dx_yi));

//always step forward in the x direction
assign Xn = x_i + 1;
assign Yn_sel = {p_or_n, diff[21]};
//select if you want y_i or y_i+1
//algorithm equals dx(d1-d2)

assign Yn = (Yn_sel == 1) ? (y_i + 1):
			(Yn_sel == 2) ? (y_i - 1):
							      y_i;

endmodule