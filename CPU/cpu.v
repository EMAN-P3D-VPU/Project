////////////////////////////////////////////////////////////////////////////////
// cpu.v
// Dan Wortmann
//
// Description:
// 
////////////////////////////////////////////////////////////////////////////////
module cpu(
	// Inputs //
	clk, rst_n,
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
	start_VPU,
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
input				clk, rst_n;
input				VPU_rdy;
input		[15:0]	VPU_V0, VPU_V1, VPU_V2, VPU_V3, VPU_V4, VPU_V5, VPU_V6, VPU_V7, VPU_RO;

/////////////
// Outputs /
///////////
output				halt, start_VPU;
output		[15:0]	V0_VPU, V1_VPU, V2_VPU, V3_VPU, V4_VPU, V5_VPU, V6_VPU, V7_VPU, RO_VPU;

/////////////////////////////
// Signals/Logic/Registers /
///////////////////////////

///////////////////
// Interconnects /
/////////////////

////////////////////////////////////////////////////////////////////////////////
// cpu
////

// Instruction Fetch (Stage 1) /////////////////////////////////////////////////
instruction_fetch IF(
    // Inputs //
    .clk(clk), .rst_n(rst_n), .STALL(),
    .IF_PC_next(),
    .IF_PC_select(),
    .MEM_instr(),
    // Outputs //
    .IF_mem_read_addr(),
    .IF_PC_plus_one(),
    .IF_instr()
);

// CPU Memory //
cpu_memory MEMORY(
    // Inputs //
	.clk(clk),
    .re_0(), .re_1(), .we(),
    .i_addr(),
    .d_addr(),
    .wrt_data(),
    // Outputs //
    .instr(),
    .read_data()
);

// Instruction Decode + Execute (Stage 2) //////////////////////////////////////
instruction_decode_execute DEX(
	// Inputs //
	.clk(clk), .rst_n(),
    .instr(),
    .pc_plus_1(),
    .we_VPU(),
    .VPU_rdy(VPU_rdy),
    .we_CPU_0(),
    .we_CPU_1(),
    .wrt_addr_0(),
    .wrt_addr_1(),
    .wrt_data_0(),
    .wrt_data_1(),
    .V0_in(VPU_V0),
    .V1_in(VPU_V1),
    .V2_in(VPU_V2),
    .V3_in(VPU_V3),
    .V4_in(VPU_V4),
    .V5_in(VPU_V5),
    .V6_in(VPU_V6),
    .V7_in(VPU_V7),
    .RO_in(VPU_RO),
    // Outputs //
    .STALL(),
    .PC_select(),
    .PC_next(),
    .VPU_start(),
    .V0_out(),
    .V1_out(),
    .V2_out(),
    .V3_out(),
    .V4_out(),
    .V5_out(),
    .V6_out(),
    .V7_out(),
    .RO_out(),
    .DEX_alu_to_reg(),
    .DEX_pcr_to_reg(),
    .DEX_mem_to_reg(),
	.DEX_imm_to_reg(),
    .DEX_reg_we_dst_0(),
    .DEX_reg_we_dst_1(),
    .DEX_mem_we(),
    .DEX_mem_re(),
    .DEX_halt(),
    .DEX_dst_addr_0(),
    .DEX_dst_addr_1(),
    .DEX_alu_result(),
    .DEX_PC_return(),
    .DEX_mem_read_addr(),
    .DEX_mem_write_data(),
    .DEX_load_immd(),
	.DEX_reg_data_0(),
	.DEX_reg_data_1()
);

// VPU Interface Register //
VPU_register VPU_data_out(
    // Inputs //
    .clk(clk), .rst_n(rst_n), .STALL(),
    .VPU_start(),
    .V0_in(),
    .V1_in(),
    .V2_in(),
    .V3_in(),
    .V4_in(),
    .V5_in(),
    .V6_in(),
    .V7_in(),
    .RO_in(),
    // Outputs //
    .VPU_start_out(start_VPU),
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
    .MWB_alu_to_reg(),
    .MWB_pcr_to_reg(),
    .MWB_mem_to_reg(),
    .MWB_imm_to_reg(),
    .MWB_reg_we_dst_0(),
    .MWB_reg_we_dst_1(),
    .MWB_halt(),
    .MWB_dst_addr_0(),
    .MWB_dst_addr_1(),
    .MWB_alu_result(),
    .MWB_PC_return(),
    .MWB_load_immd(),
    .MWB_reg_data_0(),
    .MWB_reg_data_1(),
    .MEM_rdata(),
    // Outputs //
    .dst_we_0(),
    .dst_we_1(),
    .dst_addr_0(),
    .dst_addr_1(),
    .reg_0_wrt_data(),
    .reg_1_wrt_data()
);

endmodule
