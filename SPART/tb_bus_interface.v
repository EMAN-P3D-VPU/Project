`timescale 1ns / 1ps
module tb_bus_interface();

// inputs
reg iocs, iorw, rda, tbr;
reg [1:0] ioaddr;
reg [7:0] receive;

// outputs
wire [7:0] databus, dataIn;

bus_interface test( .iocs(iocs),
		.iorw(iorw),
		.rda(rda),
		.tbr(tbr),
		.ioaddr(ioaddr),
		.receive(receive),
		.databus(databus),
		.dataIn(dataIn));

// need to set up fake three-state driver for databus
reg [7:0] dataOut;
reg enable;

assign databus = enable ? dataOut : 8'hz;

initial begin
	enable = 0;
	iocs = 0;
	iorw = 0;
	rda = 0;
	tbr = 0;
	ioaddr = 2'b00;
	receive = 8'h8A;

	#1
	$display("Databus should have 0xz and it has %h", databus);

	// read from receive
	iocs = 1;
	iorw = 1;
	#1
	$display("Databus should have 0x8A and it has %h", databus);

	// read from status register
	ioaddr = 2'b01;
	rda = 1;
	#1
	$display("Databus should have 0x01 and it has %h", databus);

	tbr = 1;
	#1
	$display("Databus should have 0x03 and it has %h", databus);
	
	// write to dbLow
	iorw = 0;
	ioaddr = 2'b10;
	enable = 1;
	dataOut = 8'h54;
	#1
	$display("DataIn should have 0x54 and it has %h", dataIn);
	
	//write to dbHigh
	iorw = 0;
	ioaddr = 2'b11;
	enable = 1;
	dataOut = 8'h36;
	#1	
	$display("DataIn should have 0x36 and it has %h", dataIn);
end

endmodule