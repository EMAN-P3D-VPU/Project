module matrix_unit_top(input clk,
                        input rst_n,
                        input [15:0] v0, //all these have to be input regs
                        input [15:0] v1,
                        input [15:0] v2,
                        input [15:0] v3,
                        input [15:0] v4,
                        input [15:0] v5,
                        input [15:0] v6,
                        input [15:0] v7,
                        input [1:0] obj_type,
                        input [7:0] obj_color,
                        input [4:0] obj_num_in,
                        input [3:0] gmt_op,
                        input [3:0] gmt_code,
                        input go,
                        output busy,
                        output obj_mem_full_out,
                        output [4:0] lst_stored_obj_out
                        );

//CPU-matrix interface
//wire busy;
//wire obj_mem_full_out;
//wire [4:0] lst_stored_obj_out;
//matrix-obj_unit interface
wire crt_obj, del_obj, del_all, ref_addr, changed_in, obj_mem_full_in, addr_vld;
wire [4:0] obj_num_out, lst_stored_obj_in;
//matrix-mem_unit interface
wire [143:0] mat_obj_in, mat_obj_out;
wire mat_rd_en, mat_wr_en, loadback;
//obj-mem interface
wire [4:0] mat_addr;
//clipping
wire clip_read_en;
wire [4:0] clip_addr;
wire [31:0] obj_map;
wire [143:0] clip_obj_out;

matrix_unit_new mat(.clk(clk), .rst_n(rst_n), .go(go), .v0(v0), .v1(v1), .v2(v2), .v3(v3), .v4(v4), .v5(v5), .v6(v6), .v7(v7),
                .obj_type(obj_type), .obj_color(obj_color), .obj_num_in(obj_num_in),
                .gmt_op(gmt_op), .gmt_code(gmt_code), .obj_in(mat_obj_out), .addr_vld(addr_vld), 
                .lst_stored_obj_in(lst_stored_obj_in), .lst_stored_obj_vld(lst_stored_obj_vld),
                .obj_mem_full_in(obj_mem_full_in), .busy(busy), .lst_stored_obj_out(lst_stored_obj_out),
                .obj_mem_full_out(obj_mem_full_out), .crt_obj(crt_obj), .del_obj(del_obj), .ref_addr(ref_addr),
                .obj_num_out(obj_num_out), .obj_out(mat_obj_in), .rd_en(mat_rd_en), .wr_en(mat_wr_en),
                .loadback(loadback));

video_mem_unit mem_unit(.clk(clk), .rst_n(rst_n), .mat_addr(mat_addr), .mat_obj_in(mat_obj_in), .loadback(loadback),
                .mat_rd_en(mat_rd_en), .mat_wr_en(mat_wr_en), .mat_obj_out(mat_obj_out),
                .clip_addr(clip_addr), .clip_rd_en(clip_rd_en), .clip_obj_out(clip_obj_out));

object_unit obj(.clk(clk), .rst_n(rst_n), .crt_obj(crt_obj), .del_obj(del_obj), .del_all(del_all),
                .ref_addr(ref_addr), .obj_num(obj_num_out), .changed_in(changed_in), .addr(mat_addr),
                .addr_vld(addr_vld), .lst_stored_obj(lst_stored_obj_in), .lst_stored_obj_vld(lst_stored_obj_vld),
                .obj_mem_full(obj_mem_full_in), .obj_map(obj_map));

clipping_unit clipper(.clk(clk), .rst_n(rst_n), .obj_map(obj_map), .obj(clip_obj_out), .addr(clip_addr), .read_en(clip_rd_en),
                .writing(busy));


endmodule
