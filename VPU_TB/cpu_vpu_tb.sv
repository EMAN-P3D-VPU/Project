`include "timescale.v"
module cpu_vpu_tb();
////////////
// Inputs /
//////////
reg			clk, rst_n;
reg			VPU_rdy, VPU_data_we;
logic			SPART_we;
logic	[3:0]	SPART_keys;
reg	[15:0]	VPU_V0, VPU_V1, VPU_V2, VPU_V3, VPU_V4, VPU_V5, VPU_V6, VPU_V7, VPU_RO;

//////////////////////
// CPU-VPU Interface /
//////////////////////
wire            halt, start_VPU;
wire            fill_VPU;
wire    [1:0]	obj_type_VPU;
wire    [2:0]	obj_color_VPU;
wire    [3:0]	op_VPU;
wire    [3:0]	code_VPU;
wire    [4:0]	obj_num_VPU;
wire    [15:0]	V0_VPU, V1_VPU, V2_VPU, V3_VPU, V4_VPU, V5_VPU, V6_VPU, V7_VPU, RO_VPU;

///////////////////
// Interconnects /
/////////////////
//CPU inputs
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

////////////////////
// Instantiations /
//////////////////
cpu CPU(
    // Inputs //
    .clk(clk), .rst_n(rst_n), .VPU_data_we(VPU_data_we), .VPU_rdy(VPU_rdy),
    .VPU_V0(VPU_V0), .VPU_V1(VPU_V1), .VPU_V2(VPU_V2), .VPU_V3(VPU_V3), 
    .VPU_V4(VPU_V4), .VPU_V5(VPU_V5), .VPU_V6(VPU_V6), .VPU_V7(VPU_V7), .VPU_RO(VPU_RO),
    // Outputs // TODO: SPART interface
    .halt(halt),
    // SPART //
    .SPART_we(SPART_we), .SPART_keys(SPART_keys), // VPU //
    .start_VPU(start_VPU), .fill_VPU(fill_VPU), .obj_type_VPU(obj_type_VPU),
    .obj_color_VPU(obj_color_VPU), .op_VPU(op_VPU), .code_VPU(code_VPU), .obj_num_VPU(obj_num_VPU),
    .V0_VPU(V0_VPU), .V1_VPU(V1_VPU), .V2_VPU(V2_VPU), .V3_VPU(V3_VPU), .V4_VPU(V4_VPU), 
    .V5_VPU(V5_VPU), .V6_VPU(V6_VPU), .V7_VPU(V7_VPU), .RO_VPU(RO_VPU)
);

assign VPU_rdy = !busy;

matrix_unit mat(.clk(clk), .rst_n(rst_n), .go(start_VPU), .v0(V0_VPU), .v1(V1_VPU), .v2(V2_VPU), .v3(V3_VPU), 
                .v4(V4_VPU), .v5(V5_VPU), .v6(V6_VPU), .v7(V7_VPU),
                .obj_type(obj_type_VPU), .obj_color({5'b0,obj_color_VPU}), .obj_num_in(obj_num_VPU),
                .gmt_op(op_VPU), .gmt_code(code_VPU), .obj_in(mat_obj_out), .addr_vld(addr_vld), 
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



////////////////////////////////////////////////////////////////////////////////
// cpu_tb
////

// Clock //
always
	#5 clk = ~clk;

// Fill Memory for Software Tests //
initial begin
    $readmemh("/userspace/d/dsingh/ece554/EMAN/VPU_TB/CPU_instr_1.hex", CPU.MEMORY.RAM);
end

initial begin
    #10000; //after 10us, trigger clipper
    trigger_clipper();//trigger clipper
end


// Main Test Loop //
initial begin
	clk = 0;
	rst_n = 0;
    force clipper.refresh_cnt = 0;
	// SPART //
    SPART_we     = 1'h0;
    SPART_keys   = 3'h0;
	// VPU //
    //VPU_rdy      = 1'h1;	// CPU stalls when VPU is not ready!
    VPU_data_we  = 1'h1;
    VPU_V0       = 16'd100;
    VPU_V1       = 16'd100;
    VPU_V2       = 16'd100;
    VPU_V3       = 16'd200;
    VPU_V4       = 16'd200;
    VPU_V5       = 16'd200;
    VPU_V6       = 16'd200;
    VPU_V7       = 16'd1000;
    VPU_RO       = 16'h0;
    $display("rst assert\n");
    @(negedge clk) rst_n = 1;
    VPU_data_we  = 1'h0;
    $display("rst deassert\n");
end

task trigger_clipper();
    force clipper.refresh_cnt = 1666667;
    @(posedge clk);
    release clipper.refresh_cnt;
endtask


endmodule
