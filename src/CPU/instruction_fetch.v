////////////////////////////////////////////////////////////////////////////////
// instruction_fetch.v
// Dan Wortmann
//
// Description:
// Fetch stage of the CPU which handles the Program Counter (PC) and the data
// read from memory pointed to by PC.
////////////////////////////////////////////////////////////////////////////////
module instruction_fetch(
    // Inputs //
    clk, rst_n, STALL,
    VPU_start,
    IF_PC_next,
    IF_PC_select,
    MEM_instr,
    // Outputs //
    IF_mem_read_addr,
    IF_PC_plus_one,
    IF_instr
);
////////////
// Inputs /
//////////
input           clk, rst_n, STALL;
// From DEX //
input           VPU_start;
input           IF_PC_select;
input   [15:0]  IF_PC_next;
// Memory Interface //
input   [15:0]  MEM_instr;

/////////////
// Outputs /
///////////
output      [15:0]  IF_mem_read_addr;
output  reg [15:0]  IF_PC_plus_one;
output  reg [15:0]  IF_instr;

/////////////////////////////
// Signals/Logic/Registers /
///////////////////////////
reg     [15:0]  PC;

///////////////////
// Interconnects /
/////////////////
wire    [15:0]  PC_plus_one;
wire    [15:0]  PC_next;

////////////////////////////////////////////////////////////////////////////////
// instruction_fetch
////

// PC Logic //
assign PC_plus_one = PC + 1;

assign PC_next = (IF_PC_select) ? IF_PC_next:
                                  PC_plus_one;

always@(posedge clk)begin
    if(!rst_n)
        PC <= 16'h0000;
    else if(VPU_start)
        PC <= PC;
    else if(~STALL | IF_PC_select)
        PC <= PC_next;
    else
        PC <= PC;
end

// To Instr Memory //
assign IF_mem_read_addr = PC;

// Pipeline Flip-Flop //--------------------------------------------------------
// Instruction //
always@(posedge clk)begin
    if(!rst_n)
        IF_instr <= 16'h7800;
    else if(VPU_start | IF_PC_select)
        IF_instr <= 16'h7800;
    else if(~STALL)
        IF_instr <= MEM_instr;
    else
        IF_instr <= IF_instr;
end

// PC Next //
always@(posedge clk)begin
    if(!rst_n)
        IF_PC_plus_one <= 16'h0000;
    else if(~STALL)
        IF_PC_plus_one <= PC_plus_one;
    else
        IF_PC_plus_one <= IF_PC_plus_one;
end

endmodule
