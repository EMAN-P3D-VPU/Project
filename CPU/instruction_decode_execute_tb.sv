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
logic 			clk, rst_n;
logic	[15:0]	instr;
logic	[15:0]	pc_plus_1;
logic			VPU_data_we;
logic			VPU_rdy;
logic			we_CPU_0;
logic			we_CPU_1;
logic			SPART_we;
logic	[3:0]	SPART_keys; // [UP,DOWN,LEFT,RIGHT]
logic	[4:0]	wrt_addr_0;
logic	[4:0]	wrt_addr_1;
logic	[15:0]	wrt_data_0;
logic	[15:0]	wrt_data_1;
logic	[15:0]	VPU_V0, VPU_V1, VPU_V2, VPU_V3, VPU_V4, VPU_V5, VPU_V6, VPU_V7, VPU_RO;

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
integer i, j, k;
logic			X;
logic	[4:0]	Opcode;
logic	[4:0]	Rd_Rs, Rt;

////////////////////
// Instantiations /
//////////////////
instruction_decode_execute DEX(
	// Inputs //
	.clk(clk), .rst_n(rst_n),
    .instr(instr),
    .pc_plus_1(pc_plus_1),
    .we_VPU(VPU_data_we),
    .VPU_rdy(VPU_rdy),
    .we_CPU_0(we_CPU_0),
    .we_CPU_1(we_CPU_1),
    .wrt_addr_0(wrt_addr_0),
    .wrt_addr_1(wrt_addr_1),
    .wrt_data_0(wrt_data_0),
    .wrt_data_1(wrt_data_1),
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

/////////////
// OPCODES /
///////////
localparam AND  = 5'b00000;
localparam OR   = 5'b00001;
localparam XOR  = 5'b00010;
localparam NOT  = 5'b00011;
localparam ADD  = 5'b00100;
localparam LSL  = 5'b00101;
localparam SR   = 5'b00110; // LSR/ASR
localparam ROT  = 5'b00111; // ROL/ROR
localparam MOV  = 5'b01000; // MOV/SWAP
localparam LDR  = 5'b01001;
localparam LDU  = 5'b01010;
localparam LDL  = 5'b01011;
localparam ST   = 5'b01100;
localparam J    = 5'b01101; // J/JI
localparam B    = 5'b01110; // All B instr.
localparam NOP  = 5'b01111; // NOP/WAIT
localparam HALT = 5'b11111;

///////////////
// REGISTERS /
/////////////
localparam  R0  = 5'b00000;
localparam  R1  = 5'b00001;
localparam  R2  = 5'b00010;
localparam  R3  = 5'b00011;
localparam  R4  = 5'b00100;
localparam  R5  = 5'b00101;
localparam  R6  = 5'b00110;
localparam  R7  = 5'b00111;
localparam  R8  = 5'b01000;
localparam  R9  = 5'b01001;
localparam  R10 = 5'b01010;
localparam  R11 = 5'b01011;
localparam  R12 = 5'b01100;
localparam  R13 = 5'b01101;
localparam  R14 = 5'b01110;
localparam  R15 = 5'b01111;
localparam  R16 = 5'b10000;
localparam  R17 = 5'b10001;
localparam  R18 = 5'b10010;
localparam  R19 = 5'b10011;
localparam  R20 = 5'b10100;
localparam  R21 = 5'b10101;
localparam  R22 = 5'b10110;
localparam  R23 = 5'b10111;
localparam  R24 = 5'b11000;
localparam  R25 = 5'b11001;
localparam  R26 = 5'b11010;
localparam  R27 = 5'b11011;
localparam  R28 = 5'b11100;
localparam  R29 = 5'b11101;
localparam  R30 = 5'b11110;
localparam  R31 = 5'b11111;

////////////////////////////////////////////////////////////////////////////////
// instruction_decode_execute_tb
////

// Clock //
always
	#2 clk = ~clk;

// Fail Safe Stop //
initial
	#1000000 $stop;

// Main Test Loop //
initial begin
	clk = 0;
	rst_n = 0;
	i = 0; j = 0; k = 0;
    // CPU - IF //
    instr       = 16'h0000;
    pc_plus_1   = 16'h0000;
	// CPU - MWB //
    we_CPU_0    = 0;
    we_CPU_1    = 0;
    wrt_addr_0  = 5'b00000;
    wrt_addr_1  = 5'b00000;
    wrt_data_0  = 16'h0000;
    wrt_data_1  = 16'h0000;
	// SPART //
    SPART_we    = 0;
    SPART_keys  = 4'h0;
	// VPU //
    VPU_data_we = 0;
    VPU_rdy     = 1;
    VPU_V0      = 16'h0000;
    VPU_V1      = 16'h0000;
    VPU_V2      = 16'h0000;
    VPU_V3      = 16'h0000;
    VPU_V4      = 16'h0000;
    VPU_V5      = 16'h0000;
    VPU_V6      = 16'h0000;
    VPU_V7      = 16'h0000;
    VPU_RO      = 16'h0000;

	$display("rst assert\n");
	@(negedge clk) rst_n = 1;
	$display("rst deassert\n");

	// CPU/VPU/SPART I/O interface regarding writing/reading the register file //--
	// Write Data to each register (PORT 0) //
	we_CPU_0    = 1;
	for(i = 0; i < 32; i = i + 1)begin
		@(posedge clk);
		wrt_addr_0 = i;
		wrt_data_0 = 2*i;
	end

	// Check if Data was set //
	for(i = 0; i < 32; i = i + 1)begin 
		@(posedge clk);
		force DEX.reg_addr_0 = i;
		@(negedge clk);
		if(DEX.reg_data_0 !== 2*i)begin
			$display("Register%d data does not match: %h EXPECTED: %h",
						i, DEX.reg_data_0, 2*i);
			$stop;
		end
		release DEX.reg_addr_0;
	end

	we_CPU_0    = 0;
	// Write Data to each register (PORT 1) //
	we_CPU_1    = 1;
	for(i = 0; i < 32; i = i + 1)begin
		@(posedge clk);
		wrt_addr_1 = i;
		wrt_data_1 = i;
	end

	// Check if Data was set //
	for(i = 0; i < 32; i = i + 1)begin 
		@(posedge clk);
		force DEX.reg_addr_1 = i;
		@(negedge clk);
		if(DEX.reg_data_1 !== i)begin
			$display("Register%d data does not match: %h EXPECTED: %h",
						i, DEX.reg_data_1, i);
			$stop;
		end
		release DEX.reg_addr_1;
	end

	we_CPU_1    = 0;
	// VPU Interface //
	@(posedge clk);
    VPU_data_we = 1;
    VPU_V0      = 16'h000A;
    VPU_V1      = 16'h000B;
    VPU_V2      = 16'h000C;
    VPU_V3      = 16'h000D;
    VPU_V4      = 16'h000E;
    VPU_V5      = 16'h000F;
    VPU_V6      = 16'h00AA;
    VPU_V7      = 16'h00BB;
    VPU_RO      = 16'h00CC;

	@(negedge clk);
	if(DEX_V0 !== VPU_V0)begin
		$display("Vertex Register V0 incorrect: %h EXPECTED %h", DEX_V0, VPU_V0);
		$stop;
	end
	if(DEX_V1 !== VPU_V1)begin
		$display("Vertex Register V1 incorrect: %h EXPECTED %h", DEX_V1, VPU_V1);
		$stop;
	end
	if(DEX_V2 !== VPU_V2)begin
		$display("Vertex Register V2 incorrect: %h EXPECTED %h", DEX_V2, VPU_V2);
		$stop;
	end
	if(DEX_V3 !== VPU_V3)begin
		$display("Vertex Register V3 incorrect: %h EXPECTED %h", DEX_V3, VPU_V3);
		$stop;
	end
	if(DEX_V4 !== VPU_V4)begin
		$display("Vertex Register V4 incorrect: %h EXPECTED %h", DEX_V4, VPU_V4);
		$stop;
	end
	if(DEX_V5 !== VPU_V5)begin
		$display("Vertex Register V5 incorrect: %h EXPECTED %h", DEX_V5, VPU_V5);
		$stop;
	end
	if(DEX_V6 !== VPU_V6)begin
		$display("Vertex Register V6 incorrect: %h EXPECTED %h", DEX_V6, VPU_V6);
		$stop;
	end
	if(DEX_V7 !== VPU_V7)begin
		$display("Vertex Register V7 incorrect: %h EXPECTED %h", DEX_V7, VPU_V7);
		$stop;
	end
	if(DEX_RO !== VPU_RO)begin
		$display("Vertex Register RO incorrect: %h EXPECTED %h", DEX_RO, VPU_RO);
		$stop;
	end

    VPU_data_we = 0; // This won't deassert til end of the cycle in practice
	// SPART Interface //
	@(posedge clk);
    SPART_we    = 1;
    SPART_keys  = 4'hF; // Write all key bits in R22 [6:3]

	@(negedge clk);
	if(DEX.regfile.R22[6:3] !== SPART_keys)begin
		$display("SPART interface was not captured by the CPU correctly! R22: %h", DEX.regfile.R22);
		$stop;
	end
	// Clearing the SPART flags is up to the user with an AND operation or similar //
    SPART_we    = 1;
	// CPU Operation Tests //------------------------------------------------------
	@(posedge clk);
	Opcode		= AND;
	X			= 0;
	Rd_Rs		= R0;
	Rt			= R1;
	instr       = {Opcode, X, Rd_Rs, Rt};
    pc_plus_1   = pc_plus_1 + 1;
	
	repeat(25) @(posedge clk);
	$stop;
end

endmodule
