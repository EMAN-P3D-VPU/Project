////////////////////////////////////////////////////////////////////////////////
// instruction_decode_execute_tb.sv
// Dan Wortmann
//
// Description:
// 
////////////////////////////////////////////////////////////////////////////////
module instruction_decode_execute_tb();
////////////
// Inputs /
//////////
logic clk, rst_n;

/////////////
// Outputs /
///////////
wire    		DEX_STALL;
wire    		DEX_PC_select;
wire    [15:0]	DEX_PC_next;
wire    		DEX_VPU_start;
wire    [15:0]	DEX_V0, DEX_V1, DEX_V2, DEX_V3, DEX_V4, DEX_V5, DEX_V6, DEX_V7, DEX_RO;
wire    		DEX_alu_to_reg;
wire    		DEX_pcr_to_reg;
wire    		DEX_mem_to_reg;
wire    		DEX_imm_to_reg;
wire    		DEX_reg_we_dst_0;
wire    		DEX_reg_we_dst_1;
wire    		DEX_mem_we;
wire    		DEX_mem_re;
wire    		DEX_halt;
wire    [4:0]	DEX_dst_addr_0;
wire    [4:0]	DEX_dst_addr_1;
wire    [15:0]	DEX_alu_result;
wire    [15:0]	DEX_PC_return;
wire    [15:0]	DEX_mem_read_addr;
wire    [15:0]	DEX_mem_write_data;
wire    [15:0]	DEX_load_immd;
wire    [15:0]	DEX_reg_data_0;
wire    [15:0]	DEX_reg_data_1;

///////////////////
// Interconnects /
/////////////////

////////////////////
// Instantiations /
//////////////////
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

////////////////////////////////////////////////////////////////////////////////
// instruction_decode_execute_tb
////

// Clock //
always
	#2 clk = ~clk;

// Fail Safe Stop //
initial
	#1000 $stop;

// Main Test Loop //
initial begin
	clk = 0;
	rst_n = 0;
	$display("rst assert\n");
	@(negedge clk) rst_n = 1;
	$display("rst deassert\n");


	repeat(2) @(posedge clk);
	$stop;
end

endmodule
