module matrix_unit(input clk,
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
wire [7:0] coeff_1, coeff_2, coeff_3, coeff_4;
coeff_ROM ROM(.clk(clk), .addr(coeff_addr), .c1(coeff_1), .c2(coeff_2), .c3(coeff_3), .c4(coeff_4));

reg [15:0] c11, c12, c13, c21, c22, c23; //not sure about the width of these
reg [6:0] c11_d, c12_d, c21_d, c22_d;
reg signed [15:0]  x0, y0, x1, y1, x2, y2, x3, y3; //note - regs are signed
reg signed [15:0]  s0, t0, s1, t1, s2, t2, s3, t3; //note - regs are signed
reg [7:0] color_reg, type_reg;

reg ld_trans_coeff, ld_scl_coeff, ld_rot_coeff, ld_mem_obj, calc_centroid;
reg mat_mult, mat_mult_cen, writeback, writeback_cen;
wire [15:0] scl_coeff, scl_coeff_d;
wire crt_cmd, del_cmd, trans_one, trans_all, scl_cmd, rotl_cmd, rotr_cmd, ref_cmd;
wire ref_x, ref_y, ref_xy, crt_mat, use_mat, ldback;
wire draw_pt, draw_line, draw_tri, draw_quad;
wire dont_touch_p0, dont_touch_p1, dont_touch_p2, dont_touch_p3;

reg [3:0] st, nxt_st;
localparam IDLE=4'h0, WAIT_FOR_VLD_WR=4'h1, WAIT_FOR_VLD_RD=4'h2, LD_OBJ=4'h3, 
    CALC_CENTROID = 4'h4, MAT_MULT=4'h5, MAT_MULT_CEN = 4'h6, WRITEBACK = 4'h7, WRITEBACK_CEN = 4'h8;

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
        end else if (writeback_cen) begin
            obj_out[15:0] <= s0 + x0;
            obj_out[31:15] <= t0 + y0;
            obj_out[47:32] <= s1 + x1;
            obj_out[63:48] <= t1 + y1;
            obj_out[79:64] <= s2 + x2;
            obj_out[95:80] <= t2 + y2;
            obj_out[111:96] <= s3 + x3;
            obj_out[127:112] <= t3 + y3;
            obj_out[135:128] <= color_reg;
            obj_out[143:136] <= type_reg;
        end
    end
end

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
        c11_d <= 7'b1; //max divisor needed is 100
        c12_d <= 7'b1;
        c21_d <= 7'b1;
        c22_d <= 7'b1;
    end else begin
        //TODO - should we multiply by a 100 here and then make the divide uniform
        if (ld_trans_coeff) begin //translate amt should be in pixels
            c11 <= 1;
            c12 <= 0;
            c13 <= (gmt_code[0] == 1'b1) ? v0 : 0;
            c21 <= 0;
            c22 <= 1;
            c23 <= (gmt_code[1] == 1'b1) ? v0 : 0;
            c11_d <= 1;
            c12_d <= 1;
            c21_d <= 1;
            c22_d <= 1;
        end else if (ld_scl_coeff) begin
            c11 <= scl_coeff;
            c21 <= 0;
            c13 <= 0;
            c21 <= 0;
            c22 <= scl_coeff;
            c23 <= 0;
            c11_d <= scl_coeff_d;
            c12_d <= 1;
            c21_d <= 1;
            c22_d <= scl_coeff_d;
        end else if (ld_rot_coeff) begin
            c11 <= coeff_1;
            c12 <= coeff_2;
            c13 <= 0;
            c21 <= coeff_3;
            c22 <= coeff_4;
            c23 <= 0;
            c11_d <= 100;
            c21_d <= 100;
            c12_d <= 100;
            c22_d <= 100;
        end
    end
end

assign x_centroid = (x0 + x1 + x2 + x3)/4;
assign y_centroid = (y0 + y1 + y2 + y3)/4;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
    end else begin
        if (calc_centroid) begin
            s0 <= x0 - x_centroid;
            s1 <= x1 - x_centroid;
            s2 <= x2 - x_centroid;
            s3 <= x3 - x_centroid;
            t0 <= y0 - y_centroid;
            t1 <= y1 - y_centroid;
            t2 <= y2 - y_centroid;
            t3 <= y3 - y_centroid;
        end else if (mat_mult_cen) begin
            //TODO - the division by a 100
            if(type_reg >= 0 && !dont_touch_p0) begin //point
                s0 <= s0*c11/c11_d + t0*c12/c12_d + c13;
                t0 <= s0*c21/c21_d + t0*c22/c22_d + c23;
            end
            if(type_reg >= 1 && !dont_touch_p1) begin //line
                s1 <= s1*c11/c11_d + t1*c12/c12_d + c13;
                t1 <= s1*c21/c21_d + t1*c22/c22_d + c23;
            end
            if(type_reg >= 2 && !dont_touch_p2) begin //tri
                s2 <= s2*c11/c11_d + t2*c12/c12_d + c13;
                t2 <= s2*c21/c21_d + t2*c22/c22_d + c23;
            end
            if(type_reg == 3 && !dont_touch_p3) begin //quad
                s3 <= s3*c11/c11_d + t3*c12/c12_d + c13;
                t3 <= s3*c21/c21_d + t3*c22/c22_d + c23;
            end
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
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
        if (mat_mult) begin
            if(type_reg >= 0 && !dont_touch_p0) begin //point
                x0 <= x0*c11/c11_d + y0*c12/c12_d + c13;
                y0 <= x0*c21/c21_d + y0*c22/c22_d + c23;
            end
            if(type_reg >= 1 && !dont_touch_p1) begin //line
                x1 <= x1*c11/c11_d + y1*c12/c12_d + c13;
                y1 <= x1*c21/c21_d + y1*c22/c22_d + c23;
            end
            if(type_reg >= 2 && !dont_touch_p2) begin //tri
                x2 <= x2*c11/c11_d + y2*c12/c12_d + c13;
                y2 <= x2*c21/c21_d + y2*c22/c22_d + c23;
            end
            if(type_reg == 3 && !dont_touch_p3) begin //quad
                x3 <= x3*c11/c11_d + y3*c12/c12_d + c13;
                y3 <= x3*c21/c21_d + y3*c22/c22_d + c23;
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
wr_en = 1'b1;
ref_addr = 1'b0;
obj_num_out = 5'b0; //maybe we should have a separate flop to drive obj_num to obj_unit
ld_trans_coeff = 1'b0;
ld_scl_coeff = 1'b0;
ld_rot_coeff = 1'b0;
ld_mem_obj = 1'b0;
mat_mult = 1'b0;
mat_mult_cen = 1'b0;
writeback = 1'b0;
writeback_cen = 1'b0;
calc_centroid = 1'b0;
coeff_addr = 5'bz;
loadback = 1'b0;
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
            end else if (trans_all || trans_one || scl_cmd || rotl_cmd || rotr_cmd) begin //load the obj and prepare the coeffs
                obj_num_out = obj_num_in;
                ref_addr = 1'b1;
                nxt_st = WAIT_FOR_VLD_RD;
            end else if (ldback) begin
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
            rd_en = 1'b1; //read from video mem - obj goes into mem_obj
            nxt_st = LD_OBJ;
        end else begin
            nxt_st = WAIT_FOR_VLD_RD;
        end
    LD_OBJ:
        begin
            ld_mem_obj = 1'b1;
            if(trans_all || trans_one) begin
                ld_trans_coeff = 1'b1;
                nxt_st = MAT_MULT;
            end else if(scl_cmd) begin
                ld_scl_coeff = 1'b1;
                nxt_st = CALC_CENTROID;
            end else if (rotl_cmd) begin
                coeff_addr = 4*gmt_code[2:0];
                ld_rot_coeff = 1'b1; //this might now work, data might take 1 cycle more
                nxt_st = CALC_CENTROID;
            end else if (rotr_cmd) begin
                coeff_addr = 32 + 4*gmt_code[2:0];
                ld_rot_coeff = 1'b1;
                nxt_st = CALC_CENTROID;
            end
        end
    MAT_MULT:
        begin
            mat_mult = 1'b1;
            nxt_st = WRITEBACK;
        end
    CALC_CENTROID:
        begin
            calc_centroid = 1'b1;
            nxt_st = MAT_MULT_CEN;
        end
    MAT_MULT_CEN:
        begin
            mat_mult_cen = 1'b1;
            nxt_st = WRITEBACK_CEN;
        end
    WRITEBACK:
        begin
            writeback = 1'b1;
            nxt_st = IDLE;
        end
    WRITEBACK_CEN:
        begin
            writeback_cen = 1'b1;
            nxt_st = IDLE;
        end

endcase
end

endmodule
