`include "timescale.v"

module matrix_unit_tb();

reg clk, rst_n;
//CPU inputs
reg [15:0] v0, v1, v2, v3, v4, v5, v6, v7;
reg [1:0] obj_type;
reg [7:0] obj_color;
reg [4:0] obj_num_in;
reg [3:0] gmt_op, gmt_code;
reg go, busy;
wire obj_mem_full_in, obj_mem_full_out;
//matrix-obj_unit interface
reg crt_obj, del_obj, del_all, ref_addr, changed_in;
reg [4:0] obj_num_out, lst_stored_obj_in, lst_stored_obj_out;
reg addr_vld;
//matrix-mem_unit interface
reg [143:0] mat_obj_in, mat_obj_out, clip_obj_out;
reg mat_rd_en, mat_wr_en, loadback;
reg clip_rd_en;
//obj-mem interface
reg [4:0] mat_addr;
reg [4:0] clip_addr;
//clipping
reg [31:0] obj_map;

matrix_unit_new mat(.clk(clk), .rst_n(rst_n), .go(go), .v0(v0), .v1(v1), .v2(v2), .v3(v3), .v4(v4), .v5(v5), .v6(v6), .v7(v7),
                .obj_type(obj_type), .obj_color(obj_color), .obj_num_in(obj_num_in),
                .gmt_op(gmt_op), .gmt_code(gmt_code), .obj_in(mat_obj_out), .addr_vld(addr_vld), 
                .lst_stored_obj_in(lst_stored_obj_in), .lst_stored_obj_vld(lst_stored_obj_vld),
                .obj_mem_full_in(obj_mem_full_in), .busy(busy), .lst_stored_obj_out(lst_stored_obj_out),
                .obj_mem_full_out(obj_mem_full_out), .crt_obj(crt_obj), .del_obj(del_obj), .ref_addr(ref_addr),
                .obj_num_out(obj_num_out), .obj_out(mat_obj_in), .rd_en(mat_rd_en), .wr_en(mat_wr_en),
                .loadback(loadback), .reading(1'b0));

video_mem_unit mem_unit(.clk(clk), .rst_n(rst_n), .mat_addr(mat_addr), .mat_obj_in(mat_obj_in), .loadback(loadback),
                .mat_rd_en(mat_rd_en), .mat_wr_en(mat_wr_en), .mat_obj_out(mat_obj_out), 
                .clip_addr(clip_addr), .clip_rd_en(clip_rd_en), .clip_obj_out(clip_obj_out));

object_unit obj(.clk(clk), .rst_n(rst_n), .crt_obj(crt_obj), .del_obj(del_obj), .del_all(del_all),
                .ref_addr(ref_addr), .obj_num(obj_num_out), .changed_in(changed_in), .addr(mat_addr),
                .addr_vld(addr_vld), .lst_stored_obj(lst_stored_obj_in), .lst_stored_obj_vld(lst_stored_obj_vld),
                .obj_mem_full(obj_mem_full_in), .obj_map(obj_map));

clipping_unit clipper(.clk(clk), .rst_n(rst_n), .obj_map(obj_map), .obj(clip_obj_out), .addr(clip_addr), .read_en(clip_rd_en),
                .writing(busy));


initial begin
    initialize(); //(100, 100), (100,200), (200,200), (200, 100)
    //create three objects
    create(2'h3); //obj0 - quad
    create(2'h2); //obj1 - tri
    create(2'h1); //obj2 - line
    translate(1, 500);//translate object 1 (tri) along x-axis by a <> pixels
    rotate_l(0, 4, 1); //rotate object  0 by 60 degrees around centroid
    translate(0, -150);//translate object 0 (qua) along x-axis by a <> pixels
    rotate_l(2, 1, 1);//rotate object  2 by 15 degrees around centroid
    //scale(2, 3);//scale obj 2 to twice the size
    scale(2, 2);//scale obj 2 to 1.5x the size
    trigger_clipper();//trigger clipper

end

always #5 clk = ~clk;

task initialize();
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
    @(posedge clk);
endtask

task create(input bit [1:0] typ);
    gmt_op <= 4'h0; //crt
    obj_type <= typ;
    go <= 1'b1;
    @(posedge clk) go <= 1'b0;
    wait(busy == 1'b0);
endtask

task translate(input bit [5:0] num, input bit [15:0] amt);
    obj_num_in <= num;
    v0 <= amt;
    gmt_op <= 4'h4;
    gmt_code[1:0] <= 2'b01;
    go <= 1'b1;
    @(posedge clk) go <= 1'b0;
    wait(busy == 1'b0);
    @(posedge clk);
endtask

task rotate_l(input bit [5:0] num, input bit [2:0] amt, input bit centroid);
    obj_num_in <= num;
    gmt_op <= 4'h6; //rotl
    gmt_code[3] = centroid;//around centroid
    gmt_code[2:0] <= amt; 
    go <= 1'b1;
    @(posedge clk) go <= 1'b0;
    wait(busy == 1'b0);
    @(posedge clk);
endtask

task rotate_r(input bit [5:0] num, input bit [2:0] amt, input bit centroid);
    obj_num_in <= num;
    gmt_op <= 4'h7; //rotr
    gmt_code[3] = centroid;//around centroid
    gmt_code[2:0] <= amt; 
    go <= 1'b1;
    @(posedge clk) go <= 1'b0;
    wait(busy == 1'b0);
    @(posedge clk);
endtask

task scale(input bit [5:0] num, input bit [1:0] amt);
    obj_num_in <= num;
    gmt_op <= 4'h5; //scale
    gmt_code[1:0] <= amt; 
    go <= 1'b1;
    @(posedge clk) go <= 1'b0;
    wait(busy == 1'b0);
    @(posedge clk);
endtask

task trigger_clipper();
    force clipper.refresh_cnt = 1666667;
    @(posedge clk);
    release clipper.refresh_cnt;
endtask

endmodule
