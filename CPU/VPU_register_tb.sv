////////////////////////////////////////////////////////////////////////////////
// VPU_register_tb.sv
// Dan Wortmann
//
// Description:
// 
////////////////////////////////////////////////////////////////////////////////
module VPU_register_tb();
////////////
// Inputs /
//////////
logic			clk, rst_n, STALL;
logic			VPU_start;
logic			VPU_rdy;
logic	[15:0]	VPU_instr;
logic	[15:0]	V0_in, V1_in, V2_in, V3_in, V4_in, V5_in, V6_in, V7_in, RO_in;

logic	[15:0]	INSTRUCTION;
/////////////
// Outputs /
///////////
wire			VPU_start_out;
wire			VPU_fill;
wire	[1:0]	VPU_obj_type;
wire	[2:0]	VPU_obj_color;
wire	[3:0]	VPU_op;
wire	[3:0]	VPU_code;
wire	[4:0]	VPU_obj_num;
wire	[15:0]	V0_out, V1_out, V2_out, V3_out, V4_out, V5_out, V6_out, V7_out, RO_out;

///////////////////
// Interconnects /
/////////////////

////////////////////
// Instantiations /
//////////////////
// VPU Interface Register //
VPU_register VPU_data_out(
    // Inputs //
    .clk(clk), .rst_n(rst_n), .STALL(STALL),
    .VPU_start(VPU_start),
	.VPU_rdy(VPU_rdy),
	.VPU_instr(VPU_instr),
    .V0_in(V0_in),
    .V1_in(V1_in),
    .V2_in(V2_in),
    .V3_in(V3_in),
    .V4_in(V4_in),
    .V5_in(V5_in),
    .V6_in(V6_in),
    .V7_in(V7_in),
    .RO_in(RO_in),
    // Outputs //
    .VPU_start_out(VPU_start_out),
	.VPU_fill(VPU_fill),
	.VPU_obj_type(VPU_obj_type),
	.VPU_obj_color(VPU_obj_color),
	.VPU_op(VPU_op),
	.VPU_code(VPU_code),
	.VPU_obj_num(VPU_obj_num),
    .V0_out(V0_out),
    .V1_out(V1_out),
    .V2_out(V2_out),
    .V3_out(V3_out),
    .V4_out(V4_out),
    .V5_out(V5_out),
    .V6_out(V6_out),
    .V7_out(V7_out),
    .RO_out(RO_out)
);

/////////////////
// VPU Opcodes /
///////////////                 // op
localparam DRAW     = 5'b10000; // 0x0
localparam ELLI     = 5'b10001; // DROPPED
localparam FILL     = 5'b10010; // not to mmu (seperate)
localparam RMV      = 5'b10011; // 0x1 , 0x2 - All
localparam TRAN     = 5'b10100; // 0x3 , 0x4 - All
localparam ROT      = 5'b10101; // 0x6 - Left , 0x7 - Right
localparam SCALE    = 5'b10110;
localparam REFLECT  = 5'b10111; // 0x8 - x , 0x9 - y , 0xA - Both
localparam MAT      = 5'b11000; // 0xB - Create , 0xC - Use
localparam GETOBJ   = 5'b11001; // 0xF
								// 0xD - UNUSED

////////////////////////////////////////////////////////////////////////////////
// VPU_register_tb
////

// Clock //
always
	#2 clk = ~clk;

// Fail Safe Stop //
initial
	#1000 $stop;

// Simulate CPU Operatations //
always@(VPU_rdy)
	STALL = ~VPU_rdy;

always@(VPU_instr)
	VPU_start = VPU_instr[15];

always@(INSTRUCTION)
	VPU_instr = INSTRUCTION;

always@(posedge clk)
	if(VPU_start)
		VPU_instr <= 16'h0;

