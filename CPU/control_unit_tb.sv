////////////////////////////////////////////////////////////////////////////////
// control_unit_tb.sv
// Dan Wortmann
//
// Description:
// The control unit logic is fairly straight forward and does not require a lot
// of thorough testing. This is moreso dependent on the design of the control
// unit as a whole, and ensuring correct (and needed) signals are asserted at
// the correct times. Most complicated logic is stalling and waiting which will
// encompass much of this testbench.
////////////////////////////////////////////////////////////////////////////////
module control_unit_tb();
////////////
// Inputs /
//////////
logic 			clk, rst_n;
logic			x_bit;		// Extra Opcode Bit
logic	[4:0]	opcode;
logic	[10:0]	wait_time;
logic			VPU_rdy;

/////////////
// Outputs /
///////////
wire    STALL_control;
wire    VPU_start;
wire    alu_to_reg;
wire    pcr_to_reg;
wire    mem_to_reg;
wire    reg_we_dst_0;
wire    reg_we_dst_1;
wire    mem_we;
wire    mem_re;
wire    add_immd;
wire    jump_immd;
wire    ldu;
wire    ldl;
wire    branch;
wire    jump;
wire    Z_we, N_we, V_we;
wire    halt;

///////////////////
// Interconnects /
/////////////////

////////////////////
// Instantiations /
//////////////////
control_unit control(
    // Inputs //
	.clk(clk), .rst_n(rst_n),
	.opcode(opcode),
	.x_bit(x_bit),
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

////////////////////////////////////////////////////////////////////////////////
// control_unit_tb
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
	VPU_rdy = 1;
	wait_time = 11'h0000;
	$display("rst assert\n");
	@(negedge clk) rst_n = 1;
	$display("rst deassert\n");

	// AND //
	@(posedge clk);
	opcode = AND;
	x_bit = 0;

	@(negedge clk);
	if(	(alu_to_reg !== 1) ||
		(reg_we_dst_0 !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// OR //
	@(posedge clk);
	opcode = OR;
	x_bit = 0;

	@(negedge clk);
	if(	(alu_to_reg !== 1) ||
		(reg_we_dst_0 !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// XOR //
	@(posedge clk);
	opcode = XOR;
	x_bit = 0;

	@(negedge clk);
	if(	(alu_to_reg !== 1) ||
		(reg_we_dst_0 !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// NOT //
	@(posedge clk);
	opcode = NOT;
	x_bit = 0;

	@(negedge clk);
	if(	(alu_to_reg !== 1) ||
		(reg_we_dst_0 !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// ADD //
	@(posedge clk);
	opcode = ADD;
	x_bit = 0;

	@(negedge clk);
	if(	(alu_to_reg !== 1) ||
		(reg_we_dst_0 !== 1) ||
		(add_immd !== 0))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// ADDI //
	@(posedge clk);
	opcode = ADD;
	x_bit = 1;

	@(negedge clk);
	if(	(alu_to_reg !== 1) ||
		(reg_we_dst_0 !== 1) ||
		(add_immd !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// LSL //
	@(posedge clk);
	opcode = LSL;
	x_bit = 0;

	@(negedge clk);
	if(	(alu_to_reg !== 1) ||
		(reg_we_dst_0 !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// SR //
	@(posedge clk);
	opcode = SR;
	x_bit = 0;

	@(negedge clk);
	if(	(alu_to_reg !== 1) ||
		(reg_we_dst_0 !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// ROT //
	@(posedge clk);
	opcode = ROT;
	x_bit = 0;

	@(negedge clk);
	if(	(alu_to_reg !== 1) ||
		(reg_we_dst_0 !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// MOV //
	@(posedge clk);
	opcode = MOV;
	x_bit = 0;

	@(negedge clk);
	if(	(reg_we_dst_0 !== 1) ||
		(reg_we_dst_1 !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// LDR //
	@(posedge clk);
	opcode = LDR;
	x_bit = 0;

	@(negedge clk);
	if(	(mem_re !== 1) ||
		(mem_to_reg !== 1) ||
		(reg_we_dst_0 !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// LDU //
	@(posedge clk);
	opcode = LDU;
	x_bit = 0;

	@(negedge clk);
	if(	(reg_we_dst_0 !== 1) ||
		(ldu !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// LDL //
	@(posedge clk);
	opcode = LDL;
	x_bit = 0;

	@(negedge clk);
	if(	(reg_we_dst_0 !== 1) ||
		(ldl !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// ST //
	@(posedge clk);
	opcode = ST;
	x_bit = 0;

	@(negedge clk);
	if(	(mem_we !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// J //
	@(posedge clk);
	opcode = J;
	x_bit = 0;

	@(negedge clk);
	if(	(jump !== 1) ||
		(pcr_to_reg !== 1) ||
		(reg_we_dst_1 !== 1) ||
		(jump_immd !== 0))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// JI //
	@(posedge clk);
	opcode = J;
	x_bit = 1;

	@(negedge clk);
	if(	(jump !== 1) ||
		(pcr_to_reg !== 1) ||
		(reg_we_dst_1 !== 1) ||
		(jump_immd !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// B //
	@(posedge clk);
	opcode = B;
	x_bit = 0;

	@(negedge clk);
	if(	(branch !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// NOP //
	@(posedge clk);
	opcode = NOP;
	x_bit = 0;
	wait_time = 11'h0000;

	@(negedge clk);
	if(	(control.set_timer !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end

	// STALL signal testing //-----------------------------------------------------
	@(posedge clk);
	opcode = NOP;
	wait_time = 11'hFFFF;

	@(negedge clk);
	if(	(control.set_timer !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end
	@(posedge clk); // Flops new timer
	opcode = NOT; // any non NOP instr (stall doesn't assert til we flop next instr)
	wait_time = 11'hFFFF;

	wait(STALL_control == 1);
	// Check Register content //
	if(	(control.timer !== wait_time))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end
	// Monitor Stall signal //
	while(control.timer_done == 0)begin
		if(	(STALL_control !== 1))begin
			$display("Stall signal should be asserted while timer is NOT done");
			$stop;
		end
		@(posedge clk);
	end

	// Now 2 NOP's in a row with non-zero wait times
	@(posedge clk);
	opcode = NOP;
	wait_time = 11'h00FF;

	@(negedge clk);
	if(	(control.set_timer !== 1))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end
	@(posedge clk); // Flops new timer
	opcode = NOP; // any non NOP instr (stall doesn't assert til we flop next instr)
	wait_time = 11'h00FF;

	wait(STALL_control == 1);
	// Check Register content //
	if(	(control.timer !== wait_time))begin
		$display("Needed signals were not asserted during OPCODE:%b", opcode);
		$stop;
	end
	// Monitor Stall signal //
	while(control.timer_done == 0)begin
		if(	(STALL_control !== 1))begin
			$display("Stall signal should be asserted while timer is NOT done");
			$stop;
		end
		@(posedge clk);
	end

	@(posedge clk);
	opcode = NOT;
	wait_time = 11'hAAAA;

	// TODO:
	// VPU_rdy testing? Interface between VPU stalling CPU and then we rerun a
	// NOP command? This seems like a very fringe case but may be worth revisiting

	repeat(25) @(posedge clk);
	$stop;
end

endmodule
