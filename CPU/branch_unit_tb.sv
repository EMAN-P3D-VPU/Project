////////////////////////////////////////////////////////////////////////////////
// branch_unit_tb.sv
// Dan Wortmann
//
// Description:
// Make sure the PC control logic for jump and branch instructions is functioning.
// This is not a complicated module but should  be verified seperately for basic
// multiplexing and logic. Consider changing the unit to limit the address space
// here as well? In the case we don't really need full 16-bit memory access...
////////////////////////////////////////////////////////////////////////////////
module branch_unit_tb();
////////////
// Inputs /
//////////
logic           clk, rst_n;
logic           branch;
logic           jump;
logic   [2:0]   condition_code;
logic   [2:0]   condition_flags;
logic   [15:0]  PC_plus_one;
logic   [15:0]  branch_offset;
logic   [15:0]  jump_offset;

/////////////
// Outputs /
///////////
wire                PC_select;
wire        [15:0]  PC_next;
wire        [15:0]  PC_return;

///////////////////
// Interconnects /
/////////////////
integer i, j, k;
logic   [15:0]  GOLD_JUMP, GOLD_BRANCH;

////////////////////
// Instantiations /
//////////////////
branch_unit pc_ctrl(
    // Inputs //
    .branch(branch),
    .jump(jump),
    .condition_code(condition_code),
    .condition_flags(condition_flags),
    .PC_plus_one(PC_plus_one),
    .branch_offset(branch_offset),
    .jump_offset(jump_offset),
    // Outputs //
    .PC_select(PC_select),
    .PC_next(PC_next),
    .PC_return(PC_return)
);

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
// branch_unit_tb
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
    branch = 0; jump = 0;
    condition_code  = U;
    condition_flags = 3'b000;
    PC_plus_one   = 16'h0000;
    branch_offset = 16'h0000;
    jump_offset   = 16'h0000;
    $display("rst assert\n");
    @(negedge clk) rst_n = 1;
    $display("rst deassert\n");

    // Jump Logic //---------------------------------------------------------------
    @(posedge clk);
    jump = 1;
    PC_plus_one   = 16'h0000;
    jump_offset   = 16'h0000;

    for(i = 0; i <= 65535; i = i + 1)begin
        @(posedge clk);
        PC_plus_one = i;
        jump_offset = (2*i) % 65535;
        GOLD_JUMP = jump_offset + PC_plus_one;
        @(negedge clk);
        if(GOLD_JUMP !== PC_next || PC_select !== 1)begin
            $display("Jump was miscalculated to %d EXPECTED: %d", PC_next, GOLD_JUMP);
            $stop;
        end
    end

    jump = 0;

    // Branch Logic //-------------------------------------------------------------
    // UNCONDITIONAL test basic operation //
    @(posedge clk);
    branch = 1;
    condition_code  = U;
    condition_flags = 3'b000;
    PC_plus_one   = 16'h0000;
    branch_offset   = 16'h0000;

    for(i = 0; i <= 65535; i = i + 1)begin
        @(posedge clk);
        PC_plus_one = i;
        branch_offset = (2*i) % 65535;
        GOLD_BRANCH = branch_offset + PC_plus_one;
        @(negedge clk);
        if(GOLD_BRANCH !== PC_next || PC_select !== 1)begin
            $display("U Branch was miscalculated to %d EXPECTED: %d", PC_next, GOLD_BRANCH);
            $stop;
        end
    end

    // Check Branch condition codes now //
    // EQ //
    @(posedge clk);
    condition_code  = EQ;
    condition_flags = 3'b000; // Z N V

    @(negedge clk);
    if(PC_select !== 0)begin
        $display("EQ Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    @(posedge clk);
    condition_code  = EQ;
    condition_flags = 3'b100; // Z N V

    @(negedge clk);
    if(PC_select !== 1)begin
        $display("EQ Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    // NE //
    @(posedge clk);
    condition_code  = NE;
    condition_flags = 3'b000; // Z N V

    @(negedge clk);
    if(PC_select !== 1)begin
        $display("NE Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    @(posedge clk);
    condition_code  = NE;
    condition_flags = 3'b100; // Z N V

    @(negedge clk);
    if(PC_select !== 0)begin
        $display("NE Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    // GT //
    @(posedge clk);
    condition_code  = GT;
    condition_flags = 3'b000; // Z N V

    @(negedge clk);
    if(PC_select !== 1)begin
        $display("GT Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    @(posedge clk);
    condition_code  = GT;
    condition_flags = 3'b100; // Z N V

    @(negedge clk);
    if(PC_select !== 0)begin
        $display("GT Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    @(posedge clk);
    condition_code  = GT;
    condition_flags = 3'b010; // Z N V

    @(negedge clk);
    if(PC_select !== 0)begin
        $display("GT Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    // GTE //
    @(posedge clk);
    condition_code  = GTE;
    condition_flags = 3'b000; // Z N V

    @(negedge clk);
    if(PC_select !== 1)begin
        $display("GTE Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    @(posedge clk);
    condition_code  = GTE;
    condition_flags = 3'b100; // Z N V

    @(negedge clk);
    if(PC_select !== 1)begin
        $display("GTE Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    @(posedge clk);
    condition_code  = GTE;
    condition_flags = 3'b010; // Z N V

    @(negedge clk);
    if(PC_select !== 0)begin
        $display("GTE Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    // LT //
    @(posedge clk);
    condition_code  = LT;
    condition_flags = 3'b010; // Z N V

    @(negedge clk);
    if(PC_select !== 1)begin
        $display("LT Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    @(posedge clk);
    condition_code  = LT;
    condition_flags = 3'b101; // Z N V

    @(negedge clk);
    if(PC_select !== 0)begin
        $display("LT Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    // LTE //
    @(posedge clk);
    condition_code  = LTE;
    condition_flags = 3'b100; // Z N V

    @(negedge clk);
    if(PC_select !== 1)begin
        $display("LTE Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    @(posedge clk);
    condition_code  = LTE;
    condition_flags = 3'b010; // Z N V

    @(negedge clk);
    if(PC_select !== 1)begin
        $display("LTE Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    @(posedge clk);
    condition_code  = LTE;
    condition_flags = 3'b001; // Z N V

    @(negedge clk);
    if(PC_select !== 0)begin
        $display("LTE Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    // OF //
    @(posedge clk);
    condition_code  = OF;
    condition_flags = 3'b001; // Z N V

    @(negedge clk);
    if(PC_select !== 1)begin
        $display("OF Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    @(posedge clk);
    condition_code  = OF;
    condition_flags = 3'b100; // Z N V

    @(negedge clk);
    if(PC_select !== 0)begin
        $display("OF Branch condition was wrong %b EXPECTED: %b", PC_select, ~PC_select);
        $stop;
    end

    repeat(25) @(posedge clk);
    $stop;
end

endmodule
