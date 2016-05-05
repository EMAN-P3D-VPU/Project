////////////////////////////////////////////////////////////////////////////////
// cpu_memory.v
// Dan Wortmann
//
// Description:
// 2 - Read Ports with enable
// 1 - Write Port
////////////////////////////////////////////////////////////////////////////////
module cpu_memory(
    // Inputs //
    clk,
    re_0, re_1, we,
    i_addr,
    d_addr,
    wrt_data,
    // Outputs //
    instr,
    read_data
);
////////////
// Inputs /
//////////
input           clk;
input           re_0, re_1, we;
input   [15:0]  i_addr;
input   [15:0]  d_addr;
input   [15:0]  wrt_data;

/////////////
// Outputs /
///////////
output  [15:0]  instr;
output  [15:0]  read_data;

/////////////////////////////
// Signals/Logic/Registers /
///////////////////////////
reg [15:0]  RAM [511:0];

///////////////////
// Interconnects /
/////////////////

////////////////////////////////////////////////////////////////////////////////
// cpu_memory (Xilinx User Guide)
////
//HACK//
initial begin
    //$readmemh("CPU_Instruction_Files/CPU_instr_1.hex", RAM);
    //$readmemh("/userspace/p/procek/554_eMan_Final/Project/CPU/CPU_Instruction_Files/CPU_instr_1.hex", RAM);
    //$readmemh("../Assembler/test_instr_01.out", RAM); // RAM must be >= 512
    //$readmemh("/userspace/d/dsingh/ece554/EMAN/Assembler/test_instr_01.out", RAM); // RAM must be >= 512
	 $readmemh("CPU_Instruction_Files/Eman_bg.hex", RAM);
end


// Write //
always@(posedge clk)begin
    if(we)
        RAM[d_addr] <= wrt_data;
    // TODO:
    // Xilinx does read enable here as well...but in the pipeline its not important
    // Could do it for power saving? Ill look more if I use an IP block too
end

// Read //
assign instr     = RAM[i_addr];
assign read_data = RAM[d_addr];

// IP Block? //

endmodule
