module clipping_unit(input clk,
                    input rst_n,
                    input [31:0] obj_map,
                    input [143:0] obj,
                    input raster_ready,
                    input writing, //from matrix_unit
                    output reg [9:0] x0_out,
                    output reg [9:0] y0_out,
                    output reg [9:0] x1_out,
                    output reg [7:0] y1_out,
                    output reg [2:0] color_out,
                    output reg vld,
                    output reg end_of_obj,
                    output [4:0] addr,
                    output reg read_en,
                    output reg clr_changed, //to matrix unit
                    output reg reading //to matrix_unit
                    );

//fifo inputs, not sure if they should be wires
reg [15:0] x0_in_f0, x1_in_f0, y0_in_f0, y1_in_f0;
reg [7:0] color_in_f0;
wire [3:0] oc0_in, oc1_in; 
reg f0_rd, f0_wr, clr_f0;
//fifo outputs
wire [15:0] x0_out_f0, x1_out_f0, y0_out_f0, y1_out_f0;
wire [7:0] color_out_f0;
wire [3:0] oc0_out, oc1_out;
wire f0_empty, f0_full;

//not sure if this fifo needs to be 128-deep
aFifo initial_fifo(
            .Data_out({oc1_out, oc0_out, color_out_f0, y1_out_f0, x1_out_f0, y_out_f0, x_out_f0}), 
            .Empty_out(f0_empty), 
            .ReadEn_in(f0_rd), 
            .RClk(clk),
            .Data_in({oc1_in, oc0_in, color_in_f0, y1_in_f0, x1_in_f0, y_in_f0, x_in_f0}),
            .Full_out(f0_full), 
            .WriteEn_in(f0_wr), 
            .WClk(clk), 
            .Clear_in(clr_f0)
            );

//fifo inputs, not sure if they should be wires
reg [15:0] x0_in_f1, x1_in_f1, y0_in_f1, y1_in_f1;
reg [7:0] color_in_f1;
reg f1_rd, f1_wr, clr_f1;
//fifo outputs
wire [15:0] x0_out_f1, x1_out_f1, y0_out_f1, y1_out_f1;
wire [7:0] color_out_f1;
wire f1_empty, f1_full;

aFifo final_fifo(
            .Data_out({8'b0, color_out_f1, y1_out_f1, x1_out_f1, y_out_f1, x_out_f1}), 
            .Empty_out(f1_empty), 
            .ReadEn_in(f1_rd), 
            .RClk(clk),
            .Data_in({color_in_f1, y1_in_f1, x1_in_f1, y_in_f1, x_in_f1}),
            .Full_out(f1_full), 
            .WriteEn_in(f1_wr), 
            .WClk(clk), 
            .Clear_in(clr_f1)
            );

reg signed [16:0] x0, y0, x1, y1, x2, y2, x3, y3;
reg [7:0] color_reg;
reg [1:0] type_reg;

reg [1:0] point_cnt;
wire start_refresh, end_refresh;
reg refresh_en;
reg [4:0] obj_num, prev_obj_num;
reg inc_obj_num, inc_prev_obj_num;
reg [20:0] refresh_cnt;
wire obj_vld, prev_obj_vld;

reg [15:0] x0_clip, y0_clip, x1_clip, y1_clip;
reg [7:0] color_clip;
reg [3:0] oc0_clip, oc1_clip;
wire accept_line, reject_line, clip_line;
reg read_fifo, store_line;

reg [3:0] st, nxt_st;
localparam IDLE=4'h0, WAIT_FOR_LINE=4'h1, MAKE_DECISION=4'h2;

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

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
    end else begin
        if(start_refresh) //after a delay of 1 cycle, refresh will be enabled
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
assign cycle_1 = (point_cnt == 3'b00) ? 1'b1 : 1'b0;
//these will be low if refresh_en == 0
assign cycle_2 = (point_cnt == 3'b01) ? 1'b1 : 1'b0;
assign cycle_3 = (point_cnt == 3'b10) ? 1'b1 : 1'b0;
assign cycle_4 = (point_cnt == 3'b11) ? 1'b1 : 1'b0;

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

assign addr = obj_num;
assign obj_vld = (refresh_en && (obj_map[obj_num] == 1'b1)) ? 1'b1 : 1'b0;
assign prev_obj_vld = (refresh_en && (obj_map[prev_obj_num] == 1'b1)) ? 1'b1 : 1'b0;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
    end else begin
        if(cycle_2 && obj_vld) begin
            read_en = 1'b1; //obj will be available on bus after 2 cycles
        end else begin
            read_en = 1'b0;
        end
    end
end

//STAGE 1 - a new object is loaded into memory every 4th clk
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
    end else begin
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
        end else begin
            x0 <= 16'hx; 
            y0 <= 16'hx; 
            x1 <= 16'hx; 
            y1 <= 16'hx; 
            x2 <= 16'hx; 
            y2 <= 16'hx; 
            x3 <= 16'hx; 
            y3 <= 16'hx;
            color_reg <= 8'hx;
            type_reg <= 2'hx;
        end
    end
end

//STAGE 2 - obj is split into lines and stored in a fifo
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        clr_f0 <= 1'b1;
        f0_wr = 1'b0;
    end else begin
        clr_f0 <= 1'b0;
        if(prev_obj_vld) begin 
            if(cycle_1 && type_reg >= 0) begin //point
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
    end else begin
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
    end else begin
        if(read_fifo) begin //this will be seen after 2 cycles of making fifo_rd 1
            x0_clip <= x0_out_f0;
            y0_clip <= y0_out_f0;
            oc0_clip <= oc0_out;
            x1_clip <= x1_out_f0;
            y1_clip <= y1_out_f0;
            oc1_clip <= oc1_out;
            color_clip <= color_out_f0;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        clr_f1 <= 1'b1;
        f1_wr <= 1'b0;
    end else begin
        clr_f1 <= 1'b0;
        if(store_line) begin
            x0_in_f1 <= x0_clip;
            y0_in_f1 <= y0_clip;
            x1_in_f1 <= x0_clip;
            y1_in_f1 <= y0_clip;
            color_in_f1 <= color_clip;
            f1_wr <= 1'b1;
        end
    end
end

assign accept_line = ((oc0_clip | oc1_clip) == 4'b0) ? 1'b1 : 1'b0;
assign reject_line = ((oc0_clip & oc1_clip) != 4'b0) ? 1'b1 : 1'b0;
assign clip_line = !(accept_line || reject_line) ? 1'b1 : 1'b0;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        st <= IDLE;
    end else begin
        st <= nxt_st;
    end
end

always @(*) begin
f0_rd = 1'b0;
read_fifo = 1'b0;
store_line = 1'b0;
case(st)
    IDLE:
        begin
            if(!f0_empty) begin
                f0_rd = 1'b1;
                nxt_st = WAIT_FOR_LINE;
            end else begin
                nxt_st = IDLE;
            end
        end
    WAIT_FOR_LINE:
        begin
           read_fifo = 1'b1; 
           nxt_st = MAKE_DECISION;
        end
    MAKE_DECISION:
        begin
            if(accept_line) begin
                store_line = 1'b1;
            end else if (reject_line) begin //drop this and fetch next line
                if(!f0_empty) begin
                    f0_rd = 1'b1;
                    nxt_st = WAIT_FOR_LINE;
                end else begin
                    nxt_st = IDLE;
                end
            end else if (clip_line) begin
            end
        end
endcase
end

endmodule
