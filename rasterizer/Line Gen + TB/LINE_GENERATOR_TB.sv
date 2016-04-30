module LINE_GENERATOR_TB ();

parameter line_data_width = 68;

reg clk, rst;
reg [2:0] internal_state, internal_nxt_state;

//fake fifo in/out
reg [line_data_width:0] fifo_data;
reg fifo_empty, fifo_rd_en;

//line generator inputs and probeable/testable signals
reg EoO, Frame_Start, obj_change, frame_ready;
reg [2:0] bk_color;

//line generator testable outputs
wire raster_done, frame_rd_en;
wire [2:0] px_color;
wire [9:0] frame_x, frame_y;

//TODO:: instantiate the LINE FIFO here//

LINE_GENERATOR LINE_GENERATOR(.clk(clk), .rst(rst), 
 .fifo_data(fifo_data), .fifo_empty(fifo_empty), .fifo_rd_en(fifo_rd_en), 
 .EoO(EoO), .Frame_Start(Frame_Start), 
 .obj_change(obj_change), 
 .bk_color(bk_color), 
 .frame_ready(frame_ready), .raster_done(raster_done), .frame_rd_en(frame_rd_en), .frame_x(frame_x), .frame_y(frame_y), .px_color(px_color));

/*TODO:: instantiate line generator for self checking*/

//probe the state
assign internal_state = LINE_GENERATOR.state;
assign internal_nxt_state = LINE_GENERATOR.nxt_state;

//FSM PARAMS for comparison
localparam IDLE       = 3'b000;
localparam CLR_SCREEN = 3'b001;
localparam POP_LINE   = 3'b010;
localparam LD_LINE    = 3'b100;  
localparam WAIT_DATA  = 3'b101;
localparam GEN_POINTS = 3'b110;
localparam ERROR      = 3'b111;

//diagnostic info for debugging
  wire [2:0] fail_state, nxt_state;
  reg testing;
  reg nxt_state_flag, curr_state_flag;
  //**LINE CLEARING**//
  real _xcoord, _ycoord;
  real y_track;
  wire _f_rd_en;
  wire _raster_complete;
  reg [2:0] gp_counter;
  reg test_loop;


//10ns (100mhz clock)
always
#10 clk = ~clk;



initial 
begin

test_loop = 1;
testing = 1;
gp_counter = 0;
//begin fsm params
clk = 0;
rst = 0;
//End of objects low
EoO = 0;
//FILL LINE FIFO

//First test screen clearing****
Frame_Start = 0;
frame_ready = 0;
obj_change = 0;
bk_color = 3'b101;
_ycoord = 0;
_xcoord = 0;

#10
//fsm active
rst = 1;

