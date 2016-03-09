module matrix_unit(input clk,
            input rst_n,
            //FROM CPU
            input go,
            input signed [15:0] v0,
            input signed [15:0] v1,
            input signed [15:0] v2,
            input signed [15:0] v3,
            input signed [15:0] v4,
            input signed [15:0] v5,
            input signed [15:0] v6,
            input signed [15:0] v7,
            input [1:0] obj_type, //0 -line, 1 -triangle, 2 -quad
            input [7:0] obj_color,
            input [4:0] obj_num_in,
            input [3:0] gmt_op, // 0 - create_obj,
                                        // 1 - delete single obj
                                        // 2 - delete all
                                        // 3 - translate single point
                                        // 4 - translate all points
                                        // 5 - scale
                                        // 6 - rot left,
                                        // 7 - rot right,
                                        // 8 - reflect x
                                        // 9 - reflect y
                                        // A - reflect x&y
                                        // B - create matrix
                                        // C - use matrix
                                        // F - loadback
            input [3:0] gmt_code,  //for translate_single - [3:2] bits select point, [1] - y, [0] - x
                                        //for rotate and scale (3 bits) - selects amount
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
            output reg loadback
);

reg [5:0] coeff_addr;
reg [7:0] coeff;
coeff_ROM ROM(.clk(clk), .addr(coeff_addr), .dout(coeff));

reg [15:0] c11, c12, c13, c21, c22, c23; //not sure about the width of these
reg signed [15:0]  x0, x1, y0, y1, x2, y2, x3, y3; //note - regs are signed
reg [7:0] color_reg, type_reg;

reg ld_trans_coeff, ld_mem_obj, mat_mult, writeback;
wire crt_cmd, del_cmd, trans_one, trans_all, scl_cmd, rotl_cmd, rotr_cmd, ref_cmd;
wire ref_x, ref_y, ref_xy, crt_mat, use_mat, ldback;
wire draw_pt, draw_line, draw_tri, draw_quad;

reg [2:0] st, nxt_st;
localparam IDLE=3'h0, WAIT_FOR_VLD_WR=3'h1, WAIT_FOR_VLD_RD=3'h2, LD_OBJ=3'h3, MAT_MULT=3'h4;

