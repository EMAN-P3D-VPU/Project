module matrix_unit_new(input clk,
            input rst_n,
            //FROM CPU
            //inputs should hold steady for the duration of the operation
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
                                        //TODO - add the option of rotating around centroid or origin
            input [3:0] gmt_code,  //for translate_single - [3:2] bits select point, [1] - y, [0] - x
                                   //for rotate and scale (3 bits) - selects amount
            //FROM VIDEO MEMORY UNIT
            input [143:0] obj_in,
            //FROM OBJECT UNIT
            input addr_vld,
            input [4:0] lst_stored_obj_in,
            input lst_stored_obj_vld,
            input obj_mem_full_in,
            //FROM CLIPPING UNIT
            input clr_changed,
            input reading,

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
            output reg loadback,
            //TO CLIPPING UNIT
            output reg writing
            );

reg [5:0] coeff_addr;
wire signed[15:0] coeff_1, coeff_2, coeff_3, coeff_4;
coeff_ROM cff_ROM(.clk(clk), .addr(coeff_addr), .c1(coeff_1), .c2(coeff_2), .c3(coeff_3), .c4(coeff_4));

reg signed [15:0] c11, c12, c13, c21, c22, c23; //not sure about the width of these
reg signed [15:0]  x0, y0, x1, y1, x2, y2, x3, y3; //note - regs are signed
//reg signed [15:0]  s0, t0, s1, t1, s2, t2, s3, t3; //note - regs are signed
wire signed [15:0] x_cen_tmp, y_cen_tmp;
reg signed [15:0] x_centroid, y_centroid;
reg signed [15:0] reg_x, reg_y;
reg signed [31:0] mult_res1_x, mult_res1_y, mult_res2_x, mult_res2_y;
reg signed [15:0] mat_res_x, mat_res_y;
wire signed [31:0] sum_1, sum_2;
reg [7:0] color_reg;
reg [1:0] type_reg;

reg ld_trans_coeff, ld_scl_coeff, ld_rot_coeff, ld_obj_in, calc_from_cen;
reg ld_point, inc_point_cnt, clr_point_cnt, ldback_reg, do_mult, do_div;
reg mat_mult, writeback, writeback_cen, set_op_cen, clr_op_cen;
wire [15:0] scl_coeff, scl_coeff_d;
wire crt_cmd, del_cmd, del_all, trans_one, trans_all, scl_cmd, rotl_cmd, rotr_cmd, ref_cmd;
wire ref_x, ref_y, ref_xy, crt_mat, use_mat, ldback;
wire draw_pt, draw_line, draw_tri, draw_quad;
wire dont_touch_p0, dont_touch_p1, dont_touch_p2, dont_touch_p3;

reg op_cen;
reg [2:0] point_cnt;
wire [2:0] max_point_cnt;

reg [3:0] st, nxt_st;
localparam IDLE=4'h0, WAIT_FOR_VLD_WR=4'h1, WAIT_FOR_VLD_RD=4'h2, LD_OBJ=4'h3, 
    MAT_MULT=4'h4, CALC_CENTROID = 4'h5, DO_MULT=4'h6, DO_DIV=4'h7, 
    LDBACK_REG=4'h8, WRITEBACK = 4'h9;

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

