//rasterizer provides the complete FSM for screen clearing
//and pixel generation on a line by line basis
module LINE_GENERATOR(/*global inputs*/      clk, rst,
	              /*raster inputs*/      fifo_data, fifo_empty,
	              /*raster self-out*/    fifo_rd_en,
				  /*input from clipper*/ end_of_objects, frame_start, 
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
input end_of_objects, frame_start;

//OBJECT UNIT INPUT
input obj_change;

//MATRIX UNIT INPUT
input [2:0] bk_color;

//Frame Buffer input/outputs
input frame_ready;
output raster_done, frame_rd_en;
output [9:0] frame_x;
output [8:0] frame_y;
output [2:0] px_color;

//FSM PARAMS
localparam IDLE       = 2'b00;
localparam CLR_SCREEN = 2'b01;
localparam POP_LINE   = 2'b10;
localparam GEN_POINTS = 2'b11;

//line capture register
//will get filled on a fifo "POP"
reg [68:0] CAP_REG;

// combinational logic for loading the next line
reg load_line, load_next_point;

// read from fifo when loading in a line
assign fifo_rd_en  = load_line;

// valid determines whether or not to actually draw the line
// take valid directly from the fifo data
wire valid;
assign valid = fifo_data[3];

//instantiate the math module here
wire [9:0] new_x, new_y;
wire final_line_point;

//MUX output px_color between background color or the line color
reg clr_color;
assign px_color = (clr_color) ? bk_color : CAP_REG[6:4];

//mathmodules****
point_gen POINT_GEN(.x_i(CAP_REG[68:59]), .y_i(CAP_REG[58:49]), .dy(CAP_REG[28:18]), .dx(CAP_REG[17:7]), .p_or_n(CAP_REG[0]), .Xn(new_x), .Yn(new_y));

//see if you hit the final point
assign final_line_point = ((CAP_REG[68:59] == CAP_REG[48:39]) & (CAP_REG[58:49] == CAP_REG[38:29]));

// CAP_REG used to load new point and continue drawing line until new_x and new_y are equivalent to the final destination
always @(posedge clk) begin
	if (~rst) begin
		CAP_REG <= 69'b0;
	end else if (load_line) begin
		CAP_REG <= fifo_data;
	end else if (load_next_point) begin
		CAP_REG <= {new_x, new_y, CAP_REG[48:0]};
	end else begin
		CAP_REG <= CAP_REG;
	end
end

//frame buffer coordinate values
reg [9:0] x;
reg [8:0] y;
reg clr_coords;
reg update_coords;

// last pixel used to determine when to move y back to 0 as well as move to next state if in CLR_SCREEN
wire last_px;
assign last_px = (y == 9'd479) & (x == 10'd639);

//As x goes 0 to 639
always @(posedge clk) begin
	if(~rst) begin
		x <= 10'b0;
	// clear x
	end else if (clr_coords) begin
		x <= 10'b0;
	// move x back to 0 to start new row
	end else if ((x == 10'd639) & update_coords) begin
		x <= 10'b0;
	// increment x
	end else if (update_coords) begin
		x <= x + 10'b1;
	// keep x the same if update_coords is not asserted
	end else begin
		x <= x;
	end
end

//y goes to 479, increasing after each column filled
//y gets auto updated by x
always @(posedge clk) begin
	if(~rst) begin
		y <= 9'b0;
	end else if (clr_coords) begin
		y <= 9'b0;
	end else if ((x == 10'd639) & update_coords) begin
		y <= y + 9'b1;
	end else if (last_px & update_coords) begin
		y <= 9'b0;
	end else begin
		y <= y;
	end
end

//MUX between scanning/clear function and select/paint function
assign frame_x = (clr_color) ? x : CAP_REG[68:59];
assign frame_y = (clr_color) ? y : CAP_REG[57:49];

//frame and fifo enable regs
reg draw_px;
assign frame_rd_en = draw_px;

//raster done
reg draw_complete;

//when draw complete is asserted, the raster done signal gets 
//asserted immediately to be ready before the clock edge.
//the signal is then maintained by a register
assign raster_done = draw_complete; //(draw_complete) ? draw_complete:rast_draw_complete;

// state logic
reg [1:0] state, nxt_state;
always @(posedge clk) begin
	if (~rst) begin
		state <= IDLE;
	end else begin
		state <= nxt_state;
	end
end

//combinational logic
//(EQUIVALENT TO 'ALWAYS_COMB'
always @(*) begin

// deterines whether to use bg color or color from line
clr_color = 1'b0;

// draw a pixel to screen
draw_px = 1'b0;

// update x y coordinates to fill screen with a bg color
update_coords = 1'b0;

// x, y go to 0 -> start of filling bg color
clr_coords = 1'b0;

// assert that the rasterizer is done
draw_complete = 1'b0;

// loads in new line from fifo to draw
load_line = 1'b0;

// loads next point of the current line in CAP_REG
load_next_point = 1'b0;

case (state)
	IDLE: begin
		if (frame_start & obj_change) begin
			//set x y to 0
			clr_coords = 1'b1;

			//enter screen clearing state
			nxt_state = CLR_SCREEN;
		end else begin
			nxt_state = IDLE;
		end
	end
	CLR_SCREEN: begin
		// in this state, set the color to bg and continously draw
		clr_color = 1'b1;
		draw_px = 1'b1;

		if (frame_ready & ~last_px) begin
			//update the coordinates
			update_coords = 1'b1;
			nxt_state = CLR_SCREEN;
		end else if (frame_ready & last_px) begin
			// go to POP_LINE when it's the last pixel
			nxt_state = POP_LINE;
		end else begin
			// if frame is not ready, just stay in CLR_SCREEN without updating coords
			nxt_state = CLR_SCREEN;
		end
	end
	POP_LINE: begin
		// go to idle if there is no object change
		if(fifo_empty & end_of_objects & frame_start & ~obj_change) begin
			draw_complete = 1'b1;
			nxt_state = IDLE;
		// go directly to clear screen if object change is ready as well
		end else if (fifo_empty & end_of_objects & frame_start & obj_change) begin
			clr_coords = 1'b1;
			draw_complete = 1'b1;
			nxt_state = CLR_SCREEN;
		// if fifo is not empty -> if invalid just pop line without doing anything with it
		end else if (~fifo_empty & ~valid) begin
			load_line = 1'b1;
			nxt_state = POP_LINE;
		end else if (~fifo_empty & valid) begin
			// a valid line needs to be drawn
			load_line = 1'b1;
			nxt_state = GEN_POINTS;
		end else begin
			// fifo is empty but does not match the criteria to exit out
			nxt_state = POP_LINE;
		end
	end
	GEN_POINTS: begin
		draw_px = 1'b1;
		if (frame_ready & ~final_line_point) begin
			// draw curent pixel and load in the next point
			load_next_point = 1'b1;
			nxt_state = GEN_POINTS;
		end else if (frame_ready & final_line_point) begin
			// do not need to load next point but still draw last pixel
			nxt_state = POP_LINE;
		end else begin
			// frame ready is not asserted so just stay at the same place
			nxt_state = GEN_POINTS;
		end
	end
	default : nxt_state = IDLE;
endcase
end

endmodule