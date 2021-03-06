////////////////////////////////////////////////////////////////////////////////
// VPU_register.v
// Dan Wortmann
//
// Description:
// Register that holds all data to interface with VPU end. When a CPU read a
// VPU instruction, the information gets loaded and held for the duration of
// the VPU processing time.
////////////////////////////////////////////////////////////////////////////////
module VPU_register(
    // Inputs //
    clk, rst_n, STALL,
    VPU_instr,
    VPU_object,
    VPU_start,
    VPU_rdy,
    V0_in,
    V1_in,
    V2_in,
    V3_in,
    V4_in,
    V5_in,
    V6_in,
    V7_in,
    RO_in,
    // Outputs //
    VPU_start_out,
    VPU_fill,
    VPU_obj_type,
    VPU_obj_color,
    VPU_op,
    VPU_code,
    VPU_obj_num,
    V0_out,
    V1_out,
    V2_out,
    V3_out,
    V4_out,
    V5_out,
    V6_out,
    V7_out,
    RO_out
);
////////////
// Inputs /
//////////
input               clk, rst_n, STALL;
input               VPU_start;
input               VPU_rdy;
input       [4:0]   VPU_object;
input       [15:0]  VPU_instr;
input       [15:0]  V0_in, V1_in, V2_in, V3_in, V4_in, V5_in, V6_in, V7_in, RO_in;
/////////////
// Outputs /
///////////
output  wire        VPU_start_out;
output  reg         VPU_fill;
output  reg [1:0]   VPU_obj_type;
output  reg [2:0]   VPU_obj_color;
output  reg [3:0]   VPU_op;
output  reg [3:0]   VPU_code;
output  [4:0]   VPU_obj_num;
output  reg [15:0]  V0_out, V1_out, V2_out, V3_out, V4_out, V5_out, V6_out, V7_out, RO_out;

/////////////////////////////
// Signals/Logic/Registers /
///////////////////////////
reg         VPU_start_r;

///////////////////
// Interconnects /
/////////////////
reg         fill;
reg [3:0]   op;
reg [3:0]   code;

/////////////////
// VPU Opcodes /
///////////////
localparam DRAW     = 5'b10000;
localparam ELLI     = 5'b10001;
localparam FILL     = 5'b10010;
localparam RMV      = 5'b10011;
localparam TRAN     = 5'b10100;
localparam ROT      = 5'b10101;
localparam SCALE    = 5'b10110;
localparam REFLECT  = 5'b10111;
localparam MAT      = 5'b11000;
localparam GETOBJ   = 5'b11001;

////////////////////////////////////////////////////////////////////////////////
// VPU_register
////

// Decode VPU_op and _code //
always@(*)begin
    // Defaults //
    op = 4'h0;
    fill = 0;
    code = {VPU_instr[1:0], VPU_instr[3:2]}; // [3:2] Point [1:0] Y,X Direction (TRANSLATE)

    // VPU_op //
    case(VPU_instr[15:11])
        DRAW   :begin
            op = 4'h0;
        end
        ELLI   :begin   // Dropped this Instruction //
            op = 4'h0;  // Dropped this Instruction //
        end             // Dropped this Instruction //
        FILL   :begin
            fill = 1;   // Canceled the VPU_start signal and ONLY signal FILL
        end
        RMV    :begin
            op = (VPU_instr[10]) ? 4'h2 : 4'h1;
        end
        TRAN   :begin
            op = (VPU_instr[10]) ? 4'h4 : 4'h3;
        end
        ROT    :begin
            op = (VPU_instr[10]) ? 4'h6 : 4'h7;
            code = VPU_instr[3:0];// [3] Centroid [2:0] Amount (ROT/SCALE)
        end
        SCALE  :begin
            op = 4'h5;
            code = VPU_instr[3:0];// [3] Centroid [2:0] Amount (ROT/SCALE)
        end
        REFLECT:begin
            op = (VPU_instr[1:0] == 2'h1) ? 4'h8:
                 (VPU_instr[1:0] == 2'h2) ? 4'h9:
                                            4'hA;
        end
        MAT    :begin
            op = (VPU_instr[10]) ? 4'hC : 4'hB;
        end
        GETOBJ :begin
            op = 4'hF;
        end
    endcase
end

// Flop VPU signals + registers //
always@(posedge clk)begin
    if(!rst_n)
        VPU_start_r <= 1'h0;
    else if(~VPU_rdy)
        VPU_start_r <= 1'h0;
    else if(~STALL | (STALL & VPU_start))
        VPU_start_r <= VPU_start & ~fill;
    else
        VPU_start_r <= VPU_start_r;
end

assign VPU_start_out = VPU_start_r; // Single Cycle for VPU_start

always@(posedge clk)begin
    if(!rst_n)begin
        VPU_op    <= 4'h0;
        VPU_code  <= 4'h0;
    end else if(~STALL | (STALL & VPU_start))begin
        VPU_op    <= op;
        VPU_code  <= code;
    end else begin 
        VPU_op    <= VPU_op;
        VPU_code  <= VPU_code;
    end
end

always@(posedge clk)begin
    if(!rst_n)
        VPU_fill      <= 1'h0;
    else if(~STALL | (STALL & VPU_start))
        VPU_fill      <= fill;
    else
        VPU_fill      <= VPU_fill;
end

always@(posedge clk)begin
    if(!rst_n)
        VPU_obj_type <= 2'h0;
    else if(~STALL | (STALL & VPU_start))
        VPU_obj_type <= VPU_instr[10:9];
    else
        VPU_obj_type <= VPU_obj_type;
end

always@(posedge clk)begin
    if(!rst_n)
        VPU_obj_color <= 3'h0;
    else if(~STALL | (STALL & VPU_start))
        VPU_obj_color <= VPU_instr[2:0];
    else
        VPU_obj_color <= VPU_obj_color;
end

assign VPU_obj_num = VPU_object;
//always@(posedge clk)begin
//    if(!rst_n)
//        VPU_obj_num <= 5'h0;
//    else if(~STALL | (STALL & VPU_start))
//        VPU_obj_num <= VPU_object;
//    else
//        VPU_obj_num <= VPU_obj_num;
//end

always@(posedge clk)begin
    if(!rst_n)begin
        V0_out <= 16'h0000;
        V1_out <= 16'h0000;
        V2_out <= 16'h0000;
        V3_out <= 16'h0000;
        V4_out <= 16'h0000;
        V5_out <= 16'h0000;
        V6_out <= 16'h0000;
        V7_out <= 16'h0000;
        RO_out <= 16'h0000;
    end else if(~STALL | (STALL & VPU_start))begin
        V0_out <= V0_in;
        V1_out <= V1_in;
        V2_out <= V2_in;
        V3_out <= V3_in;
        V4_out <= V4_in;
        V5_out <= V5_in;
        V6_out <= V6_in;
        V7_out <= V7_in;
        RO_out <= RO_in;
    end else begin
        V0_out <= V0_out;
        V1_out <= V1_out;
        V2_out <= V2_out;
        V3_out <= V3_out;
        V4_out <= V4_out;
        V5_out <= V5_out;
        V6_out <= V6_out;
        V7_out <= V7_out;
        RO_out <= RO_out;
    end
end

endmodule