assign crt_cmd = (gmt_op == 4'h0)? 1'b1: 1'b0;
assign del_cmd = (gmt_op == 4'h1)? 1'b1: 1'b0;
assign del_all = (gmt_op == 4'h2)? 1'b1: 1'b0;
assign trans_one = (gmt_op == 4'h3)? 1'b1: 1'b0;
assign trans_all = (gmt_op == 4'h4)? 1'b1: 1'b0;
assign scl_cmd = (gmt_op == 4'h5)? 1'b1: 1'b0;
assign rotl_cmd = (gmt_op == 4'h6)? 1'b1: 1'b0;
assign rotr_cmd = (gmt_op == 4'h7)? 1'b1: 1'b0;
assign ref_x = (gmt_op == 4'h8)? 1'b1: 1'b0;
assign ref_y = (gmt_op == 4'h9)? 1'b1: 1'b0;
assign ref_xy = (gmt_op == 4'ha)? 1'b1: 1'b0;
assign crt_mat = (gmt_op == 4'hb)? 1'b1: 1'b0;
assign use_mat = (gmt_op == 4'hc)? 1'b1: 1'b0;
assign ldback = (gmt_op == 4'hf)? 1'b1: 1'b0;

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
    end else begin
        if(addr_vld) //stored loc can be returend when obj_unit flags addr_vld
            lst_stored_obj_out <= lst_stored_obj_in;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        obj_out <= 148'h0;
    end else begin
        if (go && crt_cmd) begin //obj_out gets automatically created without the SM's inteference
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
        end else if (writeback) begin
            obj_out[15:0] <= x0;
            obj_out[31:15] <= y0;
            obj_out[47:32] <= x1;
            obj_out[63:48] <= y1;
            obj_out[79:64] <= x2;
            obj_out[95:80] <= y2;
            obj_out[111:96] <= x3;
            obj_out[127:112] <= y3;
            obj_out[135:128] <= color_reg;
            obj_out[143:136] <= type_reg;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
    end else begin
        if (ld_trans_coeff) begin //translate amt should be in pixels
            //TODO - should we multiply by a 100 here and then make the divide uniform
            c11 <= 1;
            c12 <= 0;
            if(gmt_code[0] == 1'b1)
                c13 <= v0; //assuming CPU is going to put translate amt in v0
            else
                c13 <= 0;
            c21 <= 0;
            c22 <= 1;
            if(gmt_code[1] == 1'b1)
                c23 <= v0;
            else
                c23 <= 0;
        end
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
        if(ld_mem_obj) begin
            x0 <= mem_obj[15:0];
            y0 <= mem_obj[31:16];
            x1 <= mem_obj[47:32];
            y1 <= mem_obj[63:48];
            x2 <= mem_obj[79:64];
            y2 <= mem_obj[95:80];
            x3 <= mem_obj[111:96];
            y3 <= mem_obj[127:112];
            color_reg <= mem_obj[135:128];
            type_reg <= mem_obj[143:136];
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
    end else begin
        if (mat_mult) begin
            //TODO - the multiplication by a 100
            if(type_reg >= 0) begin //point
                x0 <= x0*c11 + y0*c12 + c13;
                y0 <= x0*c21 + y0*c22 + c23;
            end
            if(type_reg >= 1) begin //line
                x1 <= x1*c11 + y1*c12 + c13;
                y1 <= x1*c21 + y1*c22 + c23;
            end
            if(type_reg >= 2) begin //tri
                x2 <= x2*c11 + y2*c12 + c13;
                y2 <= x2*c21 + y2*c22 + c23;
            end
            if(type_reg == 3) begin //quad
                x3 <= x3*c11 + y3*c12 + c13;
                y3 <= x3*c21 + y3*c22 + c23;
            end
        end
    end
end

always @(*) begin
busy = 1'b0;
crt_obj = 1'b0;
del_obj = 1'b0;
wr_en = 1'b1;
ref_addr = 1'b0;
obj_num_out = 5'b0; //maybe we should have a separate flop to drive obj_num to obj_unit
ld_trans_coeff = 1'b0;
ld_mem_obj = 1'b0;
mat_mult = 1'b0;
case (st)
    IDLE:
        if(go)begin
            busy = 1'b1;
            if (crt_cmd) begin
                if(!obj_mem_full_in) begin
                    crt_obj = 1'b1;
                    nxt_st = WAIT_FOR_VLD_WR;
                end else begin
                    nxt_st = IDLE;
                end
            end else if (del_cmd) begin
                del_obj = 1'b1;
            end else if (trans_all) begin //load the obj and prepare the coeffs
                obj_num_out = obj_num_in;
                ref_addr = 1'b1;
                nxt_st = WAIT_FOR_VLD_RD;
            end
        end
    WAIT_FOR_VLD_WR:
        if(addr_vld == 1'b1) begin
            wr_en = 1'b1; //write to video mem
            nxt_st = IDLE;
        end else begin
            busy = 1'b1;
            nxt_st = WAIT_FOR_VLD_WR;
        end
    WAIT_FOR_VLD_RD:
        if(addr_vld == 1'b1) begin
            rd_en = 1'b1; //read from video mem - obj goes into mem_obj
            nxt_st = LD_OBJ;
        end else begin
            busy = 1'b1;
            nxt_st = WAIT_FOR_VLD_RD;
        end
    LD_OBJ:
        begin
            ld_trans_coeff = 1'b1;
            ld_mem_obj = 1'b1;
            nxt_st = MAT_MULT;
        end
    MAT_MULT:
        begin
            mat_mult = 1'b1;
        end
endcase
end

endmodule
