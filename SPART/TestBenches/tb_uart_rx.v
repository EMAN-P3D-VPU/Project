`timescale 1ns / 1ps
module tb_uart_rx();

// inputs
reg clk, rst, enable, iocs, iorw, rxd;
reg [1:0] ioaddr;

// outputs
wire [7:0] receive_buffer;
wire rda;

uart_rx iDUT(
	.receive_buffer(receive_buffer),
	.rxd(rxd),
	.rda(rda),
	.clk(clk),
	.rx_en(enable),
	.rst(rst),
	.iocs(iocs),
	.iorw(iorw),
	.ioaddr(ioaddr));

initial begin
	rxd = 1; //The default, non-data transferring situation value
	clk = 0;
	rst = 0;
	enable = 0;
	iocs = 0;
	iorw = 0;
	ioaddr = 2'b01;
	@(negedge clk) rst = 1; //reseting the whole module
	@(negedge clk) rst = 0; 
	@(posedge clk) enable = 0;
	//Transmitting Begins
	rxd = 0; //Start Bit
	repeat(16)@(posedge enable);
	rxd = 1;
	repeat(16)@(negedge enable);
	rxd = 0;
	repeat(16)@(negedge enable);
	rxd = 1;
	repeat(16)@(negedge enable);
	rxd = 1;
	repeat(16)@(negedge enable);
	rxd = 0;
	repeat(16)@(negedge enable);
	rxd = 1;
	repeat(16)@(negedge enable);
	rxd = 0;
	repeat(16)@(negedge enable);
	rxd = 0;
	repeat(16)@(negedge enable);
	rxd = 1; //Stop Bit
	
	repeat(50)@(negedge enable);
	rxd = 0; //It will be wrong if FSM is running again
	
end

initial begin
	@(posedge rda) $display("Receiving Finishes");
	$stop;
end

initial begin
	repeat(10000)@(negedge clk);
	iocs = 1;
	iorw = 1;
	ioaddr = 2'b00;	
	@(negedge rda) $display("Processor begins to receiving data now");
	$stop;
	
end

initial begin
	repeat(100000)@(posedge clk);
	$display("Runtime Error");
	$stop;
end

always
  #4 clk = ~ clk;
  
always
  #16 enable = ~enable;  
  
endmodule