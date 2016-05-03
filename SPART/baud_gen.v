`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    baud_gen 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//	Continuously generates an enable signal based on a set baud rate. Reset every
//	time the unit reaches 0.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module baud_gen(clk,
				rst,
				divisor,
				ioaddr,
				en);

////////////
// Inputs //
////////////
input wire clk, rst;
input wire [7:0] divisor;
input wire [1:0] ioaddr;

/////////////
// Outputs //
/////////////
output wire en;

/////////////
// Signals //
/////////////
localparam DB_LOW	= 2'b10;
localparam DB_HIGH	= 2'b11;

reg [15:0] divisor_buf;
reg [15:0] down_counter; 

//////////////////////////////////////////////////////////////////////////////////
// Baud Generator
////

// Division Buffer //
always@(posedge clk, posedge rst)begin
	if(rst)
		divisor_buf <= 16'h028A; // Reset to 9600 @100Mhz
	else if(ioaddr == DB_LOW)
		divisor_buf[7:0] <= divisor;
	else if(ioaddr == DB_HIGH)
		divisor_buf[15:8] <= divisor;
	else
		divisor_buf <= divisor_buf;
end

// Down Counter //
always@(posedge clk, posedge rst)begin
	if(rst)
		down_counter <= 16'h028A; //Reset to 9600 @100Mhz
	else if(en)
		down_counter <= divisor_buf;
	else
		down_counter <= down_counter - 1;
end

// enable signal //
assign en = ~|down_counter;

endmodule
