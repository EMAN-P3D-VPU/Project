module matrix_unit(input clk,
            input rst_n,
            //FROM CPU
            input go,
            input [15:0] v0,
            input [15:0] v1,
            input [15:0] v2,
            input [15:0] v3,
            input [15:0] v4,
            input [15:0] v5,
            input [15:0] v6,
            input [15:0] v7,
            input [1:0] obj_type, //0 -line, 1 -triangle, 2 -quad
            input [7:0] obj_color,
            input [4:0] obj_num_in,
            input [2:0] geometric_op, // 0 - create_obj,
                                        // 1 - delete obj
                                        // 2 - translate,
                                        // 3 - scale
                                        // 4 - rot left,
                                        // 5 - rot right,
                                        // 6 - reflect
                                        // 7 - matrix operation
            input [2:0] geometric_code, //for delete (1 bit) - selects between all or single
                                        //for translate (3 bits, 4+1) - selects point
                                        //for rotate and scale (3 bits) - selects amount
                                        //for reflect (1 bit) - selects axis
                                        //for matrix op (1-bit) - whether to create or use matrix
            input [1:0] translate_xy,
            //FROM VIDEO MEMORY UNIT
            input [143:0] mem_obj,
            //FROM OBJECT UNIT
            input addr_vld,
            input [4:0] lst_stored_obj_in,
            input lst_stored_obj_vld,
            input obj_mem_full_in,
            //FROM CLIPPING UNIT
            input clr_changed,

            //TO CPU
            output reg busy,
            output reg [4:0] lst_stored_obj_out, //CPU should read this after busy goes low
            output reg obj_mem_full_out,
            //TO OBJECT UNIT
            output reg crt_obj,
            output reg del_obj,
            output reg ref_addr,
            output reg [4:0] obj_num_out,
            output changed,
            //TO VIDEO MEMORY UNIT
            output reg [143:0] obj_out,
            output reg rd_en,
            output reg wr_en,
            output reg special_load_out
);

reg signed [15:0]  x0, x1, y0, y1, x2, y2, x3, y3;
wire crt_cmd, del_cmd, trans_cmd, scl_cmd, rotl_cmd, rotr_cmd, ref_cmd, mat_op;
wire del_all, ref_axis, crt_or_use_mat;

reg [1:0] st, nxt_st;
localparam IDLE=2'h0, WAIT_FOR_VLD=2'h1;

assign crt_cmd = (geometric_op == 0)? 1'b1: 1'b0;
assign del_cmd = (geometric_op == 1)? 1'b1: 1'b0;
assign trans_cmd = (geometric_op == 2)? 1'b1: 1'b0;
assign scl_cmd = (geometric_op == 3)? 1'b1: 1'b0;
assign rotl_cmd = (geometric_op == 4)? 1'b1: 1'b0;
assign rotr_cmd = (geometric_op == 5)? 1'b1: 1'b0;
assign ref_cmd = (geometric_op == 6)? 1'b1: 1'b0;
assign mat_op = (geometric_op == 7)? 1'b1: 1'b0;

assign del_all = (del_cmd == 1) ? geometric_code[0]: 1'bz;
assign ref_axis = (ref_cmd == 1) ? geometric_code[0]: 1'bz;
assign crt_or_use_mat = (mat_op == 1) ? geometric_code[0]: 1'bz;

assign draw_pt = (obj_type == 0)? 1'b1: 1'b0;
assign draw_line = (obj_type == 1)? 1'b1: 1'b0;
assign draw_tri = (obj_type == 2)? 1'b1: 1'b0;
assign draw_quad = (obj_type == 3)? 1'b1: 1'b0;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
    end else begin
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        obj_mem_full_out <= 1'b0;
    end else begin
        obj_mem_full_out <= obj_mem_full_in;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        obj_out <= 148'h0;
    end else begin
        if (go && crt_cmd) //obj_out gets automatically created without the SM's inteference
            if (obj_type >= 0) begin
                obj_out[15:0] <= v0;
                obj_out[31:16] <= v1;
            end 
            if (obj_type >= 1) begin
                obj_out[47:32] <= v2;
                obj_out[63:48] <= v3;
            end
            if (obj_type >= 2) begin
                obj_out[79:64] <= v4;
                obj_out[95:80] <= v5;
            end
            if (obj_type == 3) begin
                obj_out[111:96] <= v6;
                obj_out[127:112] <= v7;
            end
            obj_out[135:128] <= obj_color;
            obj_out[143:136] <= {6'bx, obj_type};
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
    end else begin
        if(addr_vld) //stored loc can be returend when obj_unit flags addr_vld
            lst_stored_obj_out <= lst_stored_obj_in;
    end
end


always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        x0 <= 16'h0;
        x1 <= 16'h0;
        x2 <= 16'h0;
        x3 <= 16'h0;
        y0 <= 16'h0;
        y1 <= 16'h0;
        y2 <= 16'h0;
        y3 <= 16'h0;
    end else begin
    end
end

always @(*) begin
busy = 1'b0;
crt_obj = 1'b0;
del_obj = 1'b0;
wr_en = 1'b1;
case (st)
    IDLE:
        if(go)begin
            busy = 1'b1;
            if (crt_cmd) begin
                if(!obj_mem_full_in) begin
                    crt_obj = 1'b1;
                    nxt_st = WAIT_FOR_VLD;
                end else begin
                    nxt_st = IDLE;
                end
            end else if (del_cmd) begin
                del_obj = 1'b1;
            end else if (trans_cmd) begin
            end
        end
    WAIT_FOR_VLD:
        if(addr_vld == 1'b1) begin
            wr_en = 1'b1; //write to video mem
            nxt_st = IDLE;
        end else begin
            busy = 1'b1;
            nxt_st = WAIT_FOR_VLD;
        end
endcase
end

endmodule
