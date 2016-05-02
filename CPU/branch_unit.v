////////////////////////////////////////////////////////////////////////////////
// branch_unit.v
// Dan Wortmann
//
// Description:
// Control unit for incrementing the PC for Jump and Branch instructions.
////////////////////////////////////////////////////////////////////////////////
module branch_unit(
    // Inputs //
    branch,
    jump,
    condition_code,
    condition_flags,
    PC_plus_one,
    branch_offset,
    jump_offset,
    // Outputs //
    PC_select,
    PC_next,
    PC_return
    );
////////////
// Inputs /
//////////
input               branch;
input               jump;
input       [2:0]   condition_code;
input       [2:0]   condition_flags;
input signed [15:0]  PC_plus_one;
input signed [15:0]  branch_offset;      // Sign X'ed
input signed [15:0]  jump_offset;        // Sign X'ed immd OR Rt

/////////////
// Outputs /
///////////
output              PC_select;          // 1-Take new PC
output signed [15:0]  PC_next;
output      [15:0]  PC_return;

/////////////////////////////
// Signals/Logic/Registers /
///////////////////////////
reg     valid_B;

///////////////////
// Interconnects /
/////////////////
wire	signed [15:0]  PC_branch;
wire    signed [15:0]  PC_jump;

///////////////////////
// Branch Conditions //
///////////////////////
localparam U        = 3'h0;
localparam EQ       = 3'h1;
localparam NE       = 3'h2;
localparam GT       = 3'h3;
localparam GTE      = 3'h4;
localparam LT       = 3'h5;
localparam LTE      = 3'h6;
localparam OF       = 3'h7;

////////////////////////////////////////////////////////////////////////////////
// branch_unit
////
// Jump to new PC select //
assign PC_select = (valid_B & branch) | jump;
assign PC_next   = (branch) ? PC_branch:
                   (jump)   ? PC_jump:
                              PC_plus_one;

// Branching Logic //
assign Z = condition_flags[2];
assign N = condition_flags[1];
assign V = condition_flags[0];

assign PC_branch = PC_plus_one + branch_offset;

always@(*) begin
    // defaults //
    valid_B = 0;

    // BRANCH //
    case(condition_code)
        // Not Equal //
        NE:begin
            if(!Z)
                valid_B = (branch) ? 1 : 0;
        end
        // Equal //
        EQ:begin
            if(Z)
                valid_B = (branch) ? 1 : 0;
        end
        // Greater Than //
        GT:begin
            if(!(Z|N))
                valid_B = (branch) ? 1 : 0;
        end
        // Less Than //
        LT:begin
            if(N)
                valid_B = (branch) ? 1 : 0;
        end
        // Greater Than or Equal To //
        GTE:begin
            if(Z|!(Z|N))
                valid_B = (branch) ? 1 : 0;
        end
        // Less Than or Equal To //
        LTE:begin
            if(N|Z)
                valid_B = (branch) ? 1 : 0;
        end
        // Overflow //
        OF:begin
            if(V)
                valid_B = (branch) ? 1 : 0;
        end
        // Unconditional //
        U:begin
            valid_B = (branch) ? 1 : 0;
        end
        default: valid_B = 0;
    endcase 
end

// Jump Logic //
assign PC_jump = PC_plus_one + jump_offset;
assign PC_return =  PC_plus_one;

endmodule
