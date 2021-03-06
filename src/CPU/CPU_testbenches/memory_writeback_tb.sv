////////////////////////////////////////////////////////////////////////////////
// memory_writeback_tb.sv
// Dan Wortmann
//
// Description:
// Quite a trivial logic unit, will only test if needed.
////////////////////////////////////////////////////////////////////////////////
module memory_writeback_tb();
////////////
// Inputs /
//////////
logic clk, rst_n;

/////////////
// Outputs /
///////////

///////////////////
// Interconnects /
/////////////////

////////////////////
// Instantiations /
//////////////////

////////////////////////////////////////////////////////////////////////////////
// memory_writeback_tb
////

// Clock //
always
    #2 clk = ~clk;

// Fail Safe Stop //
initial
    #1000 $stop;

// Main Test Loop //
initial begin
    clk = 0;
    rst_n = 0;
    $display("rst assert\n");
    @(negedge clk) rst_n = 1;
    $display("rst deassert\n");


    repeat(2) @(posedge clk);
    $stop;
end

endmodule
