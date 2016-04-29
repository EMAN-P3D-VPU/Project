module matrix_top(input clk,
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
            input [1:0] obj_type, //0-pt, 1-line, 2-triangle, 3-quad - ALL TESTED
            input [7:0] obj_color,
            input [4:0] obj_num_in,
            input [3:0] gmt_op, // 0 - create_obj,
                                        // 1 - delete single obj - TESTED
                                        // 2 - delete all
                                        // 3 - translate single point - TESTED
                                        // 4 - translate all points - TESTED
                                        // 5 - scale - TESTED
                                        // 6 - rot left, - TESTED
                                        // 7 - rot right, - TESTED
                                        // 8 - reflect x //TODO
                                        // 9 - reflect y
                                        // A - reflect x&y
                                        // B - create matrix //TODO
                                        // C - use matrix  //TODO
                                        // F - loadback
            input [3:0] gmt_code,  //for translate_single - [3:2] bits select point, [1] - y, [0] - x - xy TESTED
                                   //for rotate and scale [2:0] - selects amount, [3] - whether around centroid - TESTED
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
            output busy,
            output reg [4:0] lst_stored_obj_out, //CPU should read this after busy goes low
            output reg obj_mem_full_out,
            //TO OBJECT UNIT
            output crt_obj,
            output del_obj,
            output del_all,
            output ref_addr,
            output [4:0] obj_num_out,
            output reg changed, 
            //TO VIDEO MEMORY UNIT
            output [143:0] obj_out,
            output rd_en,
            output wr_en,
            output loadback,
            //TO CLIPPING UNIT
            output reg writing
            );

wire crt_cmd, trans_one, trans_all, scl_cmd, rotl_cmd, rotr_cmd, trans_x, trans_y;
wire writeback, writeback_cen, ld_obj_in, calc_from_cen, ldback_reg;
wire ld_point, do_mult, do_div, set_changed;
wire ld_trans_coeff, ld_scl_coeff, ld_rot_coeff, get_rotl_coeff, get_rotr_coeff;

wire [2:0] point_cnt;
wire signed [15:0] mat_res_x, mat_res_y;
wire [2:0] max_point_cnt;
wire [15:0] scl_coeff, scl_coeff_d;

wire signed [15:0]  x0, y0, x1, y1, x2, y2, x3, y3;
wire [2:0] rot_amt;


matrix_data datapath(.clk(clk),
                    .rst_n(rst_n),
                    .v0(v0),
                    .v1(v1),
                    .v2(v2),
                    .v3(v3),
                    .v4(v4),
                    .v5(v5),
                    .v6(v6),
                    .v7(v7),
                    .obj_type(obj_type),
                    .obj_color(obj_color),
                    .gmt_code(gmt_code),
                    .go(go),
                    .crt_cmd(crt_cmd),
                    .trans_one(trans_one),
                    .writeback(writeback),
                    .writeback_cen(writeback_cen),
                    .ld_obj_in(ld_obj_in),
                    .calc_from_cen(calc_from_cen),
                    .ldback_reg(ldback_reg),
                    .point_cnt(point_cnt),
                    .obj_in(obj_in),
                    .mat_res_x(mat_res_x), .mat_res_y(mat_res_y),
                    .max_point_cnt(max_point_cnt),
                    .x0(x0),
                    .x1(x1),
                    .x2(x2),
                    .x3(x3),
                    .y0(y0),
                    .y1(y1),
                    .y2(y2),
                    .y3(y3),
                    .obj_out(obj_out)
                    );

matrix_mult multpath(.clk(clk),
                    .rst_n(rst_n),
                    .ld_trans_coeff(ld_trans_coeff),
                    .ld_scl_coeff(ld_scl_coeff),
                    .ld_rot_coeff(ld_rot_coeff),
                    .get_rotl_coeff(get_rotl_coeff),
                    .get_rotr_coeff(get_rotr_coeff),
                    .trans_one(trans_one),
                    .trans_all(trans_all),
                    .scl_cmd(scl_cmd),
                    .rotl_cmd(rotl_cmd),
                    .rotr_cmd(rotr_cmd),
                    .trans_x(trans_x),
                    .trans_y(trans_y),
                    .v0(v0),
                    .scl_coeff(scl_coeff),
                    .scl_coeff_d(scl_coeff_d),
                    .ld_point(ld_point),
                    .do_mult(do_mult),
                    .do_div(do_div),
                    .point_cnt(point_cnt),
                    .x0(x0),
                    .x1(x1),
                    .x2(x2),
                    .x3(x3),
                    .y0(y0),
                    .y1(y1),
                    .y2(y2),
                    .y3(y3),
                    .rot_amt(rot_amt),
                    .mat_res_x(mat_res_x), .mat_res_y(mat_res_y)
                    );


matrix_state state(.clk(clk),
                    .rst_n(rst_n),
                    .go(go),
                    .reading(reading),
                    .gmt_op(gmt_op),
                    .gmt_code(gmt_code),
                    .obj_num_in(obj_num_in),
                    .obj_mem_full_in(obj_mem_full_in),
                    .addr_vld(addr_vld),
                    .max_point_cnt(max_point_cnt),
                    .crt_obj(crt_obj),
                    .del_obj(del_obj),
                    .del_all(del_all),
                    .ref_addr(ref_addr),
                    .obj_num_out(obj_num_out),
                    .rd_en(rd_en),
                    .wr_en(wr_en),
                    .loadback(loadback),
                    .scl_coeff(scl_coeff),
                    .scl_coeff_d(scl_coeff_d),
                    .rot_amt(rot_amt),
                    .busy(busy),
                    .point_cnt(point_cnt),
                    .crt_cmd(crt_cmd),
                    .trans_one(trans_one),
                    .trans_all(trans_all),
                    .scl_cmd(scl_cmd),
                    .rotl_cmd(rotl_cmd),
                    .rotr_cmd(rotr_cmd),
                    .trans_x(trans_x),
                    .trans_y(trans_y),
                    .writeback(writeback),
                    .writeback_cen(writeback_cen),
                    .ld_obj_in(ld_obj_in),
                    .calc_from_cen(calc_from_cen),
                    .ldback_reg(ldback_reg),
                    .ld_point(ld_point),
                    .do_mult(do_mult), 
                    .do_div(do_div), 
                    .set_changed(set_changed),
                    .ld_trans_coeff(ld_trans_coeff),
                    .ld_scl_coeff(ld_scl_coeff),
                    .ld_rot_coeff(ld_rot_coeff),
                    .get_rotl_coeff(get_rotl_coeff),
                    .get_rotr_coeff(get_rotr_coeff)
                    );
    

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        obj_mem_full_out <= 1'b0;
    end else begin
        obj_mem_full_out <= obj_mem_full_in;
    end
end

always @(posedge clk) begin
        if(addr_vld) //stored loc can be returend when obj_unit flags addr_vld
            lst_stored_obj_out <= lst_stored_obj_in;
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        changed <= 1'b1;
    end else begin
        if(set_changed)
            changed <= 1'b1;
        else if (clr_changed)
            changed <= 1'b0;
    end
end


////MATRIX MULTIPLICATION LOGIC


endmodule
