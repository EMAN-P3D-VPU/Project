////////////////////////////////////////////////////////////////////////////////
// control_unit.v
// Dan Wortmann
//
// Description:
// 
////////////////////////////////////////////////////////////////////////////////
module control_unit(// Inputs //
					opcode,
					x_bit,
					wait_time,
					VPU_rdy,
					// Output //
					STALL_control,
					VPU_start,
					alu_to_reg,
					pcr_to_reg,
					mem_to_reg,
					reg_we_dst_0,
					reg_we_dst_1,
					mem_we,
					mem_re,
					add_immd,
					jump_immd,
					ldu, ldl,
					branch,
					jump,
					Z_we, N_we, V_we
					);
////////////
// Inputs /
//////////
// From CPU //
input			x_bit;		// Extra Opcode Bit
input	[4:0]	opcode;
input	[10:0]	wait_time;

// From VPU //
input			VPU_rdy;

// From SPART? //

/////////////
// Outputs /
///////////
output	reg		STALL_control;
output  reg     VPU_start;
output  reg     alu_to_reg;
output  reg     pcr_to_reg;
output  reg     mem_to_reg;
output  reg     reg_we_dst_0;
output  reg     reg_we_dst_1;
output  reg     mem_we;
output  reg     mem_re;
output  reg     add_immd;
output  reg     jump_immd;
output  reg     ldu;
output	reg		ldl;
output	reg		branch;
output	reg		jump;
output	reg		Z_we, N_we, V_we;

/////////////////////////////
// Signals/Logic/Registers /
///////////////////////////

///////////////////
// Interconnects /
/////////////////

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
// control_unit
////

always@(*)begin
	// Defaults //
	VPU_start = 0;		// Signal VPU to begin instruction
	alu_to_reg = 0;		// Write ALU result to register
	pcr_to_reg = 0;		// Write PC+1 to return register (R16)
	mem_to_reg = 0;		// Write Memory data to register
	reg_we_dst_0 = 0;	// Write enable port 0 in register file
	reg_we_dst_1 = 0;	// Write enable port 1 in register file
	mem_we = 0;			// Write to data memory
	mem_re = 0;			// Read from data memory
	add_immd = 0;		// Add immediate to Rs
	jump_immd = 0;		// Jump using immediate (not Rt)
	ldu = 0;			// Load Upper byte in register (loads lower otherwise)
	ldl = 0;			// Load Lower byte in register (loads upper byte otherwise)
	branch = 0;			// Signal a branch
	jump = 0;			// Signal a jump
	Z_we = 0;			// Update flags from ALU operation
	N_we = 0;
	V_we = 0;

	// Control SM //
	case(opcode)
        AND:begin
        	alu_to_reg = 1;
			reg_we_dst_0 = 1;
        end
        OR :begin
        	alu_to_reg = 1;
			reg_we_dst_0 = 1;
        end
        XOR:begin
        	alu_to_reg = 1;
			reg_we_dst_0 = 1;
        end
        NOT:begin
        	alu_to_reg = 1;
			reg_we_dst_0 = 1;
        end
        ADD:begin
        	alu_to_reg = 1;
			reg_we_dst_0 = 1;
			if(x_bit)
				add_immd = 1;
        end
        LSL:begin
        	alu_to_reg = 1;
			reg_we_dst_0 = 1;
        end
        SR :begin
        	alu_to_reg = 1;
			reg_we_dst_0 = 1;
        end
        ROT:begin
        	alu_to_reg = 1;
			reg_we_dst_0 = 1;
        end
        MOV:begin
			reg_we_dst_0 = 1;
			reg_we_dst_1 = 1;
        end
        LDR:begin
			mem_re = 1;
        	mem_to_reg = 1;
			reg_we_dst_0 = 1;
        end
        LDU:begin
			reg_we_dst_0 = 1;
			ldu = 1;
        end
        LDL:begin
			reg_we_dst_0 = 1;
			ldl = 1;
        end
        ST :begin
        	mem_we = 1;
        end
        J  :begin
			jump = 1;
        	pcr_to_reg = 1;
			reg_we_dst_1 = 1;
			if(x_bit)
				jump_immd = 1;
        end
        B  :begin
        	branch = 1;
        end
        NOP:begin
        
        end
		HALT:begin

		end
		// All other commands default to VPU instructions //
        default: VPU_start = 1;
	endcase
end

endmodule
