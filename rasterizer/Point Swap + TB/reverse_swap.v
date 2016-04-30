module reverse_swap(x_in, y_in, octant, x_out, y_out);

input [2:0] octant;
input [9:0] x_in, y_in;
output reg [9:0] x_in, y_out;

//if octant is 1, 2, 5, 6, then no action needed
always@(*)
begin
	case (octant)
	
		0:begin
		end
		3:begin
		end
		4:begin
		end
		7:begin
		end
		8:begin
		end


		default :	begin
						x_out = x_in;
						y_out = y_in;
					end
	endcase
end


endmodule