////////////////////////////////////////////////////////////////////////////////
// instruction_decode_execute.v
// Dan Wortmann
//
// Description:
// The workhorse phase of the CPU pipeline. In this phase we decode the
// instruction and set CPU control signal corresponding to the opcode. This
// phase also houses the register file which is read/written when needed.
// Finally, the branch and jump control logic is also done here by adding PC
// values to immediates or register contents to produce new PC's.
////////////////////////////////////////////////////////////////////////////////
module instruction_decode_execute(
    // Inputs //
    clk, rst_n, halt,
    instr,
    pc_plus_1,
    we_VPU,
    VPU_rdy,
    we_CPU_0,
    we_CPU_1,
    wrt_addr_0,
    wrt_addr_1,
    wrt_data_0,
    wrt_data_1,
    V0_in, V1_in, V2_in, V3_in, V4_in, V5_in, V6_in, V7_in, RO_in,
    SPART_we,
    SPART_keys,
    // Outputs //
    STALL,
    PC_select,
    PC_next,
    VPU_start,
    V0_out, V1_out, V2_out, V3_out, V4_out, V5_out, V6_out, V7_out, RO_out,
    DEX_alu_to_reg,
    DEX_pcr_to_reg,
    DEX_mem_to_reg,
    DEX_imm_to_reg,
    DEX_reg_we_dst_0,
    DEX_reg_we_dst_1,
    DEX_mem_we,
    DEX_mem_re,
    DEX_halt,
    DEX_dst_addr_0,
    DEX_dst_addr_1,
    DEX_alu_result,
    DEX_PC_return,
    DEX_mem_read_addr,
    DEX_mem_write_data,
    DEX_load_immd,
    DEX_reg_data_0,
    DEX_reg_data_1
);
////////////
// Inputs /
//////////
input           clk, rst_n;
input   [15:0]  instr;
input   [15:0]  pc_plus_1;
input           we_VPU;
input           VPU_rdy;
input           we_CPU_0;
input           we_CPU_1;
input           SPART_we;
input   [12:0]  SPART_keys;
input   [4:0]   wrt_addr_0;
input   [4:0]   wrt_addr_1;
input   [15:0]  wrt_data_0;
input   [15:0]  wrt_data_1;
input   [15:0]  V0_in, V1_in, V2_in, V3_in, V4_in, V5_in, V6_in, V7_in, RO_in;

/////////////
// Outputs /
///////////
output              STALL;  // Main STALL signal for pipeline
output              halt;
output              PC_select;
output      [15:0]  PC_next;
// To VPU Pipeline Register //
output              VPU_start;
output  [15:0]      V0_out, V1_out, V2_out, V3_out, V4_out, V5_out, V6_out, V7_out, RO_out;
// Pipeline Register DEX //
output  reg         DEX_alu_to_reg;
output  reg         DEX_pcr_to_reg;
output  reg         DEX_mem_to_reg;
output  reg         DEX_imm_to_reg;
output  reg         DEX_reg_we_dst_0;
output  reg         DEX_reg_we_dst_1;
output  reg         DEX_mem_we;
output  reg         DEX_mem_re;
output  reg         DEX_halt;
output  reg [4:0]   DEX_dst_addr_0;
output  reg [4:0]   DEX_dst_addr_1;
output  reg [15:0]  DEX_alu_result;
output  reg [15:0]  DEX_PC_return;
output  reg [15:0]  DEX_mem_read_addr;
output  reg [15:0]  DEX_mem_write_data;
output  reg [15:0]  DEX_load_immd;
output  reg [15:0]  DEX_reg_data_0;
output  reg [15:0]  DEX_reg_data_1;

/////////////////////////////
// Signals/Logic/Registers /
///////////////////////////
reg [3:0]   FLAGS; // WE, Z, N, V -> flags write to RF on next cycle of ALU operation

