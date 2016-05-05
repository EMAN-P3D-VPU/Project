`include "timescale.v"

module vpu_tb();

reg clk, rst_n;
//CPU inputs
reg [15:0] v0, v1, v2, v3, v4, v5, v6, v7;
reg [1:0] obj_type;
reg [7:0] obj_color;
reg [4:0] obj_num_in;
reg [3:0] gmt_op, gmt_code;
reg go;
wire busy, obj_mem_full_out;
wire [4:0] lst_stored_obj_out;
//matrix-obj_unit interface
wire crt_obj, del_obj, del_all, ref_addr, changed_in, obj_mem_full_in, addr_vld;
wire [4:0] obj_num_out, lst_stored_obj_in;
//matrix-mem_unit interface
wire [143:0] mat_obj_in, mat_obj_out;
wire mat_rd_en, mat_wr_en, loadback;
//obj-mem interface
wire [4:0] mat_addr;
//clipping-matrix
wire writing, reading, changed, clr_changed;
//clipping-mem
wire clip_read_en;
wire [4:0] clip_addr;
wire [143:0] clip_obj_out;
//clipping-obj
wire [31:0] obj_map;
//clipping-raster

matrix_unit mat(.clk(clk), .rst_n(rst_n), .go(go), .v0(v0), .v1(v1), .v2(v2), .v3(v3), .v4(v4), .v5(v5), .v6(v6), .v7(v7),
                .obj_type(obj_type), .obj_color(obj_color), .obj_num_in(obj_num_in),
                .gmt_op(gmt_op), .gmt_code(gmt_code), .obj_in(mat_obj_out), .addr_vld(addr_vld), 
                .lst_stored_obj_in(lst_stored_obj_in), .lst_stored_obj_vld(lst_stored_obj_vld),
                .obj_mem_full_in(obj_mem_full_in), .clr_changed(clr_changed), .reading(reading),
                .busy(busy), .lst_stored_obj_out(lst_stored_obj_out), .obj_mem_full_out(obj_mem_full_out), 
                .crt_obj(crt_obj), .del_obj(del_obj), .del_all(del_all), .ref_addr(ref_addr),
                .obj_num_out(obj_num_out), .changed(changed_in), .obj_out(mat_obj_in), .rd_en(mat_rd_en), .wr_en(mat_wr_en),
                .loadback(loadback), .writing(writing));

video_mem_unit mem_unit(.clk(clk), .rst_n(rst_n), .mat_addr(mat_addr), .mat_obj_in(mat_obj_in), .loadback(loadback),
                .mat_rd_en(mat_rd_en), .mat_wr_en(mat_wr_en), .mat_obj_out(mat_obj_out),
                .clip_addr(clip_addr), .clip_rd_en(clip_rd_en), .clip_obj_out(clip_obj_out));

object_unit obj(.clk(clk), .rst_n(rst_n), .crt_obj(crt_obj), .del_obj(del_obj), .del_all(del_all),
                .ref_addr(ref_addr), .obj_num(obj_num_out), .changed_in(changed_in), .addr(mat_addr),
                .addr_vld(addr_vld), .lst_stored_obj(lst_stored_obj_in), .lst_stored_obj_vld(lst_stored_obj_vld),
                .obj_mem_full(obj_mem_full_in), .obj_map(obj_map), .changed_out(changed));

clipping_unit clipper(.clk(clk), .rst_n(rst_n), .obj_map(obj_map), .obj(clip_obj_out), .raster_ready(raster_ready),
                .writing(busy), .changed(changed), .addr(clip_addr), .read_en(clip_rd_en), .clr_changed(clr_changed), 
                .reading(reading));


initial begin
    initialize(); //(100, 100), (100,200), (200,200), (200, 100)
    //create three objects
    create(2'h3); //obj0 - quad
    create(2'h2); //obj1 - tri
    create(2'h1); //obj2 - line
    //TEST 1
    //translate(1, 500, 1);//translate object 1 (tri) along x-axis by a <> pixels
    //rotate_l(0, 4, 1); //rotate object  0 by 60 degrees around centroid
    //translate(0, -150, 1);//translate object 0 (qua) along x-axis by a <> pixels
    //rotate_l(2, 1, 1);//rotate object  2 by 15 degrees around centroid
    ////scale(2, 3);//scale obj 2 to twice the size
    //scale(2, 2);//scale obj 2 to 1.5x the size
    //TEST2
    rotate_r(0, 2, 1); //30 deg around the centroid
    translate(1, 300, 2); //translate by 300 along y
    delete(1); //del obj1
    create(2); //crt tri - as obj1
    translate(0, -150, 3);// translate by -150 on both x and y
    translate_one(0, 50, 1, 1); //translate pt 2 (0-based) by 50 along x
    rotate_l(1, 4, 0); //by 60 deg around origin
    //rotate_r(2, 0, 0); //rotate by 3 deg around origin
    rotate_r(2, 3, 0); //rotate by 45 deg around origin
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
    force clipper.refresh_cnt = 0;
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
    @(posedge clk);
endtask

task delete(input bit [4:0] num);
    gmt_op <= 4'h1; //del
    obj_num_in <= num;
    go <= 1'b1;
    @(posedge clk) go <= 1'b0;
    wait(busy == 1'b0);
    @(posedge clk);
endtask

task translate(input bit [5:0] num, input bit [15:0] amt, input bit [1:0] xy);
    obj_num_in <= num;
    v0 <= amt;
    gmt_op <= 4'h4;
    gmt_code[1:0] <= xy;
    go <= 1'b1;
    @(posedge clk) go <= 1'b0;
    wait(busy == 1'b0);
    @(posedge clk);
endtask

task translate_one(input bit [5:0] num, input bit [15:0] amt, input bit [1:0] pt, input bit [1:0] xy);
    obj_num_in <= num;
    v0 <= amt;
    gmt_op <= 4'h3;
    gmt_code[3:2] <= pt;
    gmt_code[1:0] <= xy;
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
