////////////////////////////////////////////////////////////////////////////////
// cpu.v
// Dan Wortmann
//
// Description:
// Top level module housing CPU logic and any interface to VPU and SPART.
////////////////////////////////////////////////////////////////////////////////
module cpu(
    // Inputs //
    clk, rst_n,
    VPU_data_we,
    VPU_rdy,
    VPU_V0,
    VPU_V1,
    VPU_V2,
    VPU_V3,
    VPU_V4,
    VPU_V5,
    VPU_V6,
    VPU_V7,
    VPU_RO,
    // Outputs // TODO: SPART interface
    halt,
    // SPART //
    SPART_we,
    SPART_keys,
    // VPU //
    start_VPU,
    fill_VPU,
    obj_type_VPU,
    obj_color_VPU,
    op_VPU,
    code_VPU,
    obj_num_VPU,
    V0_VPU,
    V1_VPU,
    V2_VPU,
    V3_VPU,
    V4_VPU,
    V5_VPU,
    V6_VPU,
    V7_VPU,
    RO_VPU
);
////////////
// Inputs /
//////////
input               clk, rst_n;
input               VPU_rdy, VPU_data_we;
input               SPART_we;
// [4] 'W' 'w' UP
// [3] 'A' 'a' LEFT
// [2] 'S' 's' DOWN
// [1] 'D' 'd' RIGHT
// [0] 'J' 'j' SELECT/TOGGLE
input       [4:0]   SPART_keys;
input       [15:0]  VPU_V0, VPU_V1, VPU_V2, VPU_V3, VPU_V4, VPU_V5, VPU_V6, VPU_V7, VPU_RO;

/////////////
// Outputs /
///////////
output              halt, start_VPU;
output              fill_VPU;
output      [1:0]   obj_type_VPU;
output      [2:0]   obj_color_VPU;
output      [3:0]   op_VPU;
output      [3:0]   code_VPU;
output      [4:0]   obj_num_VPU;
output      [15:0]  V0_VPU, V1_VPU, V2_VPU, V3_VPU, V4_VPU, V5_VPU, V6_VPU, V7_VPU, RO_VPU;

/////////////////////////////
// Signals/Logic/Registers /
///////////////////////////

///////////////////
// Interconnects /
/////////////////
// IF Outputs //
wire    [15:0]  IF_mem_read_addr;
wire    [15:0]  IF_PC_plus_one;
wire    [15:0]  IF_instr;
// MEMORY Outputs //
wire    [15:0]  MEM_instr;
wire    [15:0]  MEM_read_data;
// DEX Outputs //
wire            DEX_STALL;
wire            DEX_PC_select;
wire    [15:0]  DEX_PC_next;
wire            DEX_VPU_start;
wire    [15:0]  DEX_V0, DEX_V1, DEX_V2, DEX_V3, DEX_V4, DEX_V5, DEX_V6, DEX_V7, DEX_RO;
wire            DEX_alu_to_reg;
wire            DEX_pcr_to_reg;
wire            DEX_mem_to_reg;
wire            DEX_imm_to_reg;
wire            DEX_reg_we_dst_0;
wire            DEX_reg_we_dst_1;
wire            DEX_mem_we;
wire            DEX_mem_re;
wire            DEX_halt;
wire    [4:0]   DEX_dst_addr_0;
wire    [4:0]   DEX_dst_addr_1;
wire    [15:0]  DEX_alu_result;
wire    [15:0]  DEX_PC_return;
wire    [15:0]  DEX_mem_read_addr;
wire    [15:0]  DEX_mem_write_data;
wire    [15:0]  DEX_load_immd;
wire    [15:0]  DEX_reg_data_0;
wire    [15:0]  DEX_reg_data_1;
// MWB Outputs //
wire            MWB_dst_we_0;
wire            MWB_dst_we_1;
wire    [4:0]   MWB_dst_addr_0;
wire    [4:0]   MWB_dst_addr_1;
wire    [15:0]  MWB_reg_0_wrt_data;
wire    [15:0]  MWB_reg_1_wrt_data;

////////////////////////////////////////////////////////////////////////////////
// cpu
////

// Instruction Fetch (Stage 1) /////////////////////////////////////////////////
instruction_fetch IF(
    // Inputs //
    .clk(clk), .rst_n(rst_n), .STALL(DEX_STALL),
    .VPU_start(DEX_VPU_start),
    .IF_PC_next(DEX_PC_next),
    .IF_PC_select(DEX_PC_select),
    .MEM_instr(MEM_instr),
    // Outputs //
    .IF_mem_read_addr(IF_mem_read_addr),
    .IF_PC_plus_one(IF_PC_plus_one),
    .IF_instr(IF_instr)
);