///////////////////
// Interconnects /
/////////////////
wire            STALL_control, BUBBLE_hazard;
wire            X_bit;
wire            ldu, ldl;
wire            alu_flags_we, Z, N, V;
wire            Z_we, N_we, V_we;
wire            branch, jump;
wire            add_immd, jump_immd;
wire            alu_to_reg;
wire            pcr_to_reg;
wire            mem_to_reg;
wire            reg_we_dst_0, reg_we_dst_1;
wire            reg_read_0, reg_read_1;
wire            mem_we, mem_re;
wire            halt;
wire    [2:0]   ALU_op;
wire    [2:0]   condition_code;
wire    [3:0]   shamt;
wire    [4:0]   opcode;
wire    [4:0]   reg_addr_0, dst_addr_0;
wire    [4:0]   reg_addr_1, dst_addr_1;
wire    [5:0]   alu_flags;
wire    [10:0]  wait_time;
wire    [15:0]  reg_data_0;
wire    [15:0]  reg_data_1;
wire    [15:0]  alu_op_0;
wire    [15:0]  alu_op_1;
wire    [15:0]  alu_result;
wire    [15:0]  branch_offset;
wire    [15:0]  jump_offset;
wire    [15:0]  PC_return;
wire    [15:0]  mem_read_addr;
wire    [15:0]  mem_write_data;
wire    [15:0]  load_immd;

////////////////////////////////////////////////////////////////////////////////
// instruction_decode_execute
////

// Stall (VPU + Hazard + WAIT) //
assign STALL = STALL_control | BUBBLE_hazard;

// Hazard //
// TODO: Some instructions may have a matching address but aren't reading the
// regfile...we'd need to add 'read reg 0/1' signals in control or just take
// the stall penalty occasionally.
assign BUBBLE_hazard =  ((reg_addr_0 == DEX_dst_addr_0) & we_CPU_0 & reg_read_0) |
                        ((reg_addr_1 == DEX_dst_addr_1) & we_CPU_1 & reg_read_1);

// Control //
assign X_bit = instr[10];
assign opcode = instr[15:11];
assign wait_time = instr[10:0];

control_unit control(
    // Inputs //
    .clk(clk), .rst_n(rst_n),
    .opcode(opcode),
    .x_bit(X_bit),
    .wait_time(wait_time),
    .VPU_rdy(VPU_rdy),
    // Output //
    .STALL_control(STALL_control),
    .VPU_start(VPU_start),
    .alu_to_reg(alu_to_reg),
    .pcr_to_reg(pcr_to_reg),
    .mem_to_reg(mem_to_reg),
    .reg_we_dst_0(reg_we_dst_0),
    .reg_we_dst_1(reg_we_dst_1),
    .reg_read_0(reg_read_0),
    .reg_read_1(reg_read_1),
    .mem_we(mem_we),
    .mem_re(mem_re),
    .add_immd(add_immd),
    .jump_immd(jump_immd),
    .ldu(ldu), .ldl(ldl),
    .branch(branch),
    .jump(jump),
    .Z_we(Z_we), .N_we(N_we), .V_we(V_we),
    .halt(halt)
);

