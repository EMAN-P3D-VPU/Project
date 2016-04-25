`timescale 1ns / 1ps
module tb_driver();

// inputs
reg clk, rst, rda, tbr;
reg [1:0] br_cfg;

// outputs
wire iocs, iorw;
wire [1:0] ioaddr;

// inout
wire [7:0] databus;

// databus helper variables
reg enable;
reg [7:0] dataOut;

assign databus = enable ? dataOut : 8'hz;

driver test( .clk(clk),
	.rst(rst),
	.rda(rda),
	.tbr(tbr),
	.br_cfg(br_cfg),
	.iocs(iocs),
	.iorw(iorw),
	.ioaddr(ioaddr),
	.databus(databus));

initial begin
	// test out 4800 -> should produce 0x516
	$display("DATABUS SHOULD PRINT OUT 0x516");
	clk = 0;
	rst = 1;
	rda = 0;
	tbr = 0;
	br_cfg = 2'b00;
	enable = 0;
	
	#10
	rst = 0;
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);
	#10
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);

	// test out 9600 -> should produce 0x28A
	$display("DATABUS SHOULD PRINT OUT 0x28A");
	rst = 1;
	rda = 0;
	tbr = 0;
	br_cfg = 2'b01;
	enable = 0;
	
	#10
	rst = 0;
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);
	#10
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);
	
	// test out 19200 -> should produce 0x145
	$display("DATABUS SHOULD PRINT OUT 0x145");
	rst = 1;
	rda = 0;
	tbr = 0;
	br_cfg = 2'b10;
	enable = 0;
	
	#10
	rst = 0;
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);
	#10
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);

	// test out 38400 -> should produce 0xA2
	$display("DATABUS SHOULD PRINT OUT 0xA2");
	rst = 1;
	rda = 0;
	tbr = 0;
	br_cfg = 2'b11;
	enable = 0;
	
	#10
	rst = 0;
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);
	#10
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);

	// now test for receive and transmit (0x54)
	$display("IN RECEIVE AND TRANSMIT 0x54");
	#20
	rda = 1;
	tbr = 0;
	enable = 1;
	dataOut = 8'h54;
	$display("RECEIVE");
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);
	
	#1
	$display("AS rda IS 1");
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);
	#9

	// go to transmit state
	enable = 0;
	rda = 0;
	$display("TRANSMIT");
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);

	// stay in transmit state
	#10
	$display("STAY IN TRANSMIT");
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);
	tbr = 1; // get out of transmit state
	#1
	$display("AS tbr IS 1");
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);
	#9
	$display("IN RECEIVE");
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);

	// now test for receive and transmit (0xAB)
	$display("IN RECEIVE AND TRANSMIT 0xAB");
	#20
	rda = 1;
	tbr = 0;
	enable = 1;
	dataOut = 8'hAB;
	$display("RECEIVE");
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);
	
	#1
	$display("AS rda IS 1");
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);
	#9

	// go to transmit state
	enable = 0;
	rda = 0;
	$display("TRANSMIT");
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);

	// stay in transmit state
	#10
	$display("STAY IN TRANSMIT");
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);
	tbr = 1; // get out of transmit state
	#1
	$display("AS tbr IS 1");
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);
	#9
	$display("IN RECEIVE");
	$display("databus: %h, iocs: %b, iorw: %b, ioaddr: %b", databus, iocs, iorw, ioaddr);

	$stop;
end

always #5 clk = !clk;
endmodule