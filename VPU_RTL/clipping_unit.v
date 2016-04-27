module clipping_unit(input clk,
                    input rst_n,
                    input [31:0] obj_map,
                    input [143:0] obj,
                    input raster_ready,
                    input writing, //from matrix_unit
                    input changed,
                    output [9:0] x0_out,
                    output [9:0] y0_out,
                    output [9:0] x1_out,
                    output [9:0] y1_out,
                    output [2:0] color_out,
                    output reg vld,
                    output reg end_of_obj,
                    output [4:0] addr,
                    output reg read_en,
                    output reg [15:0] x0_in_f1, x1_in_f1, y0_in_f1, y1_in_f1,
                    output f1_wr_test,
                    output clr_changed, //to matrix unit
                    output reg reading //to matrix_unit
                    );

//fifo inputs, not sure if they should be wires
reg signed [15:0] x0_in_f0, x1_in_f0, y0_in_f0, y1_in_f0;
reg [7:0] color_in_f0;
wire [3:0] oc0_in, oc1_in; 
reg f0_rd, f0_wr, clr_f0;
//fifo outputs
wire signed [15:0] x0_out_f0, x1_out_f0, y0_out_f0, y1_out_f0;
wire [7:0] color_out_f0;
wire [3:0] oc0_out, oc1_out;
wire f0_empty, f0_full;


//not sure if this fifo needs to be 128-deep
aFifo initial_fifo(
            .Data_out({oc1_out, oc0_out, color_out_f0, y1_out_f0, x1_out_f0, y0_out_f0, x0_out_f0}), 
            .Empty_out(f0_empty), 
            .ReadEn_in(f0_rd), 
            .RClk(clk),
            .Data_in({oc1_in, oc0_in, color_in_f0, y1_in_f0, x1_in_f0, y0_in_f0, x0_in_f0}),
            .Full_out(f0_full), 
            .WriteEn_in(f0_wr), 
            .WClk(clk), 
            .Clear_in(clr_f0)
            );

//fifo inputs, not sure if they should be wires
//reg [15:0] x0_in_f1, x1_in_f1, y0_in_f1, y1_in_f1;
reg [7:0] color_in_f1;
reg f1_rd, f1_wr, clr_f1;
//fifo outputs
wire [15:0] x0_out_f1, x1_out_f1, y0_out_f1, y1_out_f1;
wire [7:0] color_out_f1;
wire f1_empty, f1_full;