// CPU Memory //
cpu_memory MEMORY(
    // Inputs //
    .clk(clk),
    .re_0(1'b1), .re_1(DEX_mem_re), .we(DEX_mem_we),
    .i_addr(IF_mem_read_addr),
    .d_addr(DEX_mem_read_addr),
    .wrt_data(DEX_mem_write_data),
    // Outputs //
    .instr(MEM_instr),
    .read_data(MEM_read_data)
);

// Instruction Decode + Execute (Stage 2) //////////////////////////////////////
instruction_decode_execute DEX(
    // Inputs //
    .clk(clk), .rst_n(rst_n),
    .instr(IF_instr),
    .pc_plus_1(IF_PC_plus_one),
    .we_VPU(VPU_data_we),
    .VPU_rdy(VPU_rdy),
    .we_CPU_0(MWB_dst_we_0),
    .we_CPU_1(MWB_dst_we_1),
    .wrt_addr_0(MWB_dst_addr_0),
    .wrt_addr_1(MWB_dst_addr_1),
    .wrt_data_0(MWB_reg_0_wrt_data),
    .wrt_data_1(MWB_reg_1_wrt_data),
    .V0_in(VPU_V0),
    .V1_in(VPU_V1),
    .V2_in(VPU_V2),
    .V3_in(VPU_V3),
    .V4_in(VPU_V4),
    .V5_in(VPU_V5),
    .V6_in(VPU_V6),
    .V7_in(VPU_V7),
    .RO_in(VPU_RO),
    .SPART_we(SPART_we),
    .SPART_keys(SPART_keys),
    // Outputs //
    .STALL(DEX_STALL),
    .PC_select(DEX_PC_select),
    .PC_next(DEX_PC_next),
    .VPU_start(DEX_VPU_start),
    .V0_out(DEX_V0),
    .V1_out(DEX_V1),
    .V2_out(DEX_V2),
    .V3_out(DEX_V3),
    .V4_out(DEX_V4),
    .V5_out(DEX_V5),
    .V6_out(DEX_V6),
    .V7_out(DEX_V7),
    .RO_out(DEX_RO),
    .DEX_alu_to_reg(DEX_alu_to_reg),
    .DEX_pcr_to_reg(DEX_pcr_to_reg),
    .DEX_mem_to_reg(DEX_mem_to_reg),
    .DEX_imm_to_reg(DEX_imm_to_reg),
    .DEX_reg_we_dst_0(DEX_reg_we_dst_0),
    .DEX_reg_we_dst_1(DEX_reg_we_dst_1),
    .DEX_mem_we(DEX_mem_we),
    .DEX_mem_re(DEX_mem_re),
    .DEX_halt(DEX_halt),
    .DEX_dst_addr_0(DEX_dst_addr_0),
    .DEX_dst_addr_1(DEX_dst_addr_1),
    .DEX_alu_result(DEX_alu_result),
    .DEX_PC_return(DEX_PC_return),
    .DEX_mem_read_addr(DEX_mem_read_addr),
    .DEX_mem_write_data(DEX_mem_write_data),
    .DEX_load_immd(DEX_load_immd),
    .DEX_reg_data_0(DEX_reg_data_0),
    .DEX_reg_data_1(DEX_reg_data_1)
);

// VPU Interface Register //
VPU_register VPU_data_out(
    // Inputs //
    .clk(clk), .rst_n(rst_n), .STALL(DEX_STALL),
    .VPU_start(DEX_VPU_start),
    .VPU_rdy(VPU_rdy),
    .VPU_instr(IF_instr),
    .V0_in(DEX_V0),
    .V1_in(DEX_V1),
    .V2_in(DEX_V2),
    .V3_in(DEX_V3),
    .V4_in(DEX_V4),
    .V5_in(DEX_V5),
    .V6_in(DEX_V6),
    .V7_in(DEX_V7),
    .RO_in(DEX_RO),
    // Outputs //
    .VPU_start_out(start_VPU),
    .VPU_fill(fill_VPU),
    .VPU_obj_type(obj_type_VPU),
    .VPU_obj_color(obj_color_VPU),
    .VPU_op(op_VPU),
    .VPU_code(code_VPU),
    .VPU_obj_num(obj_num_VPU),
    .V0_out(V0_VPU),
    .V1_out(V1_VPU),
    .V2_out(V2_VPU),
    .V3_out(V3_VPU),
    .V4_out(V4_VPU),
    .V5_out(V5_VPU),
    .V6_out(V6_VPU),
    .V7_out(V7_VPU),
    .RO_out(RO_VPU)
);

// Memory + Write Back (Stage 3) ///////////////////////////////////////////////
memory_writeback MWB(
    // Inputs //
    .MWB_alu_to_reg(DEX_alu_to_reg),
    .MWB_pcr_to_reg(DEX_pcr_to_reg),
    .MWB_mem_to_reg(DEX_mem_to_reg),
    .MWB_imm_to_reg(DEX_imm_to_reg),
    .MWB_reg_we_dst_0(DEX_reg_we_dst_0),
    .MWB_reg_we_dst_1(DEX_reg_we_dst_1),
    .MWB_halt(DEX_halt),
    .MWB_dst_addr_0(DEX_dst_addr_0),
    .MWB_dst_addr_1(DEX_dst_addr_1),
    .MWB_alu_result(DEX_alu_result),
    .MWB_PC_return(DEX_PC_return),
    .MWB_load_immd(DEX_load_immd),
    .MWB_reg_data_0(DEX_reg_data_0),
    .MWB_reg_data_1(DEX_reg_data_1),
    .MEM_rdata(MEM_read_data),
    // Outputs //
    .dst_we_0(MWB_dst_we_0),
    .dst_we_1(MWB_dst_we_1),
    .dst_addr_0(MWB_dst_addr_0),
    .dst_addr_1(MWB_dst_addr_1),
    .reg_0_wrt_data(MWB_reg_0_wrt_data),
    .reg_1_wrt_data(MWB_reg_1_wrt_data)
);

endmodule
