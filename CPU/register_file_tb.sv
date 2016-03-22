////////////////////////////////////////////////////////////////////////////////
// register_file_tb.sv
// Dan Wortmann
//
// Description:
// 
////////////////////////////////////////////////////////////////////////////////
module register_file_tb();
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
// register_file_tb
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
