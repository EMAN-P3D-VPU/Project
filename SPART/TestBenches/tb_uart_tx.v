`timescale 1ns / 1ps
module tb_uart_tx();

// inputs
reg [7:0] transmit_buffer;
reg clk, rst, enable, iocs, iorw;
reg [1:0] ioaddr;

// outputs
wire txd, tbr;

uart_tx iDUT(
	.transmit_buffer(transmit_buffer),
	.txd(txd),
	.tbr(tbr),
	.clk(clk),
	.tx_en(enable),
	.rst(rst),
	.iocs(iocs),
	.iorw(iorw),
	.ioaddr(ioaddr));

initial begin
	// byte to send
	transmit_buffer = 8'b11010010;
	clk = 0;
	rst = 0;
	enable = 0;
	iocs = 0;
	iorw = 1;
	ioaddr = 2'b01;
	@(negedge clk) rst = 1; //reseting the whole module
	@(negedge clk) rst = 0; 
	@(negedge clk) iocs = 1;
	iorw = 0;
	ioaddr = 2'b00;	
	@(negedge clk) iocs = 0;
end

initial begin
	@(posedge tbr) $display("Transmitting Begins");
	@(posedge tbr) $display("Transmitting Finishes");
	$stop;
end

initial begin
	repeat(10000)@(posedge clk);
	$display("Runtime Error");
	$stop;
end
	
always
	#4 clk = ~ clk;
  
always
	#16 enable = ~enable;  
endmodule