//test every transition possible
while(testing)
begin
    gp_counter = 0;
	//test IDLE TRANSITIONS
	$display("BEGINING IDLE TRANSITION TO IDLE TEST");
	repeat(6)
	begin
		Frame_Start = gp_counter[0];
		frame_ready = gp_counter[1];
		obj_change  = gp_counter[2];

		@(posedge clk)
		begin
          if(internal_state == IDLE)
          begin
          	if(internal_nxt_state == IDLE)
          	begin
             //
          	end
          	else
            begin
              nxt_state_flag = 1;
              break;
          	end
          end
          else
          begin
          	curr_state_flag = 1;
          	break;
          end
		end

		if(curr_state_flag || nxt_state_flag)
		begin
        	$display("**ERROR IN IDLE TESTING** CURRENT STATE: %d, NEXT STATE: %d ", internal_state, internal_nxt_state);
        	$stop;
        end

		gp_counter = gp_counter + 1;
	end

    gp_counter = gp_counter + 1;
    Frame_Start = gp_counter[0];
    frame_ready = gp_counter[1];
    obj_change  = gp_counter[2];

	//NOW TEST TRANSITION INTO CLEAR STATE
	$display("BEGINING IDLE TRANSITION TO CLR SCREEN TEST");
	@(negedge clk)
	begin
		if(gp_counter == 3'b111)
		begin
			if(internal_state == IDLE && internal_nxt_state == CLR_SCREEN)
			begin
    			//check that current and next states are gucci
    			if((_xcoord != frame_x) || (_ycoord != frame_y))
    			begin
    				$display("**COORDINATES FAILED**\nEXPECTED COORDINATES TO WRITE: (%d, %d)\nACTUAL COORDINATES (%d, %d)", _xcoord, _ycoord, frame_x, frame_y);
    				$stop;
    			end
    			if(~LINE_GENERATOR.update_coords)
    			begin
    				$display("**TRANSITION FAILED** FAILED TO UPDATE COORDINATES**");
    				$stop;
    			end
    			//check that rd en high
    			if(~frame_rd_en)
    			begin
    				$display("**TRANSITION FAILED** FRAME READ ENABLE NOT ASSERTED");
    				$stop;
    			end
    			//check that px color is right
    			if(px_color != bk_color)
    			begin
    				$display("**TRANSITION FAILED** INCORRECT PX COLOR OUTPUT TO FRAME BUFFER");
    			end
			end
			else
			begin
			  $display("**ERROR IN IDLE TRANSITION TO CLEAR** CURRENT STATE: %d, NEXT STATE %d", internal_state, internal_nxt_state);
			  $stop;
			end
		end
		else
		begin
			$display("**OFF BY ONE IN GP COUNTER FOR IDLE TESTING**");
			$stop;
		end
	end


	//TEST SCREEN CLEARING NOW
    //@(posedge clk)
    $display("BEGIN CLEAR STATE TRANSITION TO CLEAR STATE",);




    for(_ycoord = 0; _ycoord < 240 + 1; _ycoord++)
    begin

    	y_track = y_track + 1;

        if(_ycoord == 0) //the last (0,0) is alread written and updated on the transition to new state, so we start at (1,0)
        begin

            for(_xcoord = 1; _xcoord < 640 + 1; _xcoord++)
            begin
                //transition into clr state, now we're in clr state
                //on first posedge
                @(posedge clk)
                begin
                    #5;
                    if((internal_state != CLR_SCREEN) || (internal_nxt_state != CLR_SCREEN))
                    begin
                        $display("**STATE FAILED** CURRENT STATE: %d, EXPECTED STATE: %d, CURRENT NEXT: %d, EXPECTED NEXT: %d",internal_state, CLR_SCREEN, internal_nxt_state, CLR_SCREEN);
                        $stop;
                    end
                    //check that current and next states are gucci
                    if((_xcoord != frame_x) || (_ycoord != frame_y))
                    begin
                        $display("**COORDINATES FAILED**\nEXPECTED COORDINATES TO WRITE: (%d, %d)\nACTUAL COORDINATES (%d, %d)", _xcoord, _ycoord, frame_x, frame_y);
                        $stop;
                    end
                    if(~LINE_GENERATOR.update_coords)
                    begin
                        $display("**TRANSITION FAILED** FAILED TO UPDATE COORDINATES**");
                        $stop;
                    end
                    //check that rd en high
                    if(~frame_rd_en)
                    begin
                        $display("**TRANSITION FAILED** FRAME READ ENABLE NOT ASSERTED");
                        $stop;
                    end
                    //check that px color is right
                    if(px_color != bk_color)
                    begin
                        $display("**TRANSITION FAILED** INCORRECT PX COLOR OUTPUT TO FRAME BUFFER");
                    end
                end
            end

        end
        else
        begin

        	for(_xcoord = 0; _xcoord < 640 + 1; _xcoord++)
        	begin
        		//transition into clr state, now we're in clr state
        		//on first posedge
        		@(posedge clk)
        		begin
                    #5;
        			if((internal_state != CLR_SCREEN) || (internal_nxt_state != CLR_SCREEN))
        			begin
        				$display("**STATE FAILED** CURRENT STATE: %d, EXPECTED STATE: %d, CURRENT NEXT: %d, EXPECTED NEXT: %d",internal_state, CLR_SCREEN, internal_nxt_state, CLR_SCREEN);
        				$stop;
        			end
        			//check that current and next states are gucci
        			if((_xcoord != frame_x) || (_ycoord != frame_y))
        			begin
        				$display("**COORDINATES FAILED**\nEXPECTED COORDINATES TO WRITE: (%d, %d)\nACTUAL COORDINATES (%d, %d)", _xcoord, _ycoord, frame_x, frame_y);
        				$stop;
        			end
                    if(~LINE_GENERATOR.update_coords)
                    begin
                        $display("**TRANSITION FAILED** FAILED TO UPDATE COORDINATES**");
                        $stop;
                    end
        			//check that rd en high
        			if(~frame_rd_en)
        			begin
        				$display("**TRANSITION FAILED** FRAME READ ENABLE NOT ASSERTED");
        				$stop;
        			end
        			//check that px color is right
        			if(px_color != bk_color)
        			begin
        				$display("**TRANSITION FAILED** INCORRECT PX COLOR OUTPUT TO FRAME BUFFER");
        			end
        		end
        	end

        end
    end


    $display("BEGIN CLEAR STATE TRANSITION TO CLEAR STATE WITH SAME COORDS (BREAK IN CLEAR SCREEN)",);
    //test stall mech
    frame_ready = 0;
    //fix the x and y expected
    _xcoord = _xcoord - 1;
    _ycoord = _ycoord - 1;

    repeat(10)
    begin
    	@(negedge clk)
    	begin
    		if((internal_state != CLR_SCREEN) || (internal_nxt_state != CLR_SCREEN))
    		begin
    			$display("**STATE FAILED** CURRENT STATE: %d, EXPECTED STATE: %d, CURRENT NEXT: %d, EXPECTED NEXT: %d",internal_state, CLR_SCREEN, internal_nxt_state, CLR_SCREEN);
    			$stop;
    		end
    			//check that current and next states are gucci
    		if((_xcoord != frame_x) || (_ycoord != frame_y))
    		begin
    			$display("**COORDINATES FAILED**\nEXPECTED COORDINATES TO WRITE: (%d, %d)\nACTUAL COORDINATES (%d, %d)", _xcoord, _ycoord, frame_x, frame_y);
    			$stop;
    		end
    			//check that rd en LOW
    		if(frame_rd_en)
    		begin
    			$display("**TRANSITION FAILED** FRAME READ ENABLE NOT ASSERTED");
    			$stop;
    		end
    			//check that px color is right
    		if(px_color != bk_color)
    		begin
    			$display("**TRANSITION FAILED** INCORRECT PX COLOR OUTPUT TO FRAME BUFFER");
    		end
    	end
    end

    $display("BEGIN CLEAR STATE TRANSITION TO CLEAR STATE **FINISH BLANKING**)",);
    frame_ready = 1;


    for(_ycoord = y_track; _ycoord < 481; _ycoord++)
    begin
    	for(_xcoord = 0; _xcoord < 641; _xcoord ++)
    	begin

            @(posedge clk)
            begin
                #5;

                 //CHECK LAST TRANSITION
                if((_ycoord == 480) && (_xcoord == 640))
                begin
                    $display("CHECKING FINAL POINT CONDITIONS");
                    if((internal_state != CLR_SCREEN) || (internal_nxt_state != POP_LINE))
                    begin
                        $display("**STATE FAILED** CURRENT STATE: %d, EXPECTED STATE: %d, CURRENT NEXT: %d, EXPECTED NEXT: %d",internal_state, CLR_SCREEN, internal_nxt_state, CLR_SCREEN);
                        $stop;
                    end
                    if(~LINE_GENERATOR.last_px)
                    begin
                        $display("**TRANSITION FAILED** LAST PX SHOULD BE ASSERTED",);
                    end

                    if((frame_x != _xcoord) || (frame_y != _ycoord))
                    begin
                        $display("**TRANSITION FAILED** OUTPUT (x,y) NOT AT THE FINAL POINT");
                        $stop;
                    end
                                            //check that rd en high
                    if(~frame_rd_en)
                    begin
                        $display("**TRANSITION FAILED** FRAME READ ENABLE NOT ASSERTED");
                        $stop;
                    end
                end
                else begin
            		if(((internal_state != CLR_SCREEN) || (internal_nxt_state != CLR_SCREEN)))
            		begin
            			$display("**STATE FAILED** CURRENT STATE: %d, EXPECTED STATE: %d, CURRENT NEXT: %d, EXPECTED NEXT: %d",internal_state, CLR_SCREEN, internal_nxt_state, CLR_SCREEN);
            			$stop;
            		end
            		//check that current and next states are gucci
            		if((_xcoord != frame_x) || (_ycoord != frame_y))
            		begin
            			$display("**COORDINATES FAILED**\nEXPECTED COORDINATES TO WRITE: (%d, %d)\nACTUAL COORDINATES (%d, %d)", _xcoord, _ycoord, frame_x, frame_y);
            			$stop;
            		end
                    if(~LINE_GENERATOR.update_coords)
                     begin
                        $display("**TRANSITION FAILED** FAILED TO UPDATE COORDINATES**");
                        $stop;
                    end
            		//check that rd en high
            		if(~frame_rd_en)
            		begin
            			$display("**TRANSITION FAILED** FRAME READ ENABLE NOT ASSERTED");
            			$stop;
            		end
            		//check that px color is right
            		if(px_color != bk_color)
            		begin
            			$display("**TRANSITION FAILED** INCORRECT PX COLOR OUTPUT TO FRAME BUFFER");
            		end
                end
            end
    	end
    end

    //TEST LINE POPPING NOW
    //TEST EMPTY CASE LAST!!	
    $display("BEGIN POP LINE TO POP LINE ",);

    



end


//TESTING FAILED
//PRINT OUT DIAGNOSTICs
end



endmodule