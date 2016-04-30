////////////////////////////////////////////////////////////////////////////////
// memory_writeback.v
// Dan Wortmann
//
// Description:
// CPU stage which handles write back data from memory, registers, and immediate
// values passed in from the DEX phase. Selects the destination targets and data
////////////////////////////////////////////////////////////////////////////////
module memory_writeback(
    // Inputs //
    MWB_alu_to_reg,
    MWB_pcr_to_reg,
    MWB_mem_to_reg,
    MWB_imm_to_reg,
    MWB_reg_we_dst_0,
    MWB_reg_we_dst_1,
    MWB_halt,
    MWB_dst_addr_0,
    MWB_dst_addr_1,
    MWB_alu_result,
    MWB_PC_return,
    MWB_load_immd,
    MWB_reg_data_0,
    MWB_reg_data_1,
    MEM_rdata,
    // Outputs //
    dst_we_0,
    dst_we_1,
    dst_addr_0,
    dst_addr_1,
    reg_0_wrt_data,
    reg_1_wrt_data
);
////////////
// Inputs /
//////////
// Pipeline signals
// From DEX //
input           MWB_alu_to_reg;
input           MWB_pcr_to_reg;
input           MWB_mem_to_reg;
input           MWB_imm_to_reg;
input           MWB_reg_we_dst_0;
input           MWB_reg_we_dst_1;
input           MWB_halt;
input   [4:0]   MWB_dst_addr_0;
input   [4:0]   MWB_dst_addr_1;
input   [15:0]  MWB_alu_result;
input   [15:0]  MWB_PC_return;
input   [15:0]  MWB_load_immd;
input   [15:0]  MWB_reg_data_0;
input   [15:0]  MWB_reg_data_1;
// Memory Interface //
input   [15:0]  MEM_rdata;

/////////////
// Outputs /
///////////
output          dst_we_0;
output          dst_we_1;
output  [4:0]   dst_addr_0;
output  [4:0]   dst_addr_1;
output  [15:0]  reg_0_wrt_data;
output  [15:0]  reg_1_wrt_data;

/////////////////////////////
// Signals/Logic/Registers /
///////////////////////////

///////////////////
// Interconnects /
/////////////////

////////////////////////////////////////////////////////////////////////////////
// memory_writeback
////

// Write Back Logic //
assign dst_we_0 = MWB_reg_we_dst_0;
assign dst_addr_0 = MWB_dst_addr_0;
assign reg_0_wrt_data = (MWB_mem_to_reg) ? MEM_rdata:       // ST/LDR
                        (MWB_alu_to_reg) ? MWB_alu_result:  // Any ALU instr
                        (MWB_imm_to_reg) ? MWB_load_immd:   // LDU/LDL
                                           MWB_reg_data_1;  // SWAP

assign dst_we_1 = MWB_reg_we_dst_1;
assign dst_addr_1 = MWB_dst_addr_1;
assign reg_1_wrt_data = (MWB_pcr_to_reg) ? MWB_PC_return:   // J/JI
                                           MWB_reg_data_0;  // SWAP

endmodule
