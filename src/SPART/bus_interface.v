`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    bus_interface 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//	A select module which controls a two way databus between the SPART and the
//	processor unit. Based on the input ioaddrs the databus either receives data
//	or sends data to the processor.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module bus_interface(databus,
					 rx_data,
					 ioaddr,
					 iorw,
					 iocs,
					 tbr,
					 rda,
					 clr_rda,
					 transmit,
					 tx_data);

////////////
// Inputs //
////////////
inout wire [7:0] databus;
input wire [7:0] rx_data;
input wire [1:0] ioaddr;
input wire iorw;
input wire iocs;
input wire tbr;
input wire rda;

/////////////
// Outputs //
/////////////
output reg transmit;
output reg clr_rda;
output reg [7:0] tx_data;

/////////////
// Signals //
/////////////
localparam DATA		= 2'b00;
localparam STATUS	= 2'b01;

reg [7:0] send_data;

//////////////////////////////////////////////////////////////////////////////////
// Bus Interface
////

assign databus = (iorw & iocs) ? send_data : 8'hZZ; // IOCS drives ZZ?

always@(*) begin
	// defaults //
	send_data = rx_data;
	clr_rda = 0;
	transmit = 0;
	tx_data = databus;

	case(ioaddr)
		// Send of receive data //
		DATA:begin
			if(iorw)begin
				clr_rda = 1;
				send_data = rx_data;
			end else begin
				transmit = 1;
			end
		end
		// Send Status bits to CPU //
		STATUS:begin
			send_data = {6'h00, tbr, rda};
		end
	endcase
end

endmodule
