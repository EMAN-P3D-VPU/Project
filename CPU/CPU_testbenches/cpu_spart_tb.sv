////////////////////////////////////////////////////////////////////////////////
// cpu_spart_tb.sv
// Dan Wortmann
//
// Description:
// Read instruction files for software testbench and visual inspection. Any
// code specific tests should use this as a template to have test specific
// self checking code.
////////////////////////////////////////////////////////////////////////////////
module cpu_spart_tb();
////////////
// Inputs /
//////////
logic           clk, rst_n;
logic           VPU_rdy, VPU_data_we;
logic           SPART_we;
logic   [12:0]  SPART_keys;
logic   [15:0]  VPU_V0, VPU_V1, VPU_V2, VPU_V3, VPU_V4, VPU_V5, VPU_V6, VPU_V7, VPU_RO;

/////////////
// Outputs /
///////////
wire            halt, start_VPU;
wire            fill_VPU;
wire    [1:0]   obj_type_VPU;
wire    [2:0]   obj_color_VPU;
wire    [3:0]   op_VPU;
wire    [3:0]   code_VPU;
wire    [4:0]   obj_num_VPU;
wire    [15:0]  V0_VPU, V1_VPU, V2_VPU, V3_VPU, V4_VPU, V5_VPU, V6_VPU, V7_VPU, RO_VPU;

///////////////////
// Interconnects /
/////////////////

////////////////////
// Instantiations /
//////////////////
cpu CPU(
    // Inputs //
    .clk(clk), .rst_n(rst_n),
    .VPU_data_we(VPU_data_we),
    .VPU_rdy(VPU_rdy),
    .VPU_V0(VPU_V0),
    .VPU_V1(VPU_V1),
    .VPU_V2(VPU_V2),
    .VPU_V3(VPU_V3),
    .VPU_V4(VPU_V4),
    .VPU_V5(VPU_V5),
    .VPU_V6(VPU_V6),
    .VPU_V7(VPU_V7),
    .VPU_RO(VPU_RO),
    // Outputs // TODO: SPART interface
    .halt(halt),
    // SPART //
    .SPART_we(SPART_we),
    .SPART_keys(SPART_keys),
    // VPU //
    .start_VPU(start_VPU),
    .fill_VPU(fill_VPU),
    .obj_type_VPU(obj_type_VPU),
    .obj_color_VPU(obj_color_VPU),
    .op_VPU(op_VPU),
    .code_VPU(code_VPU),
    .obj_num_VPU(obj_num_VPU),
    .V0_VPU(V0_VPU),
    .V1_VPU(V1_VPU),
    .V2_VPU(V2_VPU),
    .V3_VPU(V3_VPU),
    .V4_VPU(V4_VPU),
    .V5_VPU(V5_VPU),
    .V6_VPU(V6_VPU),
    .V7_VPU(V7_VPU),
    .RO_VPU(RO_VPU)
);

////////////////////////////////////////////////////////////////////////////////
// cpu_tb
////

// Clock //
always
    #2 clk = ~clk;

always@(posedge clk)
	if(CPU.IF.IF_instr == 16'h6F9E)
		SPART_we = 1;
	else
		SPART_we = 0;

always@(posedge clk)
    if(CPU.IF.IF_instr == 16'h6F9E)
	if(SPART_keys == 13'h0000)
		SPART_keys = 13'h1000;
	else
		SPART_keys = SPART_keys >> 1;

// Fail Safe Stop //
initial
    #1000000 $stop;

// Fill Memory for Software Tests //
initial
  $readmemh("CPU_Instruction_Files/P3D_Animation_Demo.txt", CPU.MEMORY.RAM);

// Main Test Loop //
initial begin
    clk = 0;
    rst_n = 0;
    // SPART //
    SPART_we     = 1'h0;
    SPART_keys   = 5'h10;
    // VPU //
    VPU_rdy      = 1'h1;    // CPU stalls when VPU is not ready!
    VPU_data_we  = 1'h1;
    VPU_V0       = 16'h0;
    VPU_V1       = 16'h0;
    VPU_V2       = 16'h0;
    VPU_V3       = 16'h0;
    VPU_V4       = 16'h0;
    VPU_V5       = 16'h0;
    VPU_V6       = 16'h0;
    VPU_V7       = 16'h0;
    VPU_RO       = 16'h0;
    $display("rst assert\n");
    @(negedge clk) rst_n = 1;
    VPU_data_we  = 1'h0;
    $display("rst deassert\n");


    repeat(1000000) @(posedge clk);
    $stop;
end

endmodule