// Main Test Loop //
initial begin
	clk = 0;
	rst_n = 0;
	STALL 		= 1'h0;
    VPU_rdy     = 1'h1;	// CPU stalls when VPU is not ready!
    VPU_start	= 1'h0;
	VPU_instr	= 16'h0000;
    V0_in       = 16'h0000;
    V1_in       = 16'h0001;
    V2_in       = 16'h0002;
    V3_in       = 16'h0003;
    V4_in       = 16'h0004;
    V5_in       = 16'h0005;
    V6_in       = 16'h0006;
    V7_in       = 16'h0007;
    RO_in       = 16'h000F;
	$display("rst assert\n");
	@(negedge clk) rst_n = 1;
	$display("rst deassert\n");

	///////////////////////////////////////////////////////////////////////////////
	// Create Object
	@(posedge clk);
	INSTRUCTION = 16'b10000_11_1_00000_000; // Draw Quad (joined)
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'h0)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'h0);
		$stop;
	end
	if(VPU_code != 4'hX)begin
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, 4'hX);
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;

	@(posedge clk);
	INSTRUCTION = 16'b10000_10_1_00000_000; // Draw Tri (joined)
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'h0)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'h0);
		$stop;
	end
	if(VPU_code != 4'hX)begin
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, 4'hX);
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;

	@(posedge clk);
	INSTRUCTION = 16'b10000_01_1_00000_000; // Draw Line (joined)
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'h0)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'h0);
		$stop;
	end
	if(VPU_code != 4'hX)begin
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, 4'hX);
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;

	///////////////////////////////////////////////////////////////////////////////
	// Delete Single Object
	@(posedge clk);
	INSTRUCTION = 16'b10011_0_11010_00000; 
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'h1)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'h1);
		$stop;
	end
	if(VPU_code != 4'hX)begin
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, 4'hX);
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;

	///////////////////////////////////////////////////////////////////////////////
	// Delete All Objects 
	@(posedge clk);
	INSTRUCTION = 16'b10011_1_11111_00000; 
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'h2)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'h2);
		$stop;
	end
	if(VPU_code != 4'hX)begin
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, 4'hX);
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;

	///////////////////////////////////////////////////////////////////////////////
	// Translate Single Point
	@(posedge clk);
	INSTRUCTION = 16'b10100_0_00001_01000; 
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'h3)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'h3);
		$stop;
	end
	if(VPU_code != {INSTRUCTION[1:0],INSTRUCTION[3:2]})begin
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, {INSTRUCTION[1:0],INSTRUCTION[3:2]});
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;

	///////////////////////////////////////////////////////////////////////////////
	// Translate All Points
	@(posedge clk);
	INSTRUCTION = 16'b10100_1_10101_01100; 
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'h4)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'h4);
		$stop;
	end
	if(VPU_code != {INSTRUCTION[1:0],INSTRUCTION[3:2]})begin
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, {INSTRUCTION[1:0],INSTRUCTION[3:2]});
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;

	///////////////////////////////////////////////////////////////////////////////
	// Scale
	@(posedge clk);
	INSTRUCTION = 16'b10110_0_01101_0_0_100; 
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'h5)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'h5);
		$stop;
	end
	if(VPU_code != {INSTRUCTION[3],INSTRUCTION[2:0]})begin
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, {INSTRUCTION[3],INSTRUCTION[2:0]});
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;

	///////////////////////////////////////////////////////////////////////////////
	// Rotate Left
	@(posedge clk);
	INSTRUCTION = 16'b10101_1_01101_0_0_101; 
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'h6)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'h6);
		$stop;
	end
	if(VPU_code != {INSTRUCTION[3],INSTRUCTION[2:0]})begin
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, {INSTRUCTION[3],INSTRUCTION[2:0]});
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;

	///////////////////////////////////////////////////////////////////////////////
	// Rotate Right
	@(posedge clk);
	INSTRUCTION = 16'b10101_0_11101_0_1_100; 
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'h7)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'h7);
		$stop;
	end
	if(VPU_code != {INSTRUCTION[3],INSTRUCTION[2:0]})begin
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, {INSTRUCTION[3],INSTRUCTION[2:0]});
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;

	///////////////////////////////////////////////////////////////////////////////
	// Reflect X
	@(posedge clk);
	INSTRUCTION = 16'b10111_0_11001_000_01; 
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'h8)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'h8);
		$stop;
	end
	if(VPU_code != {INSTRUCTION[1:0],INSTRUCTION[3:2]})begin // THIS MAY CHANGE
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, {INSTRUCTION[3],INSTRUCTION[2:0]});
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;

	///////////////////////////////////////////////////////////////////////////////
	// Reflect Y
	@(posedge clk);
	INSTRUCTION = 16'b10111_0_11001_000_10; 
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'h9)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'h9);
		$stop;
	end
	if(VPU_code != {INSTRUCTION[1:0],INSTRUCTION[3:2]})begin // THIS MAY CHANGE
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, {INSTRUCTION[3],INSTRUCTION[2:0]});
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;

	///////////////////////////////////////////////////////////////////////////////
	// Reflect XY
	@(posedge clk);
	INSTRUCTION = 16'b10111_0_11001_000_11; 
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'hA)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'hA);
		$stop;
	end
	if(VPU_code != {INSTRUCTION[1:0],INSTRUCTION[3:2]})begin // THIS MAY CHANGE
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, {INSTRUCTION[3],INSTRUCTION[2:0]});
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;

	///////////////////////////////////////////////////////////////////////////////
	// Create Matrix
	@(posedge clk);
	INSTRUCTION = 16'b11000_0_00000_00000; 
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'hB)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'hB);
		$stop;
	end
	if(VPU_code != {INSTRUCTION[1:0],INSTRUCTION[3:2]})begin
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, {INSTRUCTION[3],INSTRUCTION[2:0]});
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;

	///////////////////////////////////////////////////////////////////////////////
	// Use Matrix
	@(posedge clk);
	INSTRUCTION = 16'b11000_1_00000_00000; 
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'hC)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'hC);
		$stop;
	end
	if(VPU_code != {INSTRUCTION[1:0],INSTRUCTION[3:2]})begin
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, {INSTRUCTION[3],INSTRUCTION[2:0]});
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;

	///////////////////////////////////////////////////////////////////////////////
	// LoadBack
	@(posedge clk);
	INSTRUCTION = 16'b11001_0_00000_00000; 
	@(posedge clk);
	// Check expected values //
	#1;
	if(VPU_start_out !== 1'b1)begin
		$display("VPU_start_out had unexpected value:%b EXPECTED:%b\n", VPU_start_out, 1'b1);
		$stop;
	end
	if(VPU_fill !== 1'b0)begin
		$display("VPU_fill had unexpected value:%b EXPECTED:%b\n", VPU_fill, 1'b0);
		$stop;
	end
	if(VPU_obj_type !== INSTRUCTION[10:9])begin
		$display("VPU_obj_type had unexpected value:%b EXPECTED:%b\n", VPU_obj_type, INSTRUCTION[10:9]);
		$stop;
	end
	if(VPU_obj_color !== INSTRUCTION[2:0])begin
		$display("VPU_obj_color had unexpected value:%b EXPECTED:%b\n", VPU_obj_color, INSTRUCTION[2:0]);
		$stop;
	end
	if(VPU_op !== 4'hF)begin
		$display("VPU_op had unexpected value:%h EXPECTED:%h\n", VPU_op, 4'hF);
		$stop;
	end
	if(VPU_code != {INSTRUCTION[1:0],INSTRUCTION[3:2]})begin
		$display("VPU_code had unexpected value:%h EXPECTED:%h\n", VPU_code, {INSTRUCTION[3],INSTRUCTION[2:0]});
		$stop;
	end
	if(VPU_obj_num != INSTRUCTION[9:5])begin
		$display("VPU_obj_num had unexpected value:%h EXPECTED:%h\n", VPU_obj_num, INSTRUCTION[9:5]);
		$stop;
	end

	@(negedge clk);
	VPU_rdy = 0;
	repeat(5) @(posedge clk);
	@(negedge clk);
	VPU_rdy = 1;


	repeat(5) @(posedge clk);
	$stop;
end

endmodule
