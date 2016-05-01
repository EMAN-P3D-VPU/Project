//rasterizer provides the complete FSM for screen clearing
//and pixel generation on a line by line basis
module LINE_GENERATOR(/*global inputs*/      clk, rst,
	              /*raster inputs*/      fifo_data, fifo_empty,
	              /*raster self-out*/    fifo_rd_en,
				  /*input from clipper*/ EoO, Frame_Start, 
				  /*input from object*/  obj_change,
				  /*input from matrix*/  bk_color,
				  /*input from f_buff*/  frame_ready,
				  /*output to f_buff*/   raster_done, frame_rd_en, frame_x, frame_y, px_color);

//GLOBAL INPUTS
input clk, rst;
//RASTER INPUTS/OUTPUTS
input [68:0] fifo_data;
input fifo_empty;
output fifo_rd_en;
//CLIPPER INPUTS/OUTPUTS
input EoO, Frame_Start;
//OBJECT UNIT INPUT
input obj_change;
//MATRIX UNIT INPUT
input [2:0] bk_color;
//Frame Buffer input/outputs
input frame_ready;
output raster_done, frame_rd_en;
output [9:0] frame_x, frame_y;
output [2:0] px_color;

//FSM PARAMS
localparam IDLE       = 3'b000;
localparam CLR_SCREEN = 3'b001;
localparam POP_LINE   = 3'b010;
localparam LD_LINE    = 3'b011;  
localparam WAIT_DATA  = 3'b100;
localparam GEN_POINTS = 3'b101;
localparam ERROR      = 3'b110;

//line capture register
//will get filled on a fifo "POP"
reg [68:0] CAP_REG;
reg load_line, load_next_point;
wire valid;

//instantiate the math module here
wire [9:0] new_x, new_y;
wire final_line_point;
//mathmodules****
point_gen POINT_GEN(.x_i(CAP_REG[68:59]), .y_i(CAP_REG[58:49]), .dy(CAP_REG[28:18]), .dx(CAP_REG[17:7]), .p_or_n(CAP_REG[0]), .Xn(new_x), .Yn(new_y));
//see if you hit the final point
assign final_line_point = ((CAP_REG[68:59] == CAP_REG[48:39]) & (CAP_REG[58:49] == CAP_REG[38:29]));

always @(posedge clk or negedge rst) begin
	if(~rst) begin
		CAP_REG <= 0;
	end else 
	if(load_line) begin
		CAP_REG <= fifo_data;
	end else
	if(load_next_point) begin
		CAP_REG <= {new_x, new_y, CAP_REG[48:0]};
	end else
	begin
		CAP_REG <= CAP_REG;
	end
end

assign valid = CAP_REG[3];

//frame buffer coordinate values
reg [9:0] x, y;
reg clr_coords;
reg update_coords;
reg stall_coords;
//As x goes 0 to 640 
always @(posedge clk, negedge rst) begin
	if(~rst) begin
		x <= 0;
	end else 
	if(clr_coords) begin
		x <= 0;
	end else
	if(x == 640 & ~stall_coords) begin
		x <= 0;
	end else
	if(update_coords) begin
		x <= x + 1;
	end
	else begin
		x <= x;
	end
end
//y goes to 480, increasing after each column filled
//y gets auto updated by x
always @(posedge clk or negedge rst) begin
	if(~rst) begin
		y <= 0;
	end else 
	if(stall_coords)
	begin
		y <= y;
	end else
	if(clr_coords) begin
		y <= 0;
	end else
	if((x == 640) & ~stall_coords) begin
		y <= y + 1;
	end else
	if((y == 480) & (x == 640))begin
		y <= 0;
	end
	else
	begin
		y <= y ;
	end
end

//MUX output px_color between background color or the line color
reg clr_color;
assign px_color = (clr_color)? bk_color:CAP_REG[6:4];

//MUX between scanning/clear function and select/paint function
assign frame_x = (clr_color)? x:CAP_REG[68:59];
assign frame_y = (clr_color)? y:CAP_REG[58:49];

wire last_px;
assign last_px = ((x == 640) & (y == 480)) ? 1:0;


//frame and fifo enable regs
reg draw_px, pop;
assign frame_rd_en = draw_px;
assign fifo_rd_en  = pop;

//raster done
reg draw_complete;

//draw complete needs to be held high until 
//next clearing cycle
reg rast_draw_complete;
always@(posedge clk, negedge rst)
begin
	if(~rst)
	begin
		rast_draw_complete <= 0;
	end else
	if(draw_complete)
	begin
		rast_draw_complete <= draw_complete;
	end else
	if(Frame_Start & obj_change & frame_ready)
	begin
		rast_draw_complete <= 0;
	end else
	begin
		rast_draw_complete <= rast_draw_complete;
	end