aFifo final_fifo(
            .Data_out({color_out_f1, y1_out_f1, x1_out_f1, y0_out_f1, x0_out_f1}), 
            .Empty_out(f1_empty), 
            .ReadEn_in(f1_rd), 
            .RClk(clk),
            .Data_in({8'b0, color_in_f1, y1_in_f1, x1_in_f1, y0_in_f1, x0_in_f1}),
            .Full_out(f1_full), 
            .WriteEn_in(f1_wr), 
            .WClk(clk), 
            .Clear_in(clr_f1)
            );

assign f1_wr_test = f1_wr;

//For keeping track of objects
reg [1:0] point_cnt;
wire start_refresh, end_refresh;
reg refresh_en;
reg [4:0] obj_num, prev_obj_num;
reg [20:0] refresh_cnt;
wire obj_vld, prev_obj_vld;

//Pipeline regs for storing obj
reg signed [15:0] x0, y0, x1, y1, x2, y2, x3, y3;
reg [7:0] color_reg;
reg [1:0] type_reg;

//For clipping
reg signed [15:0] x0_clip, y0_clip, x1_clip, y1_clip;
reg [7:0] color_clip;
reg [3:0] oc0_clip, oc1_clip;
wire pt0_gt_ymax, pt0_lt_ymin, pt0_gt_xmax, pt0_lt_xmin;
wire pt1_gt_ymax, pt1_lt_ymin, pt1_gt_xmax, pt1_lt_xmin;
wire accept_line, reject_line, clip_line;
reg latch_line, store_line, clip_en;

reg [7:0] cnt;
reg clip_done;
wire ld_pt0, ld_pt1, ldback_x0, ldback_x1, ldback_y0, ldback_y1;
wire signed [15:0] x_a, y_a;
wire signed [15:0] x_b, y_b;
reg signed [15:0] x_diff, y_diff, x_max_min_diff, y_max_min_diff;
reg x_edge, y_edge;
//wire signed [15:0] x_diff, y_diff, x_max_min_diff, y_max_min_diff;
//wire x_edge, y_edge;
wire signed [15:0] x_max_min, y_max_min;
wire signed [15:0] mult1, mult2;
wire rfd;
reg nd;
wire signed [31:0] dividend;
wire signed [15:0] divisor;
//reg signed [31:0] dividend;
//reg signed [15:0] divisor;
wire signed [31:0] quotient; 

reg [3:0] st, nxt_st;
localparam IDLE=4'h0, WAIT_FOR_LINE=4'h1, MAKE_DECISION=4'h2,
            WAIT_FOR_CLIPPING=4'h3;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        refresh_cnt <= 21'h0;
    end else begin
        if(refresh_cnt == 1666667) begin
            refresh_cnt <= 21'h0;
        end else begin
            refresh_cnt <= refresh_cnt +1;
        end
    end
end
assign start_refresh = (refresh_cnt == 1666667) ? 1'b1 : 1'b0;
assign end_refresh = (refresh_cnt == 127) ? 1'b1 : 1'b0; //it'll reset and count from 0-127 after hitting 1666667
assign clr_changed = end_refresh;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        refresh_en <= 1'b0;
    end else begin
        if(start_refresh && changed) //after a delay of 1 cycle, refresh will be enabled
            refresh_en <= 1'b1;
        else if (end_refresh)
            refresh_en <= 1'b0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        point_cnt <= 2'b0;
    end else begin
        if(refresh_en && !writing)
            point_cnt <= point_cnt +1;
        else 
            point_cnt <= 2'b0;
    end
end

wire cycle_1, cycle_2, cycle_3, cycle_4;
assign cycle_1 = (point_cnt == 2'b00) ? 1'b1 : 1'b0;
//these will be low if refresh_en == 0
assign cycle_2 = (point_cnt == 2'b01) ? 1'b1 : 1'b0;
assign cycle_3 = (point_cnt == 2'b10) ? 1'b1 : 1'b0;
assign cycle_4 = (point_cnt == 2'b11) ? 1'b1 : 1'b0;

assign addr = obj_num;
assign obj_vld = (refresh_en && (obj_map[obj_num] == 1'b1)) ? 1'b1 : 1'b0;
assign prev_obj_vld = (refresh_en && (obj_map[prev_obj_num] == 1'b1)) ? 1'b1 : 1'b0;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        read_en <= 1'b0;
    end else begin
        if(cycle_2 && obj_vld) begin
            read_en <= 1'b1; //obj will be available on bus after 2 cycles
        end else begin
            read_en <= 1'b0;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        prev_obj_num <= 5'hx;
        obj_num <= 5'h0;
    end else begin
        if(refresh_en) begin
            if (cycle_4) begin
                prev_obj_num <= obj_num;
                obj_num <= obj_num +1;
            end
        end else begin
            prev_obj_num <= 5'hx;
            obj_num <= 5'h0;
        end
    end
end

//STAGE 1 - a new object is loaded from memory every 4th clk
always @(posedge clk) begin
        if(cycle_4 && obj_vld) begin
            x0 <= obj[15:0];
            y0 <= obj[31:16];
            x1 <= obj[47:32];
            y1 <= obj[63:48];
            x2 <= obj[79:64];
            y2 <= obj[95:80];
            x3 <= obj[111:96];
            y3 <= obj[127:112];
            color_reg <= obj[135:128];
            type_reg <= obj[143:142];
        end 
end

//STAGE 2 - obj is split into lines and stored in a fifo
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        x0_in_f0 <= 16'hx;
        y0_in_f0 <= 16'hx;
        x1_in_f0 <= 16'hx;
        y1_in_f0 <= 16'hx;
        clr_f0 <= 1'b1;
        f0_wr <= 1'b0;
    end else begin
        clr_f0 <= 1'b0;
        if(prev_obj_vld) begin 
            if(cycle_1 && type_reg == 0) begin //point
                x0_in_f0 <= x0;
                y0_in_f0 <= y0;
                x1_in_f0 <= x0;
                y1_in_f0 <= y0;
                f0_wr <= 1'b1;
            end else if(cycle_1 && type_reg >= 1) begin //or first line
                x0_in_f0 <= x0;
                y0_in_f0 <= y0;
                x1_in_f0 <= x1;
                y1_in_f0 <= y1;
                f0_wr <= 1'b1;
            end else if(cycle_2 && type_reg >= 2) begin //2nd line of tri or quad
                x0_in_f0 <= x1;
                y0_in_f0 <= y1;
                x1_in_f0 <= x2;
                y1_in_f0 <= y2;
                f0_wr <= 1'b1;
            end else if(cycle_3 && type_reg == 2) begin //3rd line of tri
                x0_in_f0 <= x2;
                y0_in_f0 <= y2;
                x1_in_f0 <= x0;
                y1_in_f0 <= y0;
                f0_wr <= 1'b1;
            end else if(cycle_3 && type_reg == 3) begin //3rd line of quad
                x0_in_f0 <= x2;
                y0_in_f0 <= y2;
                x1_in_f0 <= x3;
                y1_in_f0 <= y3;
                f0_wr <= 1'b1;
            end else if(cycle_4 && type_reg == 3) begin //4th line of quad
                x0_in_f0 <= x3;
                y0_in_f0 <= y3;
                x1_in_f0 <= x0;
                y1_in_f0 <= y0;
                f0_wr <= 1'b1;
            end else begin
                x0_in_f0 <= 16'hx;
                y0_in_f0 <= 16'hx;
                x1_in_f0 <= 16'hx;
                y1_in_f0 <= 16'hx;
                f0_wr <= 1'b0;
            end
            color_in_f0 <= color_reg;
        end
    end
end

assign oc0_in[3] = (y0_in_f0 > 480) ? 1'b1 : 1'b0;
assign oc0_in[2] = (y0_in_f0 < 0)   ? 1'b1 : 1'b0;
assign oc0_in[1] = (x0_in_f0 > 640) ? 1'b1 : 1'b0;
assign oc0_in[0] = (x0_in_f0 < 0)   ? 1'b1 : 1'b0;
assign oc1_in[3] = (y1_in_f0 > 480) ? 1'b1 : 1'b0;
assign oc1_in[2] = (y1_in_f0 < 0)   ? 1'b1 : 1'b0;
assign oc1_in[1] = (x1_in_f0 > 640) ? 1'b1 : 1'b0;
assign oc1_in[0] = (x1_in_f0 < 0)   ? 1'b1 : 1'b0;


//STAGE 3 - State machines reads lines, clips if needed and put them in out fifo

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        end_of_obj <= 1'b0;
    end else begin
        if(start_refresh)
            end_of_obj <= 1'b0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        st <= IDLE;
    end else begin
        st <= nxt_st;
    end
end

always @(*) begin
f0_rd = 1'b0;
latch_line = 1'b0;
store_line = 1'b0;
clip_en = 1'b0;
reading = 1'b1;
case(st)
    IDLE:
        begin
            if(!f0_empty) begin
                f0_rd = 1'b1;
                nxt_st = WAIT_FOR_LINE;
            end else begin
                reading = 1'b0;
                nxt_st = IDLE;
            end
        end
    WAIT_FOR_LINE:
        begin
           latch_line = 1'b1; 
           nxt_st = MAKE_DECISION;
        end
    MAKE_DECISION:
        begin
            if(accept_line) begin
                store_line = 1'b1;
                nxt_st = IDLE;
            end else if (reject_line) begin //drop this and fetch next line
                nxt_st = IDLE;
            end else if (clip_line) begin
                clip_en = 1'b1; //not sure if this is needed
                nxt_st = WAIT_FOR_CLIPPING;
            end else begin
                nxt_st = IDLE;
            end
        end
    WAIT_FOR_CLIPPING:
        begin
            if(!clip_done) begin
                clip_en = 1'b1;
                nxt_st = WAIT_FOR_CLIPPING;
            end else begin
                store_line = 1'b1;
                nxt_st = IDLE;
            end
        end

endcase
end

//Clipping logic
always @(posedge clk) begin
        if(latch_line) begin //
            x0_clip <= x0_out_f0;
            y0_clip <= y0_out_f0;
            oc0_clip <= oc0_out;
            x1_clip <= x1_out_f0;
            y1_clip <= y1_out_f0;
            oc1_clip <= oc1_out;
            color_clip <= color_out_f0;
        end else if (ldback_x0) begin //
            x0_clip <= x0_clip + quotient[15:0];
            if(pt0_gt_ymax)
                y0_clip <= 480;
            else if (pt0_lt_ymin)
                y0_clip <= 0;
            else
                y0_clip <= 16'hx;
        end else if (ldback_x1) begin //
            x1_clip <= x1_clip + quotient[15:0];
            if(pt1_gt_ymax)
                y1_clip <= 480;
            else if (pt1_lt_ymin)
                y1_clip <= 0;
            else
                y1_clip <= 16'hx;
        end else if (ldback_y0) begin //
            y0_clip <= y0_clip + quotient[15:0];
            if(pt0_gt_xmax)
                x0_clip <= 640;
            else if (pt0_lt_xmin)
                x0_clip <= 0;
            else
                x0_clip <= 16'hx;
        end else if (ldback_y1) begin //
            y1_clip <= y1_clip + quotient[15:0];
            if(pt1_gt_xmax)
                x1_clip <= 640;
            else if (pt1_lt_xmin)
                x1_clip <= 0;
            else
                x1_clip <= 16'hx;
        end
end

assign accept_line = ((oc0_clip | oc1_clip) == 4'b0) ? 1'b1 : 1'b0;
assign reject_line = ((oc0_clip & oc1_clip) != 4'b0) ? 1'b1 : 1'b0;
assign clip_line = !(accept_line || reject_line) ? 1'b1 : 1'b0;

assign pt0_gt_ymax = oc0_clip[3];
assign pt0_lt_ymin = oc0_clip[2];
assign pt0_gt_xmax = oc0_clip[1];
assign pt0_lt_xmin = oc0_clip[0];
assign pt1_gt_ymax = oc1_clip[3];
assign pt1_lt_ymin = oc1_clip[2];
assign pt1_gt_xmax = oc1_clip[1];
assign pt1_lt_xmin = oc1_clip[0];

wire cnt_stop;
wire proc_ymax_cnt, proc_ymin_cnt, proc_xmax_cnt, proc_xmin_cnt;
wire ldback_ymax_cnt, ldback_ymin_cnt, ldback_xmax_cnt, ldback_xmin_cnt;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        cnt <= 8'b0;
    end else begin
        if(clip_en) begin
            if(cnt_stop)
                cnt <= 8'h0;
            else
                cnt <= cnt +1;
        end else begin
            cnt <= 8'h0;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        clip_done <= 1'b0;
    end else begin
        if (cnt_stop) //at 11
            clip_done <= 1'b1;
        else 
            clip_done <= 1'b0;
    end
end

//CLIPPING ALGORITHM -
//order of processing is - ymax, ymin, xmax, xmin
//each one takes stage cycles
//every first stage - flopping and loadback, 2nd  - mult, 3rd  - div
parameter DIV_CYCLES =30;
assign proc_ymax_cnt = (cnt == 0) ? 1'b1 : 1'b0;
assign proc_ymin_cnt = (cnt == (1*(DIV_CYCLES +2))) ? 1'b1 : 1'b0;
assign proc_xmax_cnt = (cnt == (2*(DIV_CYCLES +2))) ? 1'b1 : 1'b0;
assign proc_xmin_cnt = (cnt == (3*(DIV_CYCLES +2))) ? 1'b1 : 1'b0;
assign ldback_ymax_cnt = (cnt == (1*(DIV_CYCLES +2) -1)) ? 1'b1 : 1'b0;
assign ldback_ymin_cnt = (cnt == (2*(DIV_CYCLES +2) -1)) ? 1'b1 : 1'b0;
assign ldback_xmax_cnt = (cnt == (3*(DIV_CYCLES +2) -1)) ? 1'b1 : 1'b0;
assign ldback_xmin_cnt = (cnt == (4*(DIV_CYCLES +2) -1)) ? 1'b1 : 1'b0;
assign cnt_stop = (cnt == (4*(DIV_CYCLES +2) -1)) ? 1'b1 : 1'b0;

always @(posedge clk)
    if (ld_pt0 || ld_pt1)
        nd <= 1'b1;
    else
        nd <= 1'b0;

assign ld_pt0    = (clip_en && 
                    (pt0_gt_ymax && proc_ymax_cnt) ||
                    (pt0_lt_ymin && proc_ymin_cnt) ||
                    (pt0_gt_xmax && proc_xmax_cnt) ||
                    (pt0_lt_xmin && proc_xmin_cnt)
                    ) ? 1'b1 : 1'b0;
assign ld_pt1    = (clip_en && 
                    (pt1_gt_ymax && proc_ymax_cnt) ||
                    (pt1_lt_ymin && proc_ymin_cnt) ||
                    (pt1_gt_xmax && proc_xmax_cnt) ||
                    (pt1_lt_xmin && proc_xmin_cnt)
                    ) ? 1'b1 : 1'b0;
assign ldback_x0 = (clip_en && 
                    (pt0_gt_ymax && ldback_ymax_cnt) || //x has to be loaded back on a ymax violation etc
                    (pt0_lt_ymin && ldback_ymin_cnt)
                    ) ? 1'b1 : 1'b0;
assign ldback_x1 = (clip_en && 
                    (pt1_gt_ymax && ldback_ymax_cnt) ||
                    (pt1_lt_ymin && ldback_ymin_cnt)
                    ) ? 1'b1 : 1'b0;
assign ldback_y0 = (clip_en && 
                    (pt0_gt_xmax && ldback_xmax_cnt) ||
                    (pt0_lt_xmin && ldback_xmin_cnt)
                    ) ? 1'b1 : 1'b0;
assign ldback_y1 = (clip_en && 
                    (pt1_gt_xmax && ldback_xmax_cnt) ||
                    (pt1_lt_xmin && ldback_xmin_cnt)
                    ) ? 1'b1 : 1'b0;
assign x_max_min =  (pt0_gt_xmax || pt1_gt_xmax) ? 640 : 
                    (pt0_lt_xmin || pt1_lt_xmin) ? 0 : 16'hx;
assign y_max_min =  (pt0_gt_ymax || pt1_gt_ymax) ? 480 : 
                    (pt0_lt_ymin || pt1_lt_ymin) ? 0 : 16'hx;
assign x_a =  (ld_pt0 == 1'b1) ? x0_clip :
              (ld_pt1 == 1'b1) ? x1_clip : 16'hx;
assign y_a =  (ld_pt0 == 1'b1) ? y0_clip :
              (ld_pt1 == 1'b1) ? y1_clip : 16'hx;
assign x_b =  (ld_pt0 == 1'b1) ? x1_clip :
              (ld_pt1 == 1'b1) ? x0_clip : 16'hx;
assign y_b =  (ld_pt0 == 1'b1) ? y1_clip :
              (ld_pt1 == 1'b1) ? y0_clip : 16'hx;

//FLOPPING STAGE
always @(posedge clk) begin
    x_diff <= x_b - x_a;
    y_diff <= y_b - y_a;
    x_max_min_diff <= x_max_min - x_a;
    y_max_min_diff <= y_max_min - y_a;
    y_edge <= (proc_ymax_cnt || proc_ymin_cnt) ? (pt0_gt_ymax || pt1_gt_ymax  || pt0_lt_ymin || pt1_lt_ymin) : 1'b0;
    x_edge <= (proc_xmax_cnt || proc_xmin_cnt) ? (pt0_gt_xmax || pt1_gt_xmax  || pt0_lt_xmin || pt1_lt_xmin) : 1'b0;
end
//assign x_diff = x_b - x_a;
//assign y_diff = y_b - y_a;
//assign x_max_min_diff = x_max_min - x_a;
//assign y_max_min_diff = y_max_min - y_a;
//assign y_edge = (proc_ymax_cnt || proc_ymin_cnt) ? (pt0_gt_ymax || pt1_gt_ymax  || pt0_lt_ymin || pt1_lt_ymin) : 1'b0;
//assign x_edge = (proc_xmax_cnt || proc_xmin_cnt) ? (pt0_gt_xmax || pt1_gt_xmax  || pt0_lt_xmin || pt1_lt_xmin) : 1'b0;

assign mult1 =  x_edge ? y_diff : //y_diff on x-edge, x_diff on y-edge
                y_edge ? x_diff : 16'hx;
assign mult2 =  x_edge ? x_max_min_diff : // x on x-edge, y on y-edge
                y_edge ? y_max_min_diff : 16'hx;

assign divisor = x_edge ? x_diff :  //x on x-edge, y on y-edge
                 y_edge ? y_diff : 16'hx;
assign dividend = mult1*mult2;

//always @(posedge clk) begin
//    divisor <= x_edge ? x_diff :  //x on x-edge, y on y-edge
//              y_edge ? y_diff : 16'hx;
//    dividend <= mult1*mult2;
//end

//For simulation
//always @ (posedge clk) begin
//    quotient <= dividend/divisor;
//end
divider div(.rfd(rfd), .nd(nd), .clk(clk), .dividend(dividend), .quotient(quotient), .divisor(divisor));

//For storing into final fifo
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        clr_f1 <= 1'b1;
        f1_wr <= 1'b0;
        x0_in_f1 <= 16'hx;
        y0_in_f1 <= 16'hx;
        x1_in_f1 <= 16'hx;
        y1_in_f1 <= 16'hx;
    end else begin
        clr_f1 <= 1'b0;
        if(store_line) begin
            x0_in_f1 <= x0_clip;
            y0_in_f1 <= y0_clip;
            x1_in_f1 <= x1_clip;
            y1_in_f1 <= y1_clip;
            color_in_f1 <= color_clip;
            f1_wr <= 1'b1;
        end else begin
            x0_in_f1 <= 16'hx;
            y0_in_f1 <= 16'hx;
            x1_in_f1 <= 16'hx;
            y1_in_f1 <= 16'hx;
            f1_wr <= 1'b0;
        end
    end
end

assign x0_out = x0_out_f1[9:0];
assign y0_out = y0_out_f1[9:0];
assign x1_out = x1_out_f1[9:0];
assign y1_out = y1_out_f1[9:0];
assign color_out = color_out_f1[2:0]; //8-bit color path has already been designed
                                      //lets just use 3 bits out of it

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        f1_rd <= 1'b0;
    end else begin
        if(raster_ready) begin //this will cause a 2-cycle delay in data
            f1_rd <= 1'b1;
        end else begin
            f1_rd <= 1'b0;
        end
    end
end

always @(posedge clk)
    vld <= f1_rd; //data will be valid in the next cycle of vld

endmodule
