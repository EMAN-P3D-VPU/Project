////////////////////////////////////////////////////////////////////////////////
// alu.v
// Dan Wortmann
//
// Description:
// Arithmetic logic unit for the main CPU pipeline responsible for basic
// operations for game logic. This includes the first 8 opcodes of the P3DVPU
// ISA: 
//		AND, OR, XOR, NOT, ADD, ADDI, LSL, LSR, ASR, ROL, ROR
//
// Operations are all done in parallel to reduce execution time and seperate
// unique logic. The N,Z,V flags are set appropriately as described in the ISA.
////////////////////////////////////////////////////////////////////////////////
module alu(op0, op1, ALU_op, shamt, X, result, Z, N, V);
////////////
// Inputs /
//////////
input		[15:0]	op0, op1;
input		[2:0]	ALU_op;
input		[3:0]	shamt;
input				X;			// Extra opcode bit

/////////////
// Outputs /
///////////
output	reg	[15:0]	result;
output	reg			N, Z, V;

/////////////////////////////
// Signals/Logic/Registers /
///////////////////////////

///////////////////
// Interconnects /
/////////////////
// AND -----------------------
wire	[15:0]	AND_result;
wire			AND_zero;
// OR ------------------------
wire	[15:0]	OR_result;
wire			OR_zero;
// XOR -----------------------
wire	[15:0]	XOR_result;
wire			XOR_zero;
// NOT -----------------------
wire	[15:0]	NOT_result;
wire			NOT_zero;
// ADD -----------------------
wire	[15:0]	ADD_result_raw;
wire	[15:0]	ADD_result;
wire			ADD_ov_pos;
wire			ADD_ov_neg;
wire			ADD_ov;
wire			ADD_neg;
wire			ADD_zero;
// LSL -----------------------
wire	[15:0]	LSL_1;
wire	[15:0]	LSL_2;
wire	[15:0]	LSL_4;
wire	[15:0]	LSL_result;
wire			LSL_zero;
// LSR -----------------------
wire	[15:0]	LSR_1;
wire	[15:0]	LSR_2;
wire	[15:0]	LSR_4;
wire	[15:0]	LSR_result;
wire			LSR_zero;
// ASR -----------------------
wire	[15:0]	ASR_1;
wire	[15:0]	ASR_2;
wire	[15:0]	ASR_4;
wire	[15:0]	ASR_result;
wire			ASR_zero;
// ROL -----------------------
wire	[15:0]	ROL_result;
// ROR -----------------------
wire	[15:0]	ROR_result;

////////////////////////////////////////////////////////////////////////////////
// alu
////
localparam AND	= 3'b000;
localparam OR	= 3'b001;
localparam XOR	= 3'b010;
localparam NOT	= 3'b011;
localparam ADD	= 3'b100;
localparam LSL	= 3'b101;
localparam SR	= 3'b110;
localparam ROT	= 3'b111;

// AND bitwise -----------------------------------------------------------------

// Intermediate result //
assign AND_result = op0 & op1;

// Zero //
assign AND_zero = ~|AND_result;

// OR bitwise ------------------------------------------------------------------

// Intermediate result //
assign OR_result = op0 | op1;

// Zero //
assign OR_zero = ~|OR_result;

// XOR bitwise -----------------------------------------------------------------

// Intermediate result //
assign XOR_result = op0 ^ op1;

// Zero //
assign XOR_zero = ~|XOR_result;

// NOT bitwise -----------------------------------------------------------------

// Intermediate result //
assign NOT_result = ~op1;

// Zero //
assign NOT_zero = ~|NOT_result;

// ADD signed ------------------------------------------------------------------

// Intermediate result //
assign ADD_result_raw = op0 + op1;

// Overflow //
assign ADD_ov_neg = ( op0[15] &  op1[15] & ~ADD_result_raw[15]);
assign ADD_ov_pos = (~op0[15] & ~op1[15] &  ADD_result_raw[15]);
assign ADD_ov = ADD_ov_pos | ADD_ov_neg;

// Round result //
assign ADD_result = (ADD_ov_pos) ? 16'h7FFF:
					(ADD_ov_neg) ? 16'h8000:
					 ADD_result_raw;

// Zero //
assign ADD_zero = ~|ADD_result;

// Negative //
assign ADD_neg = ADD_result[15];

// LSL -------------------------------------------------------------------------

// Intermediate result //
assign LSL_1		= (shamt[0]) ? (op0 << 1):
				       op0;
assign LSL_2 		= (shamt[1]) ? (LSL_1 << 2):
				       LSL_1;
assign LSL_4 		= (shamt[2]) ? (LSL_2 << 4):
				       LSL_2;
assign LSL_result 	= (shamt[3]) ? (LSL_4 << 8):
				       LSL_4;
// Zero //
assign LSL_zero = ~|LSL_result;

// LSR/ASR ---------------------------------------------------------------------

// Intermediate result //
assign LSR_1		= (shamt[0]) ? (op0 >> 1):
				       op0;
assign LSR_2 		= (shamt[1]) ? (LSR_1 >> 2):
				       LSR_1;
assign LSR_4 		= (shamt[2]) ? (LSR_2 >> 4):
				       LSR_2;
assign LSR_result 	= (shamt[3]) ? (LSR_4 >> 8):
				       LSR_4;
// Zero //
assign LSR_zero = ~|LSR_result;

// Intermediate result //
assign ASR_1		= (shamt[0]) ? (op0 >>> 1):
				       op0;
assign ASR_2 		= (shamt[1]) ? (ASR_1 >>> 2):
				       ASR_1;
assign ASR_4 		= (shamt[2]) ? (ASR_2 >>> 4):
				       ASR_2;
assign ASR_result 	= (shamt[3]) ? (ASR_4 >>> 8):
				       ASR_4;
// Zero //
assign ASR_zero = ~|ASR_result;

// ROL -------------------------------------------------------------------------

// Intermediate result //
assign ROL_result = {op0[14:0], op0[15]};

// ROR -------------------------------------------------------------------------

// Intermediate result //
assign ROR_result = {op0[0], op0[15:1]};

// ALU -------------------------------------------------------------------------
// Select Result + Set Flags //
always@(*)begin
	// defaults //
	N = 0;
	Z = 0;
	V = 0;

	// ALU Operations //
	case(ALU_op)
		AND:begin
			N = AND_result[15];
			Z = AND_zero;
			result = AND_result;
		end
		OR:begin
			N = OR_result[15];
			Z = OR_zero;
			result = OR_result;
		end
		XOR:begin
			N = XOR_result[15];
			Z = XOR_zero;
			result = XOR_result;
		end
		NOT:begin
			N = NOT_result[15];
			Z = NOT_zero;
			result = NOT_result;
		end
		ADD:begin
			N = ADD_neg;
			Z = ADD_zero;
			V = ADD_ov;
			result = ADD_result;
		end
		LSL:begin
			Z = LSL_zero;
			result = LSL_result;
		end
		SR:begin
			// Arithmetic //
			if(X)begin
				Z = ASR_zero;
				result = ASR_result;
			end
			// Logical //
			else begin
				Z = LSR_zero;
				result = LSR_result;
			end
		end
		ROT:begin
			// Right //
			if(X)begin
				result = ROR_result;
			end
			// Left //
			else begin
				result = ROL_result;
			end
		end
		default: result = op1;
	endcase
end

endmodule
