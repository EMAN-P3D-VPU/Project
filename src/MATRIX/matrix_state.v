module matrix_state(input clk,
                    input rst_n,
                    input go,
            input reading,
                    input [3:0] gmt_op,
                    input [3:0] gmt_code,
            input [4:0] obj_num_in,
            input obj_mem_full_in,
            input addr_vld,
            input [2:0] max_point_cnt,
            output reg crt_obj,
            output reg del_obj,
            output reg del_all,
            output reg ref_addr,
            output reg [4:0] obj_num_out,
            output reg rd_en,
            output reg wr_en,
            output reg loadback,
            output [15:0] scl_coeff, scl_coeff_d,
                    output [2:0] rot_amt,
                    output reg busy,
                    output reg [2:0] point_cnt,
                    output crt_cmd, trans_one, trans_all, scl_cmd, rotl_cmd, rotr_cmd, trans_x, trans_y,
                    output reg writeback, writeback_cen, ld_obj_in, calc_from_cen, ldback_reg,
                    output reg ld_point, do_mult, do_div, set_changed,
                    output reg ld_trans_coeff, ld_scl_coeff, ld_rot_coeff, get_rotl_coeff, get_rotr_coeff
                    );

wire del_cmd, del_all_cmd;
wire ref_x, ref_y, ref_xy, crt_mat, use_mat, ldback;
wire rot_cen;

reg op_cen, set_op_cen, clr_op_cen;
reg inc_point_cnt, clr_point_cnt;

reg [3:0] st, nxt_st;
localparam IDLE=4'h0, WAIT_FOR_VLD_WR=4'h1, WAIT_FOR_VLD_RD=4'h2, LD_OBJ=4'h3, 
    LD_TERMS=4'h4, CALC_CENTROID = 4'h5, DO_MULT=4'h6, DO_DIV=4'h7, 
    LDBACK_REG=4'h8, WRITEBACK = 4'h9, WAIT_FOR_COEFF = 4'hA;


assign crt_cmd = (gmt_op == 4'h0)? 1'b1: 1'b0;
assign del_cmd = (gmt_op == 4'h1)? 1'b1: 1'b0;
assign del_all_cmd = (gmt_op == 4'h2)? 1'b1: 1'b0;
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

assign scl_coeff = (gmt_code[1:0] == 2'h0) ? 1: //0.5 = 1/2
                (gmt_code[1:0] == 2'h1) ? 3: //0.75 = 3/4
                (gmt_code[1:0] == 2'h2) ? 3: //1.5 = 3/2
                (gmt_code[1:0] == 2'h3) ? 2: 16'hx; //2 = 2/1
assign scl_coeff_d = (gmt_code[1:0] == 2'h0) ? 2:
                (gmt_code[1:0] == 2'h1) ? 4:
                (gmt_code[1:0] == 2'h2) ? 2:
                (gmt_code[1:0] == 2'h3) ? 1: 16'hx;
assign trans_x = gmt_code[0];
assign trans_y = gmt_code[1];
assign rot_amt = gmt_code[2:0];
assign rot_cen = gmt_code[3];

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
del_all = 1'b0;
obj_num_out = 5'bx; //maybe we should have a separate flop to drive obj_num to obj_unit
ref_addr = 1'b0;
loadback = 1'b0;
wr_en = 1'b0;
rd_en = 1'b0;
ld_trans_coeff = 1'b0;
ld_scl_coeff = 1'b0;
ld_rot_coeff = 1'b0;
get_rotl_coeff = 1'b0;
get_rotr_coeff = 1'b0;
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
set_changed = 1'b0;
case (st)
    IDLE:
        if(go && !reading)begin
            set_changed = 1'b1;
            if (crt_cmd) begin
                if(!obj_mem_full_in) begin
                    crt_obj = 1'b1;
                    nxt_st = WAIT_FOR_VLD_WR;
                end else begin
                    nxt_st = IDLE;
                end
            end else if (del_cmd) begin
                obj_num_out = obj_num_in; //drive obj_num to obj_unit
                del_obj = 1'b1;
                nxt_st = IDLE;
            end else if (del_all_cmd) begin
                del_all = 1'b1;
                nxt_st = IDLE;
            end else if (trans_all || trans_one || scl_cmd || rotl_cmd || rotr_cmd) begin //load the obj and prepare the coeffs
                obj_num_out = obj_num_in; //drive obj_num to obj_unit
                ref_addr = 1'b1;        //ask it to drive addr of this obj to mem
                nxt_st = WAIT_FOR_VLD_RD;
            end else if (ldback) begin
                obj_num_out = obj_num_in; //drive obj_num to obj_unit
                ref_addr = 1'b1;        //ask it to drive addr of this obj to mem
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
            clr_point_cnt = 1'b1;//reset the point_cnt to 0
            if(trans_all || trans_one) begin
                clr_op_cen = 1'b1; //trans ops are never w.r.t centroid
                nxt_st = LD_TERMS;
            end else if(scl_cmd) begin
                set_op_cen = 1'b1; //scaling is always w.r.t centroid
                nxt_st = CALC_CENTROID;
            end else if (rotl_cmd || rotr_cmd) begin
                if(rotl_cmd)
                    get_rotl_coeff = 1'b1; //rot coeff will be loaded in the next cycle
                if(rotr_cmd)
                    get_rotr_coeff = 1'b1; //same as for rotl_cmd
                if(rot_cen) begin //if rotation is w.r.t centroid
                    set_op_cen = 1'b1;
                    nxt_st = CALC_CENTROID;
                end else begin //if not
                    clr_op_cen = 1'b1;
                    nxt_st = WAIT_FOR_COEFF;
                end
            end
        end
    CALC_CENTROID:
        begin
            calc_from_cen = 1'b1; //find x,y from the centroid and store the 
                                    //value of centroid for later 
            nxt_st = LD_TERMS;
        end
    WAIT_FOR_COEFF:
        begin
            nxt_st = LD_TERMS; //wait for the coeff_ROM to give back coeff
        end
    LD_TERMS:
        begin
            ld_point = 1'b1; //load x,y pt into regs for mult
            if(trans_all || trans_one) begin //load coeffs into regs for mult
                ld_trans_coeff = 1'b1;
            end else if(scl_cmd) begin
                ld_scl_coeff = 1'b1;
            end else if (rotl_cmd || rotr_cmd) begin
                ld_rot_coeff = 1'b1;
            end
            if(point_cnt > max_point_cnt) begin //if we've processed all pts of this obj
                nxt_st = WRITEBACK;
            end else begin
                nxt_st = DO_MULT;
            end
        end
    DO_MULT:
        begin
           do_mult = 1'b1; //perform mult of pt and coeff
           nxt_st = DO_DIV;
        end
    DO_DIV:
        begin
            do_div = 1'b1; //choose which bits of the result you want
            nxt_st = LDBACK_REG;
        end
    LDBACK_REG:
        begin
            ldback_reg = 1'b1; //ld result of mult into the appropriate reg
            inc_point_cnt = 1'b1;//move onto processing next pt
            nxt_st = LD_TERMS;
        end
    WRITEBACK:
        begin
            if(op_cen == 1) begin //if this is a centroid operation
                writeback_cen = 1'b1; //add with the centroid before writing
            end else begin            //else
                writeback = 1'b1;     //just write to mem 
            end
            obj_num_out = obj_num_in; //drive obj_num to obj_unit
            ref_addr = 1'b1; //ask it to drive addr corresponding to this num
            nxt_st = WAIT_FOR_VLD_WR;
        end
endcase
end
endmodule
