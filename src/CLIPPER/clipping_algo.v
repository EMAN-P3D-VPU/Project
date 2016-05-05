module clipping_algo(input clk,
                    input rst_n,
                    input latch_line,
                    input store_line,
                    input clip_en,
                    input signed [15:0] x0_out_f0, x1_out_f0, y0_out_f0, y1_out_f0,
                    input [7:0] color_out_f0,
                    input [3:0] oc0_out, oc1_out,
                    output reg signed [15:0] x0_in_f1, x1_in_f1, y0_in_f1, y1_in_f1,
                    output reg [7:0] color_in_f1,
                    output reg f1_wr, clr_f1,
                    output reg clip_done,
                    output signed [31:0] quotient,
                    output accept_line, reject_line, clip_line
                    );

wire proc_ymax_cnt, proc_ymin_cnt, proc_xmax_cnt, proc_xmin_cnt;
wire ldback_ymax_cnt, ldback_ymin_cnt, ldback_xmax_cnt, ldback_xmin_cnt;
wire ld_pt0, ld_pt1, ldback_x0, ldback_x1, ldback_y0, ldback_y1;
wire cnt_stop;
reg [7:0] cnt;

reg signed [15:0] x0_clip, y0_clip, x1_clip, y1_clip;
reg [7:0] color_clip;
reg [3:0] oc0_clip, oc1_clip;
wire pt0_gt_ymax, pt0_lt_ymin, pt0_gt_xmax, pt0_lt_xmin;
wire pt1_gt_ymax, pt1_lt_ymin, pt1_gt_xmax, pt1_lt_xmin;

wire signed [15:0] x_a, y_a;
wire signed [15:0] x_b, y_b;
reg signed [15:0] x_diff, y_diff, x_max_min_diff, y_max_min_diff;
reg x_edge, y_edge;
wire signed [15:0] x_max_min, y_max_min;
wire signed [15:0] mult1, mult2;
wire rfd;
reg nd;
wire signed [31:0] dividend;
wire signed [15:0] divisor;
//wire signed [31:0] quotient; 


assign accept_line = ((oc0_clip | oc1_clip) == 4'b0) ? 1'b1 : 1'b0;
assign reject_line = ((oc0_clip & oc1_clip) != 4'b0) ? 1'b1 : 1'b0;
assign clip_line = !(accept_line || reject_line) ? 1'b1 : 1'b0;

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
                y0_clip <= 479;
            else if (pt0_lt_ymin)
                y0_clip <= 0;
            else
                y0_clip <= 16'hx;
        end else if (ldback_x1) begin //
            x1_clip <= x1_clip + quotient[15:0];
            if(pt1_gt_ymax)
                y1_clip <= 479;
            else if (pt1_lt_ymin)
                y1_clip <= 0;
            else
                y1_clip <= 16'hx;
        end else if (ldback_y0) begin //
            y0_clip <= y0_clip + quotient[15:0];
            if(pt0_gt_xmax)
                x0_clip <= 639;
            else if (pt0_lt_xmin)
                x0_clip <= 0;
            else
                x0_clip <= 16'hx;
        end else if (ldback_y1) begin //
            y1_clip <= y1_clip + quotient[15:0];
            if(pt1_gt_xmax)
                x1_clip <= 639;
            else if (pt1_lt_xmin)
                x1_clip <= 0;
            else
                x1_clip <= 16'hx;
        end
end

assign pt0_gt_ymax = oc0_clip[3];
assign pt0_lt_ymin = oc0_clip[2];
assign pt0_gt_xmax = oc0_clip[1];
assign pt0_lt_xmin = oc0_clip[0];
assign pt1_gt_ymax = oc1_clip[3];
assign pt1_lt_ymin = oc1_clip[2];
assign pt1_gt_xmax = oc1_clip[1];
assign pt1_lt_xmin = oc1_clip[0];


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
assign x_max_min =  (pt0_gt_xmax || pt1_gt_xmax) ? 639 : 
                    (pt0_lt_xmin || pt1_lt_xmin) ? 0 : 16'hx;
assign y_max_min =  (pt0_gt_ymax || pt1_gt_ymax) ? 479 : 
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

assign mult1 =  x_edge ? y_diff : //y_diff on x-edge, x_diff on y-edge
                y_edge ? x_diff : 16'hx;
assign mult2 =  x_edge ? x_max_min_diff : // x on x-edge, y on y-edge
                y_edge ? y_max_min_diff : 16'hx;

assign divisor = x_edge ? x_diff :  //x on x-edge, y on y-edge
                 y_edge ? y_diff : 16'hx;
assign dividend = mult1*mult2;

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

endmodule
