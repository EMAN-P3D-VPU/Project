`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    
// Design Name: 
// Module Name:    driver 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//	This unit simulates the behavior a processor might take in order to move
//	data via serial. For the sake of this project, whenever data is ready in
//  the SPART, the unit asserts the databus to receive said data and follows
//	up by sending it back into the TX buffer.
//
//	Additionally, the unit sets the baud rate based on the set dip switches
//	for varying speeds of communication.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module driver(
    input clk,
    input rst,
    input [1:0] br_cfg,
    output iocs,
    output iorw,
    input rda,
    input tbr,
    output [1:0] ioaddr,
    inout [7:0] databus
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
reg iorw_r;
reg [1:0] ioaddr_r;
reg set_baud_rate;
reg save_data;
reg [7:0] send_data;
reg [7:0] data_received_reg;
reg [15:0] baud_rate;

wire [15:0] next_baud_rate;

// States //
localparam IDLE		= 3'b000;
localparam RECV		= 3'b001;
localparam SEND		= 3'b010;
localparam DB_LOW	= 3'b011;
localparam DB_HIGH	= 3'b100;

reg [2:0] state, next_state;

//////////////////////////////////////////////////////////////////////////////////
// DRIVER
////

// Loop back anything from SPART RX to be sent via TX // (Temporary)
assign iorw = iorw_r;
assign iocs = 1'b1; // In this case just always select the SPART
assign ioaddr = ioaddr_r;

// State Change //
always@(posedge clk, posedge rst)begin
	if(rst)
		state <= IDLE;
	else
		state <= next_state;
end

// Set Divisor based on dip switches //
assign next_baud_rate =	(br_cfg == 2'b00) ? 16'h0515: //  4800 @100MHz
						(br_cfg == 2'b01) ? 16'h028A: //  9600 @100MHz
						(br_cfg == 2'b10) ? 16'h0144: // 19200 @100MHz
									    	16'h00A2; // 38400 @100MHz

// Save baud rate on master side //
always@(posedge clk, posedge rst)begin
	if(rst)
		baud_rate <= 16'h028A;
	else if(set_baud_rate)
		baud_rate <= next_baud_rate;
	else
		baud_rate <= baud_rate;
end

// Save received data to echo back //
always@(posedge clk, posedge rst)begin
	if(rst)
		data_received_reg <= 8'h00;
	else if(save_data)
		data_received_reg <= databus;
	else
		data_received_reg <= data_received_reg;
end

// DATABUS //
assign databus = (~iorw) ? send_data : 8'hZZ;

// Control Unit //
always@(*) begin
	// Defaults //
	set_baud_rate = 0;
	iorw_r = 1;
	ioaddr_r = 2'b01; // Read status by default
	send_data = data_received_reg;
	save_data = 0;

	case(state)
		// Wait for operations //
		IDLE:begin
			if(rda)
				next_state = RECV;
			else if(baud_rate != next_baud_rate)
				next_state = DB_LOW;
			else
				next_state = IDLE;
		end
		// Read data from SPART //
		RECV:begin
			iorw_r = 1;
			ioaddr_r = 2'b00;
			save_data = 1;
			next_state = SEND;
		end
		// Transmit data via SPART //
		SEND:begin
			if(tbr)begin
				iorw_r = 0;
				ioaddr_r = 2'b00;
				next_state = IDLE;
			end else
				next_state = SEND;
		end
		// Set baud rate - low //
		DB_LOW:begin
			iorw_r = 0;
			ioaddr_r = 2'b10;
			set_baud_rate = 1;
			send_data = next_baud_rate[7:0];
			next_state = DB_HIGH;
		end
		// Set baud rate - high //
		DB_HIGH:begin
			iorw_r = 0;
			ioaddr_r = 2'b11;
			send_data = next_baud_rate[15:8];
			next_state = IDLE;
		end
		default: next_state = IDLE;
	endcase
end

endmodule

