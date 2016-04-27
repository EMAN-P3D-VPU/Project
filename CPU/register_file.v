////////////////////////////////////////////////////////////////////////////////
// register_file.v
// Dan Wortmann
//
// Description:
// The 32 CPU registers have unique access methods and are shared among the CPU
// and VPU space. Since we are operating on 2 read and 2 write ports, on top of
// the VPU return values, the design was well suited to D-Latches to avoid a
// multi-cycle state machine to manage resources. In this designe we are able to
// write to many registers at once, independent of the clock.
////////////////////////////////////////////////////////////////////////////////
module register_file(// Inputs //
					 reg_addr_0, reg_addr_1, wrt_addr_0, wrt_addr_1,
					 cpu_flags, cpu_flags_we,
					 wrt_data_0, wrt_data_1, we_CPU_0, we_CPU_1, we_VPU,
					 wrt_V0, wrt_V1, wrt_V2, wrt_V3,
					 wrt_V4, wrt_V5, wrt_V6, wrt_V7,
					 return_obj,
					 SPART_we, SPART_keys,
					 // Outputs //
					 reg_data_0, reg_data_1, read_RO,
					 read_V0, read_V1, read_V2, read_V3,
					 read_V4, read_V5, read_V6, read_V7);
////////////
// Inputs /
//////////
// Read Address //
input		[4:0]	reg_addr_0;
input		[4:0]	reg_addr_1;
// Write Address //
input		[4:0]	wrt_addr_0;
input		[4:0]	wrt_addr_1;
// Flags Register //
input		[2:0]	cpu_flags;		// Z, N, V
input				cpu_flags_we;
// SPART (key presses) 3 - UP 2 - DOWN 1 - LEFT 0 - RIGHT
input				SPART_we;
input		[4:0]	SPART_keys;
// Write Data from CPU //
input		[15:0]	wrt_data_0;
input		[15:0]	wrt_data_1;
input				we_CPU_0;
input				we_CPU_1;
// Write Data from VPU //
input				we_VPU;
input		[15:0]	wrt_V0;
input		[15:0]	wrt_V1;
input		[15:0]	wrt_V2;
input		[15:0]	wrt_V3;
input		[15:0]	wrt_V4;
input		[15:0]	wrt_V5;
input		[15:0]	wrt_V6;
input		[15:0]	wrt_V7;
input		[15:0]	return_obj; //uhhh do we need this anymore?

/////////////
// Outputs /
///////////
// Read Data to CPU //
output	reg	[15:0]	reg_data_0;
output	reg	[15:0]	reg_data_1;
// Read Data to VPU //
output		[15:0]	read_RO;
output		[15:0]	read_V0;
output		[15:0]	read_V1;
output		[15:0]	read_V2;
output		[15:0]	read_V3;
output		[15:0]	read_V4;
output		[15:0]	read_V5;
output		[15:0]	read_V6;
output		[15:0]	read_V7;

/////////////////////////////
// Signals/Logic/Registers /
///////////////////////////
// Registers (D-Latch) //
reg	[15:0]	R0;
reg [15:0]  R1;
reg [15:0]  R2;
reg [15:0]  R3;
reg [15:0]  R4;
reg [15:0]  R5;
reg [15:0]  R6;
reg [15:0]  R7;
reg [15:0]  R8;
reg [15:0]  R9;
reg [15:0]  R10;
reg [15:0]  R11;
reg [15:0]  R12;
reg [15:0]  R13;
reg [15:0]  R14;
reg [15:0]  R15;
reg [15:0]  R16;
reg [15:0]  R17;
reg [15:0]  R18;
reg [15:0]  R19;
reg [15:0]  R20;
reg [15:0]  R21;
reg [15:0]  R22; // Flags Register
reg [15:0]  R23; // Return Object
reg [15:0]  R24; // Vertex	V0
reg [15:0]  R25; //			V1
reg [15:0]  R26; //			V2
reg [15:0]  R27; //			V3
reg [15:0]  R28; //			V4
reg [15:0]  R29; //			V5
reg [15:0]  R30; //			V6
reg	[15:0]  R31; //			V7

