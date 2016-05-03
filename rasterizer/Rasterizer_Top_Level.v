module Rasterizer_Top_Level (	clk, rst,
                                x0_in, y0_in,
                                x1_in, y1_in,
                                EoO, valid, Frame_Start, 
                                obj_change,
                                raster_ready,
                                bk_color,
                                line_color,
                                frame_ready,
                                raster_done, frame_rd_en, frame_x, frame_y, px_color);

input clk, rst;
//CLIPPER INPUTS/OUTPUTS
input [9:0] x0_in, y0_in, x1_in, y1_in;
input EoO, Frame_Start, valid;
//OBJECT UNIT INPUT
input obj_change;
//MATRIX UNIT INPUT
input [2:0] line_color;
input [2:0] bk_color;
//Frame Buffer input/outputs
input frame_ready;
output raster_done, frame_rd_en, raster_ready;
output [9:0] frame_x;
output [8:0] frame_y;
output [2:0] px_color;


//top level internals
wire [43:0] line_cap_reg;
wire [10:0] dy, dx;
wire [1:0]  steepness;

wire [9:0] sx_0, sx_1, sy_0, sy_1;
wire [2:0] octant;

reg [45:0] delay;

wire [68:0] fifo_input, fifo_output;
wire fifo_rd_en, fifo_empty, fifo_full;


raster_input_stage input_stage( .clk(clk), 
								.rst(rst), 
								.x_0(x0_in), 
								.x_1(x1_in), 
								.y_0(y0_in), 
								.y_1(y1_in), 
								.EoO(EoO), 
								.valid(valid), 
								.color(line_color), 
								.changed(obj_change), 
								.line_cap_reg(line_cap_reg));

//calculate steepness, dy, dx
steep_calculator steep_calculator(  .line_cap_reg(line_cap_reg),.steep_value(steepness));

point_swapper point_swap(   .x_0(delay[45:36]), 
							.x_1(delay[25:16]), 
							.y_0(delay[35:26]), 
							.y_1(delay[15:6]), 
							.slope_steep(delay[1:0]),

							.sx_0(sx_0), 
							.sx_1(sx_1), 
							.sy_0(sy_0), 
							.sy_1(sy_1), 
							.line_octant(octant), .dy_s(dy), .dx_s(dx));

assign fifo_input = {sx_0, sy_0, sx_1, sy_1, dy, dx, delay[5:3], delay[2], octant};

//GENERATE FIFO INSERT HERE
//TIE WR_EN TO DELAY[2]
// rasterizer fifo - packages lines into 69 bus
assign raster_ready = !fifo_full;
rast_fifo rf(.clk(clk), .rst(~rst), .din(fifo_input), .wr_en(delay[2]), .full(fifo_full), .dout(fifo_output), .rd_en(fifo_rd_en), .empty(fifo_empty));

LINE_GENERATOR LINE_GENERATOR(/*global inputs*/      .clk(clk), .rst(rst),
	              /*raster inputs*/      .fifo_data(fifo_output), .fifo_empty(fifo_empty),
	              /*raster self-out*/    .fifo_rd_en(fifo_rd_en),
				  /*input from clipper*/ .end_of_objects(EoO), .frame_start(Frame_Start), 
				  /*input from object*/  .obj_change(obj_change),
				  /*input from matrix*/  .bk_color(bk_color),
				  /*input from f_buff*/  .frame_ready(frame_ready),
				  /*output to f_buff*/   .raster_done(raster_done), .frame_rd_en(frame_rd_en), .frame_x(frame_x), .frame_y(frame_y), .px_color(px_color));

//pipeline stage
always@(posedge clk, negedge rst)
begin
	if(~rst)
	begin
		delay <= 0;
	end
	else 
	begin
		delay <= {line_cap_reg[43:4], line_cap_reg[3:0], steepness};
	end
end

endmodule
