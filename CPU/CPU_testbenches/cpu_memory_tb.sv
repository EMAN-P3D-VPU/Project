////////////////////////////////////////////////////////////////////////////////
// cpu_memory_tb.sv
// Dan Wortmann
//
// Description:
// Somewhat basic testbench for the memory unit using two read ports and single
// write port. According to Xilinx user manuals this should be directly
// synthesizeable - and potentially have IP blocks with this direct design. My
// intention here is to make sure I it actually runs in software tests.
////////////////////////////////////////////////////////////////////////////////
module cpu_memory_tb();
////////////
// Inputs /
//////////
logic           clk, rst_n;
logic           re_0, re_1, we;
logic   [15:0]  i_addr, d_addr;
logic   [15:0]  wrt_data;

/////////////
// Outputs /
///////////
wire    [15:0]  instr;
wire    [15:0]  read_data;

///////////////////
// Interconnects /
/////////////////
integer i, j, k;

////////////////////
// Instantiations /
//////////////////
cpu_memory MEMORY(
    // Inputs //
    .clk(clk),
    .re_0(re_0), .re_1(re_1), .we(we),
    .i_addr(i_addr),
    .d_addr(d_addr),
    .wrt_data(wrt_data),
    // Outputs //
    .instr(instr),
    .read_data(read_data)
);

////////////////////////////////////////////////////////////////////////////////
// cpu_memory_tb
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
    re_0 = 1; re_1 = 1;
    we = 0;
    i_addr = 16'h0000;
    d_addr = 16'h0000;
    wrt_data = 16'hABCD;
    $display("rst assert\n");
    @(negedge clk) rst_n = 1;
    $display("rst deassert\n");

    // Write Data to every Address thats equals the address //
    @(posedge clk);
    we = 1;

    for(i = 0; i <= 65535; i = i + 1)begin
        d_addr = i;
        wrt_data = i;
        @(posedge clk);
    end

    // Read Back the data for correctness (Both ports simultaneously) //
    i = 0;
    j = 0;
    we = 0;
    @(posedge clk);
    i_addr = 16'h0000;
    d_addr = 16'h0000;

    for(i = 0; i <= 65535; i = i + 1)begin
        j = (2*i) % 65535;
        i_addr = i;
        d_addr = j;
        @(negedge clk); // Give half a cycle to READ - it's not instant on FPGA
        if(instr !== i_addr)begin
            $display("Incorrect data read at address 0x%h : %h EXPECTED: %h",
                     i_addr, instr, i_addr);
            $stop;
        end

        if(read_data !== d_addr)begin
            $display("Incorrect data read at address 0x%h : %h EXPECTED: %h",
                     d_addr, read_data, d_addr);
            $stop;
        end
        @(posedge clk);
    end

    repeat(2) @(posedge clk);
    $stop;
end

endmodule