end

//when draw complete is asserted, the raster done signal gets 
//asserted immediately to be ready before the clock edge.
//the signal is then maintained by a register
assign raster_done = (draw_complete) ? draw_complete:rast_draw_complete;


reg [2:0] state, nxt_state;
always @(posedge clk, negedge rst)
	begin
		if(~rst)
			state <= IDLE;
		else
			state <= nxt_state;
	end


//combinational logic
//(EQUIVALENT TO 'ALWAYS_COMB'
always @(*)
	begin

	//**defaults**
	clr_color     = 0;
	draw_px       = 0;
	pop           = 0;
	update_coords = 0;
	draw_complete = 0;
	clr_coords    = 0;
	update_coords = 0;
	stall_coords  = 0;

	load_line     = 0;
	load_next_point = 0;

		case (state)
			IDLE:
				begin
					if(Frame_Start & obj_change & frame_ready) begin
						//incriment coordinates
						clr_color = 1;
						update_coords = 1;
						draw_px = 1;
						//enter screen clearing state
						nxt_state = CLR_SCREEN;
					end
					else
					begin
						clr_color = 1;
						clr_coords = 1;
						draw_px = 0;
						//next state
						nxt_state = IDLE;
					end
				end
			CLR_SCREEN:
				begin
					if(~frame_ready) begin
						//last coordinates stay the same
						clr_coords = 0;
						update_coords = 0;
						stall_coords = 1;
						//don't draw what was last latched
						draw_px = 0;
						//keep background color
						clr_color = 1;
						nxt_state = CLR_SCREEN;
					end
					else 
					if(frame_ready & ~last_px) begin
						//update the coordinates
						update_coords = 1;
						//draw what was last latched
						draw_px = 1;
						//clear using the background color
						clr_color = 1;

						nxt_state = CLR_SCREEN;
					end
					else
					if(frame_ready & last_px) begin
						//update the coordinates
						update_coords = 1;
						//draw what was last latched
						draw_px = 1;
						//clear using the background color
						clr_color = 1;

						nxt_state = POP_LINE;
					end
				end
			POP_LINE:
				begin
					if(fifo_empty & ~EoO) begin
						//whilst fifo is empty then wait for it to get full
						nxt_state = POP_LINE;
					end else
					if(fifo_empty & EoO) begin
						//rasterizer is done
						draw_complete = 1;
						nxt_state = IDLE;
					end else
					if(~fifo_empty) begin
						//lines exist to be drawn
						//so pop a line
						pop = 1;
						//latch new line into CAP_REG
						load_line = 1;
						nxt_state = LD_LINE;

					end
				end
			LD_LINE:
				begin
					//no conditions, just a state to wait for the line to become
					//available to check validity
					//keep CAP_REG the same
					load_line = 0;
					load_next_point = 0;
					nxt_state = WAIT_DATA;
				end
			WAIT_DATA:
				begin
					//line is now available so check if the line is valid or not
					if(~valid) begin
						//if not valid, go back to pop a different line
						nxt_state = POP_LINE;
					end else
					if(valid & frame_ready) begin
						//update the next x and next y 
					 	load_next_point = 1;
					 	draw_px = 1;

					 	//generate the rest of the points
					 	nxt_state = GEN_POINTS;


					end else
					if(valid & ~frame_ready) begin
						//wait until we can load next point
						//keep same points before we can draw
					 	nxt_state = WAIT_DATA;
					end 
				end
			GEN_POINTS:
				begin
					if(~frame_ready) begin
						//CAP_REG STAYS THE SAME
						load_line = 0;
						load_next_point = 0;
						//don't draw what's latched
						draw_px = 0;
						//pxl color defaults now to line color
						nxt_state = GEN_POINTS;
					end else
					if(frame_ready & ~final_line_point) begin
						//update x0, y0 to get x_next and y_next
						load_next_point = 1;
						draw_px = 1;
						//default color is line color now
						nxt_state = GEN_POINTS;
					end else
					if(frame_ready & final_line_point) begin
						//doesn't really matter what happens to cap reg now
						//we will be reloading, so this value won't get
						//latched to the buffer
						load_line = 0;
						load_next_point = 0;
						draw_px = 1;
						nxt_state = POP_LINE;
					end
				end
			default : nxt_state = ERROR;
		endcase
	end
endmodule