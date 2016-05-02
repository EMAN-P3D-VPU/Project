////////////////////////////////////////////////////////////////////////////////
// alu_tb.sv
// Dan Wortmann
//
// Description:
// Main test bench for ALU operations. Exhaustively tests ADD operation. The
// remaining operations are tested to some extent given their basic nature.
////////////////////////////////////////////////////////////////////////////////
module alu_tb();
////////////
// Inputs /
//////////
logic           clk, rst_n;
logic   [15:0]  op0, op1;
logic   [2:0]   ALU_op;
logic   [3:0]   shamt;
logic           X;

/////////////
// Outputs /
///////////
wire    [15:0]  result;
wire            N,Z,V;

///////////////////
// Interconnects /
/////////////////
logic   [15:0]  GOLD_RESULT;

////////////////////
// Instantiations /
//////////////////
alu iALU(.op0(op0), .op1(op1), .ALU_op(ALU_op),
         .shamt(shamt), .X(X), .result(result),
         .Z(Z), .N(N), .V(V)
         );

////////////////////////////////////////////////////////////////////////////////
// alu_tb
////

// ALU Operations //
localparam AND  = 3'b000;
localparam OR   = 3'b001;
localparam XOR  = 3'b010;
localparam NOT  = 3'b011;
localparam ADD  = 3'b100;
localparam LSL  = 3'b101;
localparam SR   = 3'b110;
localparam ROT  = 3'b111;

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
    op0 = 16'h0000;
    op1 = 16'h0000;
    ALU_op = AND;
    shamt = 4'h0;
    X = 0;
    $display("rst assert\n");
    @(negedge clk) rst_n = 1;
    $display("rst deassert\n");

    // Test AND -------------------------------------------------------------------
    $display("AND test starting... ");
    @(posedge clk);
    ALU_op = AND;
    //shamt = 4'h0;
    //X = 0;
    op0 = 16'h0000;
    op1 = 16'h0000;

    repeat(1000)begin
        GOLD_RESULT = op0 & op1;
        
        @(posedge clk);
        if(GOLD_RESULT !== result)begin
            $display("Incorrect logical AND result. \nA:%b \nB:%b \nR:%b\t EXPECTED: %b",
                     op0, op1, result, GOLD_RESULT);
            $stop;
        end

        op0 += 1;
        op1 += 2;
    end

    $display("\t\t\t\tPASSED");
    // Test OR --------------------------------------------------------------------
    $display("OR test starting... ");
    @(posedge clk);
    ALU_op = OR;
    //shamt = 4'h0;
    //X = 0;
    op0 = 16'h0000;
    op1 = 16'h0000;

    repeat(1000)begin
        GOLD_RESULT = op0 | op1;
        
        @(posedge clk);
        if(GOLD_RESULT !== result)begin
            $display("Incorrect logical OR result. \nA:%b \nB:%b \nR:%b\t EXPECTED: %b",
                     op0, op1, result, GOLD_RESULT);
            $stop;
        end

        op0 += 1;
        op1 += 2;
    end

    $display("\t\t\t\tPASSED");
    // Test XOR -------------------------------------------------------------------
    $display("XOR test starting... ");
    @(posedge clk);
    ALU_op = XOR;
    //shamt = 4'h0;
    //X = 0;
    op0 = 16'h0000;
    op1 = 16'h0000;

    repeat(1000)begin
        GOLD_RESULT = op0 ^ op1;
        
        @(posedge clk);
        if(GOLD_RESULT !== result)begin
            $display("Incorrect logical XOR result. \nA:%b \nB:%b \nR:%b\t EXPECTED: %b",
                     op0, op1, result, GOLD_RESULT);
            $stop;
        end

        op0 += 1;
        op1 += 2;
    end

    $display("\t\t\t\tPASSED");
    // Test NOT -------------------------------------------------------------------
    $display("NOT test starting... ");
    @(posedge clk);
    ALU_op = NOT;
    //shamt = 4'h0;
    //X = 0;
    op0 = 16'h0000;
    op1 = 16'h0000;

    repeat(1000)begin
        GOLD_RESULT = ~op0;
        
        @(posedge clk);
        if(GOLD_RESULT !== result)begin
            $display("Incorrect logical NOT result. \nA:%b \nR:%b\t EXPECTED: %b",
                     op0, result, GOLD_RESULT);
            $stop;
        end

        op0 += 1;
    end

    $display("\t\t\t\tPASSED");
    // Test ADD -------------------------------------------------------------------
    $display("ADD test starting... ");
    @(posedge clk);
    ALU_op = ADD;
    //shamt = 4'h0;
    //X = 0;
    op0 = 16'h0000;
    op1 = 16'h0000;

    repeat(65536)begin
        GOLD_RESULT = op0 + op1;
        
        @(posedge clk);
        if(V)begin
            if((result !== 16'h7FFF) && (result !== 16'h8000))begin
                $display("Incorrect V flag/truncation. \nA:%d \nB:%d \nR:%d\t MAX: 32767 MIN: -32768",
                         op0, op1, result);
                $stop;
            end
        end
        else if(GOLD_RESULT !== result)begin
            $display("Incorrect ADD result. \nA:%d \nB:%d \nR:%d\t EXPECTED: %d",
                     op0, op1, result, GOLD_RESULT);
            $stop;
        end
        // Check negative flag //
        if(result[15] && ~N)begin
            $display("Incorrect N flag. \nA:%d \nB:%d \nR:%d\t EXPECTED: %d",
                     op0, op1, result, GOLD_RESULT);
            $stop;
        end

        op0 += 1;
        op1 += 2;
    end

    $display("\t\t\t\tPASSED");
    // Test LSL -------------------------------------------------------------------
    $display("LSL test starting... ");
    @(posedge clk);
    ALU_op = LSL;
    shamt = 4'h0;
    //X = 0;
    op0 = 16'h0000;
    op1 = 16'h0000;

    repeat(1000)begin
        GOLD_RESULT = op0 << shamt;
        
        @(posedge clk);
        if(GOLD_RESULT !== result)begin
            $display("Incorrect LSL result. \nA:%b \nR:%b\t EXPECTED: %b",
                     op0, result, GOLD_RESULT);
            $stop;
        end

        op0 += 1;
        shamt += 1;
    end

    $display("\t\t\t\tPASSED");
    // Test LSR --------------------------------------------------------------------
    $display("LSR test starting... ");
    @(posedge clk);
    ALU_op = SR;
    shamt = 4'h0;
    X = 0;
    op0 = 16'h0000;
    op1 = 16'h0000;

    repeat(1000)begin
        GOLD_RESULT = op0 >> shamt;
        
        @(posedge clk);
        if(GOLD_RESULT !== result)begin
            $display("Incorrect LSR result. \nA:%b \nR:%b\t EXPECTED: %b",
                     op0, result, GOLD_RESULT);
            $stop;
        end

        op0 += 1;
        shamt += 1;
    end

    $display("\t\t\t\tPASSED");
    // Test ASR --------------------------------------------------------------------
    $display("ASR test starting... ");
    @(posedge clk);
    ALU_op = SR;
    shamt = 4'h0;
    X = 1;
    op0 = 16'h0000;
    op1 = 16'h0000;

    repeat(1000)begin
        GOLD_RESULT = op0 >>> shamt;
        
        @(posedge clk);
        if(GOLD_RESULT !== result)begin
            $display("Incorrect ASR result. \nA:%b \nR:%b\t EXPECTED: %b",
                     op0, result, GOLD_RESULT);
            $stop;
        end

        op0 += 1;
        shamt += 1;
    end

    $display("\t\t\t\tPASSED");
    // Test ROL -------------------------------------------------------------------
    $display("ROL test starting... ");
    @(posedge clk);
    ALU_op = ROT;
    shamt = 4'h0;
    X = 0;
    op0 = 16'h0000;
    op1 = 16'h0000;

    repeat(1000)begin
        GOLD_RESULT = {op0[14:0], op0[15]};
        
        @(posedge clk);
        if(GOLD_RESULT !== result)begin
            $display("Incorrect ROL result. \nA:%b \nR:%b\t EXPECTED: %b",
                     op0, result, GOLD_RESULT);
            $stop;
        end

        op0 += 1;
    end

    $display("\t\t\t\tPASSED");
    // Test ROL -------------------------------------------------------------------
    $display("ROR test starting... ");
    @(posedge clk);
    ALU_op = ROT;
    shamt = 4'h0;
    X = 1;
    op0 = 16'h0000;
    op1 = 16'h0000;

    repeat(1000)begin
        GOLD_RESULT = {op0[0], op0[15:1]};
        
        @(posedge clk);
        if(GOLD_RESULT !== result)begin
            $display("Incorrect ROR result. \nA:%b \nR:%b\t EXPECTED: %b",
                     op0, result, GOLD_RESULT);
            $stop;
        end

        op0 += 1;
    end

    $display("\t\t\t\tPASSED");

    // TEST FINISHED //
    repeat(2) @(posedge clk);
    $display("Testing FINISHED");
    $stop;
end

endmodule
