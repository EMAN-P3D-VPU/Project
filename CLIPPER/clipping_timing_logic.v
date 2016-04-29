module clipping_timing_logic(input clk,
                    input rst_n,
                    input [31:0] obj_map,
                    input changed,
                    input writing,
                    output [4:0] addr,
                    output reg refresh_en,
                    output start_refresh, end_refresh,
                    output cycle_1, cycle_2, cycle_3, cycle_4,
                    output obj_vld, prev_obj_vld
                    );

//For keeping track of objects
reg [1:0] point_cnt;
reg [4:0] obj_num, prev_obj_num;
reg [20:0] refresh_cnt;
//wire obj_vld, prev_obj_vld;
//wire cycle_1, cycle_2, cycle_3, cycle_4;

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




endmodule