//if trans_one is high, 3 of these signals will be high, one will be low
//if trans_one is low, all will be low
assign dont_touch_p0 = (trans_one && gmt_code[3:2] != 2'h0)? 1'b1 : 1'b0;
assign dont_touch_p1 = (trans_one && gmt_code[3:2] != 2'h1)? 1'b1 : 1'b0;
assign dont_touch_p2 = (trans_one && gmt_code[3:2] != 2'h2)? 1'b1 : 1'b0;
assign dont_touch_p3 = (trans_one && gmt_code[3:2] != 2'h3)? 1'b1 : 1'b0;

assign max_point_cnt = type_reg;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        point_cnt <= 3'b0;
    end else begin
        if(clr_point_cnt)
            point_cnt <= 3'b0;
        if(inc_point_cnt)
            point_cnt <= point_cnt +1;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        op_cen <= 1'b0;
    end else begin
        if(clr_op_cen)
            op_cen <= 1'b0;
        if(set_op_cen)
            op_cen <= 1'b1;
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

// OBJECT REGISTERS AND BUSES

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        obj_out <= 148'h0;
    end else begin
        if (go && crt_cmd) begin //obj_out gets automatically created without the SM's inteference
            if (obj_type >= 0) begin
                obj_out[15:0] <= v0;
                obj_out[31:16] <= v1;
            end else begin
                obj_out[15:0] <= 16'hx;
                obj_out[31:16] <= 16'hx;
            end
            if (obj_type >= 1) begin
                obj_out[47:32] <= v2;
                obj_out[63:48] <= v3;
            end else begin
                obj_out[47:32] <= 16'hx;
                obj_out[63:48] <= 16'hx;
            end
            if (obj_type >= 2) begin
                obj_out[79:64] <= v4;
                obj_out[95:80] <= v5;
            end else begin
                obj_out[79:64] <= 16'hx;
                obj_out[95:80] <= 16'hx;
            end
            if (obj_type == 3) begin
                obj_out[111:96] <= v6;
                obj_out[127:112] <= v7;
            end else begin
                obj_out[111:96] <= 16'hx;
                obj_out[127:112] <= 16'hx;
            end
            obj_out[135:128] <= obj_color;
            obj_out[143:136] <= {obj_type, 6'h0};
        end else if (writeback) begin
            if (type_reg >= 0) begin
                obj_out[15:0] <= x0;
                obj_out[31:16] <= y0;
            end else begin
                obj_out[15:0] <= 16'hx;
                obj_out[31:16] <= 16'hx;
            end 
            if (type_reg >= 1) begin
                obj_out[47:32] <= x1;
                obj_out[63:48] <= y1;
            end else begin
                obj_out[47:32] <= 16'hx;
                obj_out[63:48] <= 16'hx;
            end 
            if (type_reg >= 2) begin
                obj_out[79:64] <= x2;
                obj_out[95:80] <= y2;
            end else begin
                obj_out[79:64] <= 16'hx;
                obj_out[95:80] <= 16'hx;
            end 
            if (type_reg == 3) begin
                obj_out[111:96] <= x3;
                obj_out[127:112] <= y3;
            end else begin
                obj_out[111:96] <= 16'hx;
                obj_out[127:112] <= 16'hx;
            end
            obj_out[135:128] <= color_reg;
            obj_out[143:136] <= {type_reg, 6'b0};
        end else if (writeback_cen) begin
            if (type_reg >= 0) begin
                obj_out[15:0] <= x0 + x_centroid;
                obj_out[31:16] <= y0 + y_centroid;
            end else begin
                obj_out[15:0] <= 16'hx;
                obj_out[31:16] <= 16'hx;
            end 
            if (type_reg >= 1) begin
                obj_out[47:32] <= x1 + x_centroid;
                obj_out[63:48] <= y1 + y_centroid;
            end else begin
                obj_out[47:32] <= 16'hx;
                obj_out[63:48] <= 16'hx;
            end 
            if (type_reg >= 2) begin
                obj_out[79:64] <= x2 + x_centroid;
                obj_out[95:80] <= y2 + y_centroid;
            end else begin
                obj_out[79:64] <= 16'hx;
                obj_out[95:80] <= 16'hx;
            end 
            if (type_reg == 3) begin
                obj_out[111:96] <= x3 + x_centroid;
                obj_out[127:112] <= y3 + y_centroid;
            end else begin
                obj_out[111:96] <= 16'hx;
                obj_out[127:112] <= 16'hx;
            end
            obj_out[135:128] <= color_reg;
            obj_out[143:136] <= {type_reg, 6'b0};
        end
    end
end

assign x_cen_tmp = (x0 + x1 + x2 + x3)/4;
assign y_cen_tmp = (y0 + y1 + y2 + y3)/4;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
    end else begin
        if(calc_from_cen) begin
            x_centroid <= x_cen_tmp;
            y_centroid <= y_cen_tmp;
        end
    end
end


////MATRIX MULTIPLICATION LOGIC

assign scl_coeff = (gmt_code[1:0] == 2'h0) ? 1: //0.5 = 1/2
                (gmt_code[1:0] == 2'h1) ? 3: //0.75 = 3/4
                (gmt_code[1:0] == 2'h2) ? 3: //1.5 = 3/2
                (gmt_code[1:0] == 2'h3) ? 2: 16'hx; //2 = 2/1
assign scl_coeff_d = (gmt_code[1:0] == 2'h0) ? 2:
                (gmt_code[1:0] == 2'h1) ? 4:
                (gmt_code[1:0] == 2'h2) ? 2:
                (gmt_code[1:0] == 2'h3) ? 1: 16'hx;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        c11 <= 16'b0;
        c12 <= 16'b0;
        c13 <= 16'b0;
        c21 <= 16'b0;
        c22 <= 16'b0;
        c23 <= 16'b0;
    end else begin
        if (ld_trans_coeff) begin //translate amt should be in pixels
            c11 <= 1;
            c12 <= 0;
            c13 <= (gmt_code[0] == 1'b1) ? v0 : 0;
            c21 <= 0;
            c22 <= 1;
            c23 <= (gmt_code[1] == 1'b1) ? v0 : 0;
        end else if (ld_scl_coeff) begin
            c11 <= scl_coeff;
            c21 <= 0;
            c13 <= 0;
            c21 <= 0;
            c22 <= scl_coeff;
            c23 <= 0;
        end else if (ld_rot_coeff) begin
            c11 <= coeff_1;
            c12 <= coeff_2;
            c13 <= 16'h0;
            c21 <= coeff_3;
            c22 <= coeff_4;
            c23 <= 16'h0;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
    end else begin
        if(ld_point) begin
            if (point_cnt == 4'h0) begin
                reg_x <= x0;
                reg_y <= y0;
            end else if (point_cnt == 4'h1) begin
                reg_x <= x1;
                reg_y <= y1;
            end else if (point_cnt == 4'h2) begin
                reg_x <= x2;
                reg_y <= y2;
            end else if (point_cnt == 4'h3) begin
                reg_x <= x3;
                reg_y <= y3;
            end
        end
    end
end

//wire signed [31:0] mult_res1_x, mult_res1_y, mult_res2_x, mult_res2_y;
//multiplier mult_x1(.clk(clk), .a(reg_x), .b(c11), .p(mult_res1_x));
//multiplier mult_y1(.clk(clk), .a(reg_y), .b(c12), .p(mult_res1_y));
//multiplier mult_x2(.clk(clk), .a(reg_x), .b(c21), .p(mult_res2_x));
//multiplier mult_y2(.clk(clk), .a(reg_y), .b(c22), .p(mult_res2_y));
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
    end else begin
        if(do_mult) begin
                mult_res1_x <= reg_x*c11;
                mult_res1_y <= reg_y*c12;
                mult_res2_x <= reg_x*c21;
                mult_res2_y <= reg_y*c22;
        end
    end
end

//calculating sum of the multiplication terms
assign sum_1 = mult_res1_x + mult_res1_y;
assign sum_2 = mult_res2_x + mult_res2_y;
always @(posedge clk) begin
    if(do_div)
        if(trans_one || trans_all) begin
            mat_res_x <= sum_1[15:0] + c13;//no division required
            mat_res_y <= sum_2[15:0] + c23;
        end else if (scl_cmd && scl_coeff_d == 1) begin
            mat_res_x <= sum_1[15:0] + c13;//no div
            mat_res_y <= sum_2[15:0] + c23;
        end else if (scl_cmd && scl_coeff_d == 2) begin
            mat_res_x <= sum_1[16:1] + c13;//div by 2
            mat_res_y <= sum_2[16:1] + c23;
        end else if (scl_cmd && scl_coeff_d == 4) begin
            mat_res_x <= sum_1[17:2] + c13;//div by 4
            mat_res_y <= sum_2[17:2] + c23;
        end else if(rotl_cmd || rotr_cmd) begin
            mat_res_x <= sum_1[30:15] + c13;//div by 2^15
            mat_res_y <= sum_2[30:15] + c23;
        end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
    end else begin
        if(ld_obj_in) begin
            x0 <= obj_in[15:0];
            y0 <= obj_in[31:16];
            x1 <= obj_in[47:32];
            y1 <= obj_in[63:48];
            x2 <= obj_in[79:64];
            y2 <= obj_in[95:80];
            x3 <= obj_in[111:96];
            y3 <= obj_in[127:112];
            color_reg <= obj_in[135:128];
            type_reg <= obj_in[143:142];
        end else if (calc_from_cen) begin
            x0 <= x0 - x_cen_tmp;
            x1 <= x1 - x_cen_tmp;
            x2 <= x2 - x_cen_tmp;
            x3 <= x3 - x_cen_tmp;
            y0 <= y0 - y_cen_tmp;
            y1 <= y1 - y_cen_tmp;
            y2 <= y2 - y_cen_tmp;
            y3 <= y3 - y_cen_tmp;
        end else if (ldback_reg) begin //
            if(type_reg >= 0 && !dont_touch_p0 && point_cnt == 0) begin //point
                x0 <= mat_res_x;
                y0 <= mat_res_y;
            end
            if(type_reg >= 1 && !dont_touch_p1 && point_cnt == 1) begin //line
                x1 <= mat_res_x;
                y1 <= mat_res_y;
            end
            if(type_reg >= 2 && !dont_touch_p2 && point_cnt == 2) begin //tri
                x2 <= mat_res_x;
                y2 <= mat_res_y;
            end
            if(type_reg == 3 && !dont_touch_p3 && point_cnt == 3) begin //quad
                x3 <= mat_res_x;
                y3 <= mat_res_y;
            end
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n)
        st <= IDLE;
    else
        st <= nxt_st;
end

always @(*) begin
busy = 1'b1;
crt_obj = 1'b0;
del_obj = 1'b0;
obj_num_out = 5'bx; //maybe we should have a separate flop to drive obj_num to obj_unit
ref_addr = 1'b0;
loadback = 1'b0;
wr_en = 1'b0;
rd_en = 1'b0;
ld_trans_coeff = 1'b0;
ld_scl_coeff = 1'b0;
ld_rot_coeff = 1'b0;
coeff_addr = 5'bx;
ld_obj_in = 1'b0;
writeback = 1'b0;
writeback_cen = 1'b0;
calc_from_cen = 1'b0;
set_op_cen = 1'b0;
clr_op_cen = 1'b0;
ld_point = 1'b0;
do_mult = 1'b0;
do_div = 1'b0;
clr_point_cnt = 1'b0;
inc_point_cnt = 1'b0;
ldback_reg = 1'b0;
case (st)
    IDLE:
        if(go)begin
            if (crt_cmd) begin
                if(!obj_mem_full_in) begin
                    crt_obj = 1'b1;
                    nxt_st = WAIT_FOR_VLD_WR;
                end else begin
                    nxt_st = IDLE;
                end
            end else if (del_cmd) begin
                del_obj = 1'b1;
                nxt_st = IDLE;
            end else if (trans_all || trans_one || scl_cmd || rotl_cmd || rotr_cmd) begin //load the obj and prepare the coeffs
                obj_num_out = obj_num_in;
                ref_addr = 1'b1;
                nxt_st = WAIT_FOR_VLD_RD;
            end else if (ldback) begin
                obj_num_out = obj_num_in;
                ref_addr = 1'b1;
                loadback = 1'b1; //not sure if the matrix unit needs to wait for anything
                nxt_st = IDLE;
            end else begin
                busy = 1'b0;
                nxt_st = IDLE;
            end
        end else begin
            busy = 1'b0;
            nxt_st = IDLE;
        end
    WAIT_FOR_VLD_WR:
        if(addr_vld == 1'b1) begin
            wr_en = 1'b1; //write to video mem
            nxt_st = IDLE;
        end else begin
            nxt_st = WAIT_FOR_VLD_WR;
        end
    WAIT_FOR_VLD_RD:
        if(addr_vld == 1'b1) begin
            rd_en = 1'b1; //read from video mem - obj goes into obj_in
            nxt_st = LD_OBJ;
        end else begin
            nxt_st = WAIT_FOR_VLD_RD;
        end
    LD_OBJ:
        begin
            ld_obj_in = 1'b1; //obj will be available in the next stage
            clr_point_cnt = 1'b1;
            if(trans_all || trans_one) begin
                ld_trans_coeff = 1'b1;
                clr_op_cen = 1'b1;
                nxt_st = MAT_MULT;
            end else if(scl_cmd) begin
                set_op_cen = 1'b1;
                nxt_st = CALC_CENTROID;
            end else if (rotl_cmd) begin
                set_op_cen = 1'b1;
                coeff_addr = 4*gmt_code[2:0]; //coeffs will be available in the next cycle
                nxt_st = CALC_CENTROID;
            end else if (rotr_cmd) begin
                set_op_cen = 1'b1;
                coeff_addr = 32 + 4*gmt_code[2:0];
                nxt_st = CALC_CENTROID;
            end
        end
    CALC_CENTROID:
        begin
            if(scl_cmd)
                ld_scl_coeff = 1'b1;
            else if (rotl_cmd || rotr_cmd)
                ld_rot_coeff = 1'b1;
            calc_from_cen = 1'b1;
            nxt_st = MAT_MULT;
        end
    MAT_MULT:
        begin
            ld_point = 1'b1;
            if(point_cnt > max_point_cnt) begin
                nxt_st = WRITEBACK;
            end else begin
                nxt_st = DO_MULT;
            end
        end
    DO_MULT:
        begin
           do_mult = 1'b1;
           nxt_st = DO_DIV;
        end
    DO_DIV:
        begin
            do_div = 1'b1;
            nxt_st = LDBACK_REG;
        end
    LDBACK_REG:
        begin
            ldback_reg = 1'b1;
            inc_point_cnt = 1'b1;
            nxt_st = MAT_MULT;
        end
    WRITEBACK:
        begin
            if(op_cen == 1)
                writeback_cen = 1'b1;
            else
                writeback = 1'b1; 
            obj_num_out = obj_num_in;
            ref_addr = 1'b1;
            nxt_st = WAIT_FOR_VLD_WR;
        end
endcase
end

endmodule