// Write Enable signals //
wire        	we_0 , we_a0 , we_b0 ;
wire        	we_1 , we_a1 , we_b1 ;
wire        	we_2 , we_a2 , we_b2 ;
wire        	we_3 , we_a3 , we_b3 ;
wire        	we_4 , we_a4 , we_b4 ;
wire        	we_5 , we_a5 , we_b5 ;
wire        	we_6 , we_a6 , we_b6 ;
wire        	we_7 , we_a7 , we_b7 ;
wire        	we_8 , we_a8 , we_b8 ;
wire        	we_9 , we_a9 , we_b9 ;
wire        	we_10, we_a10, we_b10;
wire        	we_11, we_a11, we_b11;
wire        	we_12, we_a12, we_b12;
wire        	we_13, we_a13, we_b13;
wire        	we_14, we_a14, we_b14;
wire        	we_15, we_a15, we_b15;
wire        	we_16, we_a16, we_b16;
wire        	we_17, we_a17, we_b17;
wire        	we_18, we_a18, we_b18;
wire        	we_19, we_a19, we_b19;
wire        	we_20, we_a20, we_b20;
wire        	we_21, we_a21, we_b21;
wire        	we_22, we_a22, we_b22; // Flags Register
wire        	we_23, we_a23, we_b23; // Return Object
wire        	we_24, we_a24, we_b24; // Vertex Registers
wire        	we_25, we_a25, we_b25;
wire        	we_26, we_a26, we_b26;
wire        	we_27, we_a27, we_b27;
wire        	we_28, we_a28, we_b28;
wire        	we_29, we_a29, we_b29;
wire        	we_30, we_a30, we_b30;
wire        	we_31, we_a31, we_b31;

// Read & Write Data Buses //
wire    [15:0]  wrt_data_R0 ;
wire    [15:0]  wrt_data_R1 ;
wire    [15:0]  wrt_data_R2 ;
wire    [15:0]  wrt_data_R3 ;
wire    [15:0]  wrt_data_R4 ;
wire    [15:0]  wrt_data_R5 ;
wire    [15:0]  wrt_data_R6 ;
wire    [15:0]  wrt_data_R7 ;
wire    [15:0]  wrt_data_R8 ;
wire    [15:0]  wrt_data_R9 ;
wire    [15:0]  wrt_data_R10;
wire    [15:0]  wrt_data_R11;
wire    [15:0]  wrt_data_R12;
wire    [15:0]  wrt_data_R13;
wire    [15:0]  wrt_data_R14;
wire    [15:0]  wrt_data_R15;
wire    [15:0]  wrt_data_R16;
wire    [15:0]  wrt_data_R17;
wire    [15:0]  wrt_data_R18;
wire    [15:0]  wrt_data_R19;
wire    [15:0]  wrt_data_R20;
wire    [15:0]  wrt_data_R21;
wire    [15:0]  wrt_data_R22;
wire    [15:0]  wrt_data_R23;
wire    [15:0]  wrt_data_R24;
wire    [15:0]  wrt_data_R25;
wire    [15:0]  wrt_data_R26;
wire    [15:0]  wrt_data_R27;
wire    [15:0]  wrt_data_R28;
wire    [15:0]  wrt_data_R29;
wire    [15:0]  wrt_data_R30;
wire    [15:0]  wrt_data_R31;

///////////////////
// Interconnects /
/////////////////

////////////////////////////////////////////////////////////////////////////////
// register_file
////

