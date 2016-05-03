`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    tx_unit 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//	The TX unit of the SPART holds any data that is to be send via RS232. When
//	data is provided the state machines loads it to a register and asserts the
//	start bit. In the idle stage, the tx line is held to a 1 as to prepare for
//	any following data transactions.
//
//	The BUF state was mainly introduced to have the possibility of holding two
//	units of data at a time. One which is on standby and one which is being
//	currently shifted out. The tbr signal is asserted to only work with a single
//	data transaction for this project, but can be edited in the future.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module tx_unit(clk,
			   rst,
			   tx_data,
			   tx_en,
			   transmit,
			   tbr,
			   txd);

////////////
// Inputs //
////////////
input wire clk, rst;
input wire [7:0] tx_data;
input wire tx_en;
input wire transmit;

/////////////
// Outputs //
/////////////
output reg tbr;
output wire txd;

/////////////
// Signals //
/////////////
reg shift;
reg clr_tbr;
reg set_tbr;
wire atStopBit;
reg load_tx_buf;
reg load_shift_reg;
reg clr_bit_count;
reg clr_baud_count;
reg inc_bit;
wire baudDone;

reg [3:0] baudCount;
reg [3:0] bitCount;
reg [7:0] tx_buf;
reg [9:0] tx_shift_reg;

// States //
localparam IDLE		= 2'b00;
localparam BUF		= 2'b01;
localparam SEND		= 2'b10;

reg [1:0] state, next_state;

//////////////////////////////////////////////////////////////////////////////////
// Tx Unit
////

// State Change //
always@(posedge clk, posedge rst)begin
	if(rst)
		state <= IDLE;
	else
		state <= next_state;
end

// Transmit Buffer Ready //
always@(posedge clk, posedge rst)begin
	if(rst)
		tbr <= 1'b1;
	else if(clr_tbr)
		tbr <= 1'b0;
	else if(set_tbr)
		tbr <= 1'b1;
	else
		tbr <= tbr;
end

// Tx Buffer //
always@(posedge clk, posedge rst)begin
	if(rst)
		tx_buf <= 8'h00;
	else if(load_tx_buf)
		tx_buf <= tx_data;
	else
		tx_buf <= tx_buf;
end

// Tx Shift Register //
always@(posedge clk, posedge rst)begin
	if(rst)
		tx_shift_reg <= 10'h001;
	else if(load_shift_reg)
		tx_shift_reg <= {1'b1, tx_buf, 1'b0}; // START, data, STOP (LSB first)
	else if(shift)
		tx_shift_reg <= tx_shift_reg >>> 1;
	else
		tx_shift_reg <= tx_shift_reg;
end

assign txd = tx_shift_reg[0];

// Bit Counter //
always@(posedge clk, posedge rst)begin
	if(rst)
		bitCount <= 4'b0000;
	else if(clr_bit_count)
		bitCount <= 4'b0000;
	else if(inc_bit)
		bitCount <= bitCount + 1;
	else
		bitCount <= bitCount;
end

assign atStopBit = (bitCount == 4'h9);

// Baud Counter // 16x Sampling rate
always@(posedge clk, posedge rst)begin
	if(rst)
		baudCount <= 4'h0;
	else if(clr_baud_count)
		baudCount <= 4'h0;
	else if(tx_en)
		baudCount <= baudCount + 1;
	else
		baudCount <= baudCount;
end

assign baudDone = &baudCount;

// Control Unit //
always@(*) begin
	// defaults //
	clr_tbr = 0;
	set_tbr = 0;
	load_tx_buf = 0;
	load_shift_reg = 0;
	shift = 0;
	clr_bit_count = 0;
	inc_bit = 0;
	clr_baud_count = 0;

	case(state)
		// Wait for Transmit command //
		IDLE:begin
			if(transmit)begin
				clr_tbr = 1;
				load_tx_buf = 1;
				next_state = BUF;
			end else begin
				next_state = IDLE;
			end
		end
		// Intermediate state to move data between buf and shift register // Do we need this?
		BUF:begin
			// Wait for sampling rate to sync //
			if(tx_en)begin
				load_shift_reg = 1;
				clr_bit_count = 1;
				clr_baud_count = 1;
				next_state = SEND;
			end else
				next_state = BUF;
		end
		// Send out data from shift register //
		SEND:begin
			if(baudDone)begin
				// At final bit, transmission is over //
				if(atStopBit)begin
					set_tbr = 1;
					clr_bit_count = 1;
					next_state = IDLE;
				// Shift bit, and keep sending //
				end else begin
					shift = 1;
					inc_bit = 1;
					next_state = SEND;
				end

				clr_baud_count = 1; // Always clear baud
			end else begin
				next_state = SEND;
			end
		end
		default: next_state = IDLE;
	endcase
end


endmodule