// Register File //
assign  reg_addr_0  =   (ldu | ldl) ? {2'b00, instr[10:8]} : instr[9:5];
assign  reg_addr_1  =    instr[4:0];
assign  mem_read_addr = reg_data_1;
assign  mem_write_data = reg_data_0;

register_file regfile(
    // Inputs //
    .clk(clk), .rst_n(rst_n),
    .reg_addr_0(reg_addr_0),
    .reg_addr_1(reg_addr_1),
    .wrt_addr_0(wrt_addr_0),
    .wrt_addr_1(wrt_addr_1),
    .cpu_flags(FLAGS[2:0]),
    .cpu_flags_we(FLAGS[3]),
    .we_VPU(we_VPU),
    .wrt_data_0(wrt_data_0),
    .wrt_data_1(wrt_data_1),
    .we_CPU_0(we_CPU_0),
    .we_CPU_1(we_CPU_1),
    .wrt_V0(V0_in),
    .wrt_V1(V1_in),
    .wrt_V2(V2_in),
    .wrt_V3(V3_in),
    .wrt_V4(V4_in),
    .wrt_V5(V5_in),
    .wrt_V6(V6_in),
    .wrt_V7(V7_in),
    .return_obj(RO_in),
    .SPART_we(SPART_we),
    .SPART_keys(SPART_keys),
    // Outputs //
    .reg_data_0(reg_data_0),
    .reg_data_1(reg_data_1),
    .read_RO(RO_out),
    .read_V0(V0_out),
    .read_V1(V1_out),
    .read_V2(V2_out),
    .read_V3(V3_out),
    .read_V4(V4_out),
    .read_V5(V5_out),
    .read_V6(V6_out),
    .read_V7(V7_out)
);

// ALU //
assign ALU_op = instr[13:11];
assign shamt = instr[3:0];
assign alu_op_0 = reg_data_0;
assign alu_op_1 = (add_immd) ? {{11{instr[4]}}, instr[4:0]}:    // Immediate
                   reg_data_1;                                  // Rs
                   
alu ALU(
    // Inputs //
    .op0(alu_op_0),
    .op1(alu_op_1),
    .ALU_op(ALU_op),
    .shamt(shamt),
    .X(X_bit),
    // Outputs //
    .result(alu_result),
    .Z(Z), .N(N), .V(V)
);

assign alu_flags = {Z_we, N_we, V_we, Z, N, V};
assign alu_flags_we = Z_we | N_we | V_we;

// Flags Logic //
// WE
always@(posedge clk)begin
    if(!rst_n)
        FLAGS[3] <= 1'b0;
    else if(alu_flags_we & ~STALL)
        FLAGS[3] <= alu_flags_we;
    else
        FLAGS[3] <= 1'b0;
end
// Z
always@(posedge clk)begin
    if(!rst_n)
        FLAGS[2] <= 1'b0;
    else if(Z_we & ~STALL)
        FLAGS[2] <= Z;
    else
        FLAGS[2] <= FLAGS[2];
end
// N
always@(posedge clk)begin
    if(!rst_n)
        FLAGS[1] <= 1'b0;
    else if(N_we & ~STALL)
        FLAGS[1] <= N;
    else
        FLAGS[1] <= FLAGS[1];
end
// V
always@(posedge clk)begin
    if(!rst_n)
        FLAGS[0] <= 1'b0;
    else if(V_we & ~STALL)
        FLAGS[0] <= V;
    else
        FLAGS[0] <= FLAGS[0];
end

// Branching Unit //
assign condition_code = instr[10:8];
assign branch_offset = {{8{instr[7]}}, instr[7:0]};
assign jump_offset = (jump_immd) ? {{6{instr[9]}}, instr[9:0]}: // Immediate
                      reg_data_1;                               // Rt register

branch_unit pc_ctrl(
    // Inputs //
    .branch(branch),
    .jump(jump),
    .return(~jump_immd),
    .condition_code(condition_code),
    .condition_flags(FLAGS[2:0]),
    .PC_plus_one(pc_plus_1),
    .branch_offset(branch_offset),
    .jump_offset(jump_offset),
    // Outputs //
    .PC_select(PC_select),
    .PC_next(PC_next),
    .PC_return(PC_return)
);

// Pipeline Flip-Flop //--------------------------------------------------------
// ALU Result //
always@(posedge clk)begin
    if(!rst_n)
        DEX_alu_result <= 16'h0;
    else if(~STALL_control)
        DEX_alu_result <= alu_result;
    else
        DEX_alu_result <= DEX_alu_result;
end
// PC Return to Save in R16
always@(posedge clk)begin
    if(!rst_n)
        DEX_PC_return <= 16'h0;
    else if(~STALL_control)
        DEX_PC_return <= PC_return;
    else
        DEX_PC_return <= DEX_PC_return;
end
// Memory Address/Data (ST/LDR)//
always@(posedge clk)begin
    if(!rst_n)begin
        DEX_mem_read_addr  <= 16'h0;
        DEX_mem_write_data <= 16'h0;
    end else if(~STALL_control)begin
        DEX_mem_read_addr  <= mem_read_addr;
        DEX_mem_write_data <= mem_write_data;
    end else begin
        DEX_mem_read_addr  <= DEX_mem_read_addr;
        DEX_mem_write_data <= DEX_mem_write_data;
    end 
end
// Immediate Value (LDU/LDR)//
assign load_immd = (ldu) ? {instr[7:0], reg_data_0[7:0]}:
                           {reg_data_0[15:8], instr[7:0]};

always@(posedge clk)begin
    if(!rst_n)
        DEX_load_immd <= 16'h0;
    else if(~STALL_control)
        DEX_load_immd <= load_immd;
    else
        DEX_load_immd <= DEX_load_immd;
end

// Destination Register Addresses (ALU/J/JI)//
assign dst_addr_0 =  reg_addr_0;                    // Rd/Rs
assign dst_addr_1 = (jump) ? 5'b10000: reg_addr_1;  // Rt or R16 for jump

always@(posedge clk)begin
    if(!rst_n)begin
        DEX_dst_addr_0 <= 5'h0;
        DEX_dst_addr_1 <= 5'h0;
    end else if(~STALL_control)begin
        DEX_dst_addr_0 <= dst_addr_0;
        DEX_dst_addr_1 <= dst_addr_1;
    end else begin
        DEX_dst_addr_0 <= DEX_dst_addr_0;
        DEX_dst_addr_1 <= DEX_dst_addr_1;
    end 
end

// Register Data (SWAP/J) //
always@(posedge clk)begin
    if(!rst_n)begin
        DEX_reg_data_0 <= 16'h0;
        DEX_reg_data_1 <= 16'h0;
    end else if(~STALL_control)begin
        DEX_reg_data_0 <= reg_data_0;
        DEX_reg_data_1 <= reg_data_1;
    end else begin
        DEX_reg_data_0 <= DEX_reg_data_0;
        DEX_reg_data_1 <= DEX_reg_data_1;
    end
end

// Control Signals //
always@(posedge clk)begin
    if(!rst_n)begin
        DEX_alu_to_reg      <= 1'h0;
        DEX_pcr_to_reg      <= 1'h0;
        DEX_mem_to_reg      <= 1'h0;
        DEX_imm_to_reg      <= 1'h0;
        DEX_reg_we_dst_0    <= 1'h0;
        DEX_reg_we_dst_1    <= 1'h0;
        DEX_mem_we          <= 1'h0;
        DEX_mem_re          <= 1'h0;
        DEX_mem_re          <= 1'h0;
        DEX_halt            <= 1'h0;
    end else if(~STALL_control)begin
        // NOP bubble on RAW hazards //
        DEX_alu_to_reg      <= alu_to_reg   & ~BUBBLE_hazard;
        DEX_pcr_to_reg      <= pcr_to_reg   & ~BUBBLE_hazard;
        DEX_mem_to_reg      <= mem_to_reg   & ~BUBBLE_hazard;
        DEX_imm_to_reg      <= ldl | ldu    & ~BUBBLE_hazard;
        DEX_reg_we_dst_0    <= reg_we_dst_0 & ~BUBBLE_hazard;
        DEX_reg_we_dst_1    <= reg_we_dst_1 & ~BUBBLE_hazard;
        DEX_mem_we          <= mem_we       & ~BUBBLE_hazard;
        DEX_mem_re          <= mem_re       & ~BUBBLE_hazard;
        DEX_halt            <= halt         & ~BUBBLE_hazard;
    end else begin
        DEX_alu_to_reg      <= DEX_alu_to_reg  ;
        DEX_pcr_to_reg      <= DEX_pcr_to_reg  ;
        DEX_mem_to_reg      <= DEX_mem_to_reg  ;
        DEX_imm_to_reg      <= DEX_imm_to_reg  ; 
        DEX_reg_we_dst_0    <= DEX_reg_we_dst_0;
        DEX_reg_we_dst_1    <= DEX_reg_we_dst_1;
        DEX_mem_we          <= DEX_mem_we      ;
        DEX_mem_re          <= DEX_mem_re      ;
        DEX_halt            <= DEX_halt        ;
    end 
end

endmodule
