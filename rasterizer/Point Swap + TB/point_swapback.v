module point_swapback(x_gen, y_gen, octant, x_f, y_f);

input [9:0] x_gen;
input [8:0] y_gen;
input [2:0] octant;
output [9:0] x_f;
output [8:0] y_f;

always@(*)
begin

	//octants 1/2 don't get their points swapped
	//octants 5/6 only change vector direction, points generated are constant
	case(octant)
		0:  begin
			end
		3:	begin
			end
		4:	begin
			end
		7: 	begin
			end
		default:	begin
					end


end


endmodule