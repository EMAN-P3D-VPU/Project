module matrix_unit_tb();

reg clk, rst_n;
//CPU inputs
reg [15:0] v0, v1, v2, v3, v4, v5, v6, v7;
reg [1:0] obj_type;
reg [7:0] obj_color;
reg [4:0] obj_num_in;
reg [3:0] gmt_op, gmt_code;
reg go, busy, lst_stored_obj_out, obj_mem_full_out;
//matrix-obj_unit interface
reg crt_obj, del_obj, del_all, ref_addr, changed_in;
reg [4:0] obj_num_out, lst_stored_obj_in, obj_mem_full_in;
reg addr_vld;
//matrix-mem_unit interface
reg [143:0] mat_obj_in, mat_obj_out;
reg mat_rd_en, mat_wr_en, loadback;
//obj-mem interface
reg [4:0] mat_addr;
//clipping
reg [31:0] obj_map;

matrix_unit mat(.clk(clk), .rst_n(rst_n), .go(go), .v0(v0), .v1(v1), .v2(v2), .v3(v3), .v4(v4), .v5(v5), .v6(v6), .v7(v7),
                .obj_type(obj_type), .obj_color(obj_color), .obj_num_in(obj_num_in),
                .gmt_op(gmt_op), .gmt_code(gmt_code), .obj_in(mat_obj_out), .addr_vld(addr_vld), 
                .lst_stored_obj_in(lst_stored_obj_in), .lst_stored_obj_vld(lst_stored_obj_vld),
                .obj_mem_full_in(obj_mem_full_in), .busy(busy), .lst_stored_obj_out(lst_stored_obj_out),
                .obj_mem_full_out(obj_mem_full_out), .crt_obj(crt_obj), .del_obj(del_obj), .ref_addr(ref_addr),
                .obj_num_out(obj_num_out), .obj_out(mat_obj_in), .rd_en(mat_rd_en), .wr_en(mat_wr_en),
                .loadback(loadback));

video_mem_unit mem_unit(.clk(clk), .rst_n(rst_n), .mat_addr(mat_addr), .mat_obj_in(mat_obj_in), .loadback(loadback),
                .mat_rd_en(mat_rd_en), .mat_wr_en(mat_wr_en), .mat_obj_out(mat_obj_out));

object_unit obj(.clk(clk), .rst_n(rst_n), .crt_obj(crt_obj), .del_obj(del_obj), .del_all(del_all),
                .ref_addr(ref_addr), .obj_num(obj_num_out), .changed_in(changed_in), .addr(mat_addr),
                .addr_vld(addr_vld), .lst_stored_obj(lst_stored_obj_in), .lst_stored_obj_vld(lst_stored_obj_vld),
                .obj_mem_full(obj_mem_full_in), .obj_map(obj_map));


initial begin
clk = 1'b0;
rst_n = 1'b0; 
v0 = 100;
v1 = 100;
v2 = 100;
v3 = 200;
v4 = 200;
v5 = 200;
v6 = 200;
v7 = 100;
go = 1'b0;
@(negedge clk);
rst_n = 1'b1;
gmt_op <= 4'h0; //crt
//create three objects
//obj0 - quad
@(posedge clk);
obj_type <= 2'h3;
go <= 1'b1;
@(posedge clk) go <= 1'b0;
wait(busy == 1'b0);
//obj1 - tri
@(posedge clk);
obj_type <= 2'h2;
go <= 1'b1;
@(posedge clk) go <= 1'b0;
wait(busy == 1'b0);
//obj2 - line
@(posedge clk);
obj_type <= 2'h1;
go <= 1'b1;
@(posedge clk) go <= 1'b0;
wait(busy == 1'b0);
@(posedge clk);
//translate object 1 along x-axis by a 100 pixels
obj_num_in <= 5'h1;
v0 <= 100;
gmt_op <= 4'h4;
gmt_code[1:0] <= 2'b01;
go <= 1'b1;
@(posedge clk) go <= 1'b0;
wait(busy == 1'b0);
@(posedge clk);
//rotate object  0 by 60 degrees
obj_num_in <= 5'h0;
gmt_op <= 4'h6; //rotl
gmt_code[2:0] <= 3'h4; //60 deg
go <= 1'b1;
@(posedge clk) go <= 1'b0;
wait(busy == 1'b0);
@(posedge clk);


end

always #5 clk = ~clk;

endmodule
