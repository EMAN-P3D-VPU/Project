module clipping_control(input clk,
                        input rst_n,
                        input raster_ready,
                        input start_refresh,
                        input accept_line, reject_line, clip_line, clip_done,
                        input f0_empty,
                        output reg f0_rd,
                        output reg reading,
                        output reg latch_line, store_line, clip_en,
                        output reg [6:0] pop_cnt
                        );

reg inc_pop_cnt;
reg [3:0] st, nxt_st;
localparam IDLE=4'h0, WAIT_FOR_LINE=4'h1, MAKE_DECISION=4'h2,
            WAIT_FOR_CLIPPING=4'h3;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        pop_cnt <= 7'h0;
    end else begin
        if(start_refresh)
            pop_cnt <= 7'h0;
        else if(inc_pop_cnt) 
            pop_cnt <= pop_cnt +1;
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
inc_pop_cnt = 1'b0;
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
                inc_pop_cnt = 1'b1;
                store_line = 1'b1;
                nxt_st = IDLE;
            end else if (reject_line) begin //drop this and fetch next line
                inc_pop_cnt = 1'b1;
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
                inc_pop_cnt = 1'b1;
                store_line = 1'b1;
                nxt_st = IDLE;
            end
        end

endcase
end


endmodule