// Write Enable Signal (Port A) //
assign	we_a0 	=	((wrt_addr_0 == 5'b00000) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a1 	=	((wrt_addr_0 == 5'b00001) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a2 	=	((wrt_addr_0 == 5'b00010) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a3 	=	((wrt_addr_0 == 5'b00011) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a4 	=	((wrt_addr_0 == 5'b00100) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a5 	=	((wrt_addr_0 == 5'b00101) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a6 	=	((wrt_addr_0 == 5'b00110) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a7 	=	((wrt_addr_0 == 5'b00111) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a8 	=	((wrt_addr_0 == 5'b01000) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a9 	=	((wrt_addr_0 == 5'b01001) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a10	=	((wrt_addr_0 == 5'b01010) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a11	=	((wrt_addr_0 == 5'b01011) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a12	=	((wrt_addr_0 == 5'b01100) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a13	=	((wrt_addr_0 == 5'b01101) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a14	=	((wrt_addr_0 == 5'b01110) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a15	=	((wrt_addr_0 == 5'b01111) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a16	=	((wrt_addr_0 == 5'b10000) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a17	=	((wrt_addr_0 == 5'b10001) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a18	=	((wrt_addr_0 == 5'b10010) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a19	=	((wrt_addr_0 == 5'b10011) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a20	=	((wrt_addr_0 == 5'b10100) & we_CPU_0)	? 1'b1 : 1'b0;
assign	we_a21	=	((wrt_addr_0 == 5'b10101) & we_CPU_0)	? 1'b1 : 1'b0;
// Flags Register
assign	we_a22	=	((wrt_addr_0 == 5'b10110) & we_CPU_0)	? 1'b1 : 1'b0;
// Return Object Register
assign	we_a23	=	((wrt_addr_0 == 5'b10111) & we_CPU_0)	? 1'b1 : 1'b0;
// Vertex Registers
assign	we_a24	=	((wrt_addr_0 == 5'b11000) & we_CPU_0)	? 1'b1: 1'b0;
assign	we_a25	=	((wrt_addr_0 == 5'b11001) & we_CPU_0)	? 1'b1: 1'b0;
assign	we_a26	=	((wrt_addr_0 == 5'b11010) & we_CPU_0)	? 1'b1: 1'b0;
assign	we_a27	=	((wrt_addr_0 == 5'b11011) & we_CPU_0)	? 1'b1: 1'b0;
assign	we_a28	=	((wrt_addr_0 == 5'b11100) & we_CPU_0)	? 1'b1: 1'b0;
assign	we_a29	=	((wrt_addr_0 == 5'b11101) & we_CPU_0)	? 1'b1: 1'b0;
assign	we_a30	=	((wrt_addr_0 == 5'b11110) & we_CPU_0)	? 1'b1: 1'b0;
assign	we_a31	=	((wrt_addr_0 == 5'b11111) & we_CPU_0)	? 1'b1: 1'b0;

// Write Enable Signal (Port B) //
assign	we_b0 	=	((wrt_addr_1 == 5'b00000) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b1 	=	((wrt_addr_1 == 5'b00001) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b2 	=	((wrt_addr_1 == 5'b00010) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b3 	=	((wrt_addr_1 == 5'b00011) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b4 	=	((wrt_addr_1 == 5'b00100) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b5 	=	((wrt_addr_1 == 5'b00101) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b6 	=	((wrt_addr_1 == 5'b00110) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b7 	=	((wrt_addr_1 == 5'b00111) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b8 	=	((wrt_addr_1 == 5'b01000) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b9 	=	((wrt_addr_1 == 5'b01001) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b10	=	((wrt_addr_1 == 5'b01010) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b11	=	((wrt_addr_1 == 5'b01011) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b12	=	((wrt_addr_1 == 5'b01100) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b13	=	((wrt_addr_1 == 5'b01101) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b14	=	((wrt_addr_1 == 5'b01110) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b15	=	((wrt_addr_1 == 5'b01111) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b16	=	((wrt_addr_1 == 5'b10000) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b17	=	((wrt_addr_1 == 5'b10001) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b18	=	((wrt_addr_1 == 5'b10010) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b19	=	((wrt_addr_1 == 5'b10011) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b20	=	((wrt_addr_1 == 5'b10100) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b21	=	((wrt_addr_1 == 5'b10101) & we_CPU_1)	? 1'b1 : 1'b0;
// Flags Register
assign	we_b22	=	((wrt_addr_1 == 5'b10110) & we_CPU_1)	? 1'b1 : 1'b0;
// Return Object Register
assign	we_b23	=	((wrt_addr_1 == 5'b10111) & we_CPU_1)	? 1'b1 : 1'b0;
// Vertex Registers
assign	we_b24	=	((wrt_addr_1 == 5'b11000) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b25	=	((wrt_addr_1 == 5'b11001) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b26	=	((wrt_addr_1 == 5'b11010) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b27	=	((wrt_addr_1 == 5'b11011) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b28	=	((wrt_addr_1 == 5'b11100) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b29	=	((wrt_addr_1 == 5'b11101) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b30	=	((wrt_addr_1 == 5'b11110) & we_CPU_1)	? 1'b1 : 1'b0;
assign	we_b31	=	((wrt_addr_1 == 5'b11111) & we_CPU_1)	? 1'b1 : 1'b0;

// Final Write Enable //
assign	we_0 	=	(we_a0  | we_b0 );
assign	we_1 	=	(we_a1  | we_b1 );
assign	we_2 	=	(we_a2  | we_b2 );
assign	we_3 	=	(we_a3  | we_b3 );
assign	we_4 	=	(we_a4  | we_b4 );
assign	we_5 	=	(we_a5  | we_b5 );
assign	we_6 	=	(we_a6  | we_b6 );
assign	we_7 	=	(we_a7  | we_b7 );
assign	we_8 	=	(we_a8  | we_b8 );
assign	we_9 	=	(we_a9  | we_b9 );
assign	we_10	=	(we_a10 | we_b10);
assign	we_11	=	(we_a11 | we_b11);
assign	we_12	=	(we_a12 | we_b12);
assign	we_13	=	(we_a13 | we_b13);
assign	we_14	=	(we_a14 | we_b14);
assign	we_15	=	(we_a15 | we_b15);
assign	we_16	=	(we_a16 | we_b16);
assign	we_17	=	(we_a17 | we_b17);
assign	we_18	=	(we_a18 | we_b18);
assign	we_19	=	(we_a19 | we_b19);
assign	we_20	=	(we_a20 | we_b20);
assign	we_21	=	(we_a21 | we_b21);
// Flags Register
// SPART (key presses) 3 - UP 2 - DOWN 1 - LEFT 0 - RIGHT
// I can remove the ability to write to Flags/RO from CPU
assign	we_22	=	 cpu_flags_we | SPART_we | (we_a22 | we_b22);
// Return Object Register
assign	we_23	=	 we_VPU | (we_a23 | we_b23);
// Vertex Registers
assign	we_24	=	(we_a24 | we_b24 | we_VPU);
assign	we_25	=	(we_a25 | we_b25 | we_VPU);
assign	we_26	=	(we_a26 | we_b26 | we_VPU);
assign	we_27	=	(we_a27 | we_b27 | we_VPU);
assign	we_28	=	(we_a28 | we_b28 | we_VPU);
assign	we_29	=	(we_a29 | we_b29 | we_VPU);
assign	we_30	=	(we_a30 | we_b30 | we_VPU);
assign	we_31	=	(we_a31 | we_b31 | we_VPU);

// Assign write Data (Priority: VPU > A > B) //
assign	wrt_data_R0 	= (we_a0 ) ? wrt_data_0 :
                          (we_b0 ) ? wrt_data_1 :
                           R0;
assign	wrt_data_R1 	= (we_a1 ) ? wrt_data_0 :
                          (we_b1 ) ? wrt_data_1 :
                           R1;
assign	wrt_data_R2 	= (we_a2 ) ? wrt_data_0 :
                          (we_b2 ) ? wrt_data_1 :
                           R2;
assign	wrt_data_R3 	= (we_a3 ) ? wrt_data_0 :
                          (we_b3 ) ? wrt_data_1 :
                           R3;
assign	wrt_data_R4 	= (we_a4 ) ? wrt_data_0 :
                          (we_b4 ) ? wrt_data_1 :
                           R4;
assign	wrt_data_R5 	= (we_a5 ) ? wrt_data_0 :
                          (we_b5 ) ? wrt_data_1 :
                           R5;
assign	wrt_data_R6 	= (we_a6 ) ? wrt_data_0 :
                          (we_b6 ) ? wrt_data_1 :
                           R6;
assign	wrt_data_R7 	= (we_a7 ) ? wrt_data_0 :
                          (we_b7 ) ? wrt_data_1 :
                           R7;
assign	wrt_data_R8 	= (we_a8 ) ? wrt_data_0 :
                          (we_b8 ) ? wrt_data_1 :
                           R8;
assign	wrt_data_R9 	= (we_a9 ) ? wrt_data_0 :
                          (we_b9 ) ? wrt_data_1 :
                           R9;
assign	wrt_data_R10	= (we_a10) ? wrt_data_0 :
                          (we_b10 ) ? wrt_data_1 :
                           R10;
assign	wrt_data_R11	= (we_a11) ? wrt_data_0 :
                          (we_b11) ? wrt_data_1 :
                           R11;
assign	wrt_data_R12	= (we_a12) ? wrt_data_0 :
                          (we_b12) ? wrt_data_1 :
                           R12;
assign	wrt_data_R13	= (we_a13) ? wrt_data_0 :
                          (we_b13) ? wrt_data_1 :
                           R13;
assign	wrt_data_R14	= (we_a14) ? wrt_data_0 :
                          (we_b14) ? wrt_data_1 :
                           R14;
assign	wrt_data_R15	= (we_a15) ? wrt_data_0 :
                          (we_b15) ? wrt_data_1 :
                           R15;
assign	wrt_data_R16	= (we_a16) ? wrt_data_0 :
                          (we_b16) ? wrt_data_1 :
                           R16;
assign	wrt_data_R17	= (we_a17) ? wrt_data_0 :
                          (we_b17) ? wrt_data_1 :
                           R17;
assign	wrt_data_R18	= (we_a18) ? wrt_data_0 :
                          (we_b18) ? wrt_data_1 :
                           R18;
assign	wrt_data_R19	= (we_a19) ? wrt_data_0 :
                          (we_b19) ? wrt_data_1 :
                           R19;
assign	wrt_data_R20	= (we_a20) ? wrt_data_0 :
                          (we_b20) ? wrt_data_1 :
                           R20;
assign	wrt_data_R21	= (we_a21) ? wrt_data_0 :
                          (we_b21) ? wrt_data_1 :
                           R21;
// Flags Register can only be written by CPU (user restricted) //
// TODO: Update from VPU/SPART as well so it may need some extra logic //
assign	wrt_data_R22	= (cpu_flags_we) ? {R22[15:3], cpu_flags}:
						  (SPART_we)	 ? {R22[15:8], R22[7:3] | SPART_keys, R22[2:0]}:
						  (we_a22)		 ?  wrt_data_0 :
                          (we_b22)       ?  wrt_data_1 :
                           R22;
// RO Register //
assign	wrt_data_R23	= (we_VPU) ? return_obj :
						  (we_a23) ? wrt_data_0 :
                          (we_b23) ? wrt_data_1 :
                           R23;
// Vertex Registers have more options //
assign	wrt_data_R24	= (we_VPU) ? wrt_V0 :
                          (we_a24) ? wrt_data_0 :
                          (we_b24) ? wrt_data_1 :
                           R24;
assign	wrt_data_R25	= (we_VPU) ? wrt_V1 :
                          (we_a25) ? wrt_data_0 :
                          (we_b25) ? wrt_data_1 :
                           R25;
assign	wrt_data_R26	= (we_VPU) ? wrt_V2 :
                          (we_a26) ? wrt_data_0 :
                          (we_b26) ? wrt_data_1 :
                           R26;
assign	wrt_data_R27	= (we_VPU) ? wrt_V3 :
                          (we_a27) ? wrt_data_0 :
                          (we_b27) ? wrt_data_1 :
                           R27;
assign	wrt_data_R28	= (we_VPU) ? wrt_V4 :
                          (we_a28) ? wrt_data_0 :
                          (we_b28) ? wrt_data_1 :
                           R28;
assign	wrt_data_R29	= (we_VPU) ? wrt_V5 :
                          (we_a29) ? wrt_data_0 :
                          (we_b29) ? wrt_data_1 :
                           R29;
assign	wrt_data_R30	= (we_VPU) ? wrt_V6 :
                          (we_a30) ? wrt_data_0 :
                          (we_b30) ? wrt_data_1 :
                           R30;
assign	wrt_data_R31	= (we_VPU) ? wrt_V7 :
                          (we_a31) ? wrt_data_0 :
                          (we_b31) ? wrt_data_1 :
                           R31;

////////////////////////////////////////////////////////////////////////////////
// Read
// Port 0 //
always @(*)begin
	case(reg_addr_0)
        5'b00000:reg_data_0 = R0 ;
        5'b00001:reg_data_0 = R1 ;
        5'b00010:reg_data_0 = R2 ;
        5'b00011:reg_data_0 = R3 ;
        5'b00100:reg_data_0 = R4 ;
        5'b00101:reg_data_0 = R5 ;
        5'b00110:reg_data_0 = R6 ;
        5'b00111:reg_data_0 = R7 ;
        5'b01000:reg_data_0 = R8 ;
        5'b01001:reg_data_0 = R9 ;
        5'b01010:reg_data_0 = R10;
        5'b01011:reg_data_0 = R11;
        5'b01100:reg_data_0 = R12;
        5'b01101:reg_data_0 = R13;
        5'b01110:reg_data_0 = R14;
        5'b01111:reg_data_0 = R15;
        5'b10000:reg_data_0 = R16;
        5'b10001:reg_data_0 = R17;
        5'b10010:reg_data_0 = R18;
        5'b10011:reg_data_0 = R19;
        5'b10100:reg_data_0 = R20;
        5'b10101:reg_data_0 = R21;
        5'b10110:reg_data_0 = R22;
        5'b10111:reg_data_0 = R23;
        5'b11000:reg_data_0 = R24;
        5'b11001:reg_data_0 = R25;
        5'b11010:reg_data_0 = R26;
        5'b11011:reg_data_0 = R27;
        5'b11100:reg_data_0 = R28;
        5'b11101:reg_data_0 = R29;
        5'b11110:reg_data_0 = R30;
        5'b11111:reg_data_0 = R31;
        default :reg_data_0 = R0 ;
	endcase
end

// Port 1 //
always @(*)begin
	case(reg_addr_1)
        5'b00000:reg_data_1 = R0 ;
        5'b00001:reg_data_1 = R1 ;
        5'b00010:reg_data_1 = R2 ;
        5'b00011:reg_data_1 = R3 ;
        5'b00100:reg_data_1 = R4 ;
        5'b00101:reg_data_1 = R5 ;
        5'b00110:reg_data_1 = R6 ;
        5'b00111:reg_data_1 = R7 ;
        5'b01000:reg_data_1 = R8 ;
        5'b01001:reg_data_1 = R9 ;
        5'b01010:reg_data_1 = R10;
        5'b01011:reg_data_1 = R11;
        5'b01100:reg_data_1 = R12;
        5'b01101:reg_data_1 = R13;
        5'b01110:reg_data_1 = R14;
        5'b01111:reg_data_1 = R15;
        5'b10000:reg_data_1 = R16;
        5'b10001:reg_data_1 = R17;
        5'b10010:reg_data_1 = R18;
        5'b10011:reg_data_1 = R19;
        5'b10100:reg_data_1 = R20;
        5'b10101:reg_data_1 = R21;
        5'b10110:reg_data_1 = R22;
        5'b10111:reg_data_1 = R23;
        5'b11000:reg_data_1 = R24;
        5'b11001:reg_data_1 = R25;
        5'b11010:reg_data_1 = R26;
        5'b11011:reg_data_1 = R27;
        5'b11100:reg_data_1 = R28;
        5'b11101:reg_data_1 = R29;
        5'b11110:reg_data_1 = R30;
        5'b11111:reg_data_1 = R31;
        default :reg_data_1 = R0 ;
	endcase
end

// VPU data always outputed //
assign read_RO = R23;
assign read_V0 = R24;
assign read_V1 = R25;
assign read_V2 = R26;
assign read_V3 = R27;
assign read_V4 = R28;
assign read_V5 = R29;
assign read_V6 = R30;
assign read_V7 = R31;

////////////////////////////////////////////////////////////////////////////////
// Write (D-Latch)
always @(we_0, wrt_data_R0 )begin
	if(we_0)
		R0 <= wrt_data_R0;
    else
        R0 <= wrt_data_R0;
end
always @(we_1, wrt_data_R1 )begin
	if(we_1)
		R1 <= wrt_data_R1;
    else
        R1 <= wrt_data_R1;
end
always @(we_2, wrt_data_R2 )begin
	if(we_2)
		R2 <= wrt_data_R2;
    else
        R2 <= wrt_data_R2;
end
always @(we_3, wrt_data_R3 )begin
	if(we_3)
		R3 <= wrt_data_R3;
    else
        R3 <= wrt_data_R3;
end
always @(we_4, wrt_data_R4 )begin
	if(we_4)
		R4 <= wrt_data_R4;
    else
        R4 <= wrt_data_R4;
end
always @(we_5, wrt_data_R5 )begin
	if(we_5)
		R5 <= wrt_data_R5;
    else
        R5 <= wrt_data_R5;
end
always @(we_6, wrt_data_R6 )begin
	if(we_6)
		R6 <= wrt_data_R6;
    else
        R6 <= wrt_data_R6;
end
always @(we_7, wrt_data_R7 )begin
	if(we_7)
		R7 <= wrt_data_R7;
    else
        R7 <= wrt_data_R7;
end
always @(we_8, wrt_data_R8 )begin
	if(we_8)
		R8 <= wrt_data_R8;
    else
        R8 <= wrt_data_R8;
end
always @(we_9, wrt_data_R9 )begin
	if(we_9)
		R9 <= wrt_data_R9;
    else
        R9 <= wrt_data_R9;
end
always @(we_10, wrt_data_R10 )begin
	if(we_10)
		R10 <= wrt_data_R10;
    else
        R10 <= wrt_data_R10;
end
always @(we_11, wrt_data_R11 )begin
	if(we_11)
		R11 <= wrt_data_R11;
    else
        R11 <= wrt_data_R11;
end
always @(we_12, wrt_data_R12 )begin
	if(we_12)
		R12 <= wrt_data_R12;
    else
        R12 <= wrt_data_R12;
end
always @(we_13, wrt_data_R13 )begin
	if(we_13)
		R13 <= wrt_data_R13;
    else
        R13 <= wrt_data_R13;
end
always @(we_14, wrt_data_R14 )begin
	if(we_14)
		R14 <= wrt_data_R14;
    else
        R14 <= wrt_data_R14;
end
always @(we_15, wrt_data_R15 )begin
	if(we_15)
		R15 <= wrt_data_R15;
    else
        R15 <= wrt_data_R15;
end
always @(we_16, wrt_data_R16 )begin
	if(we_16)
		R16 <= wrt_data_R16;
    else
        R16 <= wrt_data_R16;
end
always @(we_17, wrt_data_R17 )begin
	if(we_17)
		R17 <= wrt_data_R17;
    else
        R17 <= wrt_data_R17;
end
always @(we_18, wrt_data_R18 )begin
	if(we_18)
		R18 <= wrt_data_R18;
    else
        R18 <= wrt_data_R18;
end
always @(we_19, wrt_data_R19 )begin
	if(we_19)
		R19 <= wrt_data_R19;
    else
        R19 <= wrt_data_R19;
end
always @(we_20, wrt_data_R20 )begin
	if(we_20)
		R20 <= wrt_data_R20;
    else
        R20 <= wrt_data_R20;
end
always @(we_21, wrt_data_R21 )begin
	if(we_21)
		R21 <= wrt_data_R21;
    else
        R21 <= wrt_data_R21;
end
// Flags Register
always @(we_22, wrt_data_R22 )begin
	if(we_22)
		R22 <= wrt_data_R22;
    else
        R22 <= wrt_data_R22;
end
// Return Object Register
always @(we_23, wrt_data_R23 )begin
	if(we_23)
		R23 <= wrt_data_R23;
    else
        R23 <= wrt_data_R23;
end
// Vertex Registers
always @(we_24, wrt_data_R24 )begin
	if(we_24)
		R24 <= wrt_data_R24;
    else
        R24 <= wrt_data_R24;
end
always @(we_25, wrt_data_R25 )begin
	if(we_25)
		R25 <= wrt_data_R25;
    else
        R25 <= wrt_data_R25;
end
always @(we_26, wrt_data_R26 )begin
	if(we_26)
		R26 <= wrt_data_R26;
    else
        R26 <= wrt_data_R26;
end
always @(we_27, wrt_data_R27 )begin
	if(we_27)
		R27 <= wrt_data_R27;
    else
        R27 <= wrt_data_R27;
end
always @(we_28, wrt_data_R28 )begin
	if(we_28)
		R28 <= wrt_data_R28;
    else
        R28 <= wrt_data_R28;
end
always @(we_29, wrt_data_R29 )begin
	if(we_29)
		R29 <= wrt_data_R29;
    else
        R29 <= wrt_data_R29;
end
always @(we_30, wrt_data_R30 )begin
	if(we_30)
		R30 <= wrt_data_R30;
    else
        R30 <= wrt_data_R30;
end
always @(we_31, wrt_data_R31 )begin
	if(we_31)
		R31 <= wrt_data_R31;
    else
        R31 <= wrt_data_R31;
end

endmodule

