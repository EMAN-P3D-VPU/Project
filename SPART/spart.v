`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    spart 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//	Communication unit for the FPGA. This interacts with the RS232 line and is
//	able to receive and send information. Included four varying baud rates which
//	are set via dip switches.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module spart(
    input clk,
    input rst,
    input iocs,			// Chip select? -> To Controls
    input iorw,			// Determines the direction 1:SPART->CPU 0:CPU->SPART
    output rda,			// Byte rdy for read SPART->CPU (reset on read op)
    output tbr,			// Tx buf rdy CPU->SPART (reset on write)
    input [1:0] ioaddr,	// Select register that interacts with DATABUS
    inout [7:0] databus,// 3-state bidirectional bus
    output txd,			// TxShift Reg -> TxD
    input rxd			// RxShift Reg <- RxD
    );

////////////
// Inputs //
////////////

/////////////
// Outputs //
/////////////

/////////////
// Signals //
/////////////
wire busInt_clr_rda;
wire busInt_transmit;
wire [7:0] busInt_tx_data;
wire baudGn_en;
wire txUnit_tbr;
wire [7:0] rxUnit_rx_data;
wire rxUnit_rda;

//////////////////////////////////////////////////////////////////////////////////
// SPART
////

assign rda = rxUnit_rda;
assign tbr = txUnit_tbr;

// Bus Interface //
bus_interface busInt(.databus(databus),
					 .rx_data(rxUnit_rx_data),
					 .ioaddr(ioaddr),
					 .iorw(iorw),
					 .iocs(iocs),
					 .tbr(txUnit_tbr),
					 .rda(rxUnit_rda),
					 .clr_rda(busInt_clr_rda),
					 .transmit(busInt_transmit),
					 .tx_data(busInt_tx_data));

// Baud Rate Generator //
baud_gen baudGn(.clk(clk),
				.rst(rst),
				.divisor(busInt_tx_data),
				.ioaddr(ioaddr),
				.en(baudGn_en));

// Tx Unit //
tx_unit txUnit(.clk(clk),
			   .rst(rst),
			   .tx_data(busInt_tx_data),
			   .tx_en(baudGn_en),
			   .transmit(busInt_transmit),
			   .tbr(txUnit_tbr),
			   .txd(txd));

// Rx Unit //
rx_unit rxUnit(.clk(clk),
			   .rst(rst),
			   .rx_en(baudGn_en),
			   .rxd(rxd),
			   .clr_rda(busInt_clr_rda),
			   .rx_data(rxUnit_rx_data),
			   .rda(rxUnit_rda));

endmodule
