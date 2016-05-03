`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    rx_unit 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//	Receive unit of the SPART. This listens for asynchronous data transfer via
//	the RX line. When a start bit it detected the state machine kicks off and
//	read the 8 data bits. Finally the RX line returns back to high on the stop
//	bit.
//
//	Data from RX line is flopped additionally for metastability issues. Additionally
//	due to the asynchronous nature of this device. The SPART synchronizes based on
//	the sampling rate and the baud rate on each start bit.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module rx_unit(clk,
			   rst,
			   rx_en,
			   clr_rda,
			   rxd,
			   rx_data,
			   rda);

////////////
// Inputs //
////////////
input wire clk, rst;
input wire rx_en;
input wire rxd;
input wire clr_rda;

/////////////
// Outputs //
/////////////
output wire [7:0] rx_data;
output reg rda;

/////////////
// Signals //
/////////////
reg shift;
reg set_rda;
wire atStopBit;
reg load_rx_buf;
reg clr_bit_count;
reg inc_bit;
reg RX_rdy, RX_ff2, RX_ff1;
reg synchronize;
reg clr_baud_count;

reg [3:0] bitCount;
reg [4:0] baudCount;
reg [7:0] rx_buf;
reg [7:0] rx_shift_reg;

// States //
localparam IDLE	= 1'b1;
localparam READ	= 1'b0;

reg state, next_state;

//////////////////////////////////////////////////////////////////////////////////
// Rx Unit
////

// State Change //
always@(posedge clk, posedge rst)begin
	if(rst)
		state <= IDLE;
	else
		state <= next_state;
end

// Receive Buffer Ready //
always@(posedge clk, posedge rst)begin
	if(rst)
		rda <= 1'b0;
	else if(clr_rda)
		rda <= 1'b0;
	else if(set_rda)
		rda <= 1'b1;
	else
		rda <= rda;
end

// Rx Buffer //
always@(posedge clk, posedge rst)begin
	if(rst)
		rx_buf <= 8'h00;
	else if(load_rx_buf)
		rx_buf <= rx_shift_reg;
	else
		rx_buf <= rx_buf;
end

assign rx_data = rx_buf;

// Rx Shift Register //
always@(posedge clk, posedge rst)begin
	if(rst)
		rx_shift_reg <= 8'h00;
	else if(shift)
		rx_shift_reg <= {RX_rdy, rx_shift_reg[7:1]};
	else
		rx_shift_reg <= rx_shift_reg;
end

// Bit Counter //
always@(posedge clk, posedge rst)begin
	if(rst)
		bitCount <= 4'h0;
	else if(clr_bit_count)
		bitCount <= 4'h0;
	else if(inc_bit)
		bitCount <= bitCount + 1;
	else
		bitCount <= bitCount;
end

assign atStopBit = (bitCount == 4'h8);

// Negedge detection of RX // notes from ECE551
// metastability issues, and just general advice from Eric //
always@(posedge clk, posedge rst)begin
	if(rst)begin
		RX_ff1 <= 1'b1;
		RX_ff2 <= 1'b1;
		RX_rdy <= 1'b1;
	end else begin
		RX_ff1 <= rxd;
		RX_ff2 <= RX_ff1;
		RX_rdy <= RX_ff2;
	end
end

// Detect start bit //
assign negedgeRX = (RX_rdy & ~RX_ff2);

// Baud Counter // 16x Sampling rate
always@(posedge clk, posedge rst)begin
	if(rst)
		baudCount <= 5'h0;
	else if(synchronize)
		baudCount <= 5'h07; // 32 - 1.5*16 = 8
	else if(clr_baud_count)
		baudCount <= 5'h0F; // 32 - 16 = 16
	else if(rx_en)
		baudCount <= baudCount + 1;
	else
		baudCount <= baudCount;
end

assign baudDone = &baudCount;

// Control Unit //
always@(*) begin
	// defaults //
	clr_baud_count = 0;
	clr_bit_count = 0;
	inc_bit = 0;
	shift = 0;
	set_rda = 0;
	load_rx_buf = 0;
	synchronize = 0;

	case(state)
		// Wait for Start bit on Rx line //
		IDLE:begin
			if(negedgeRX)begin
				synchronize = 1; // 24 samples til 'middle' of first bit
				clr_bit_count = 1;
				next_state = READ;
			end else
				next_state = IDLE;
		end
		// Read in 8 data bits //
		READ:begin
			if(baudDone)begin
				if(atStopBit)begin
					set_rda = 1;
					load_rx_buf = (rda) ? 0 : 1; // drop data if not serviced
					next_state = IDLE;
				end else begin
					inc_bit = 1;
					shift = 1;
					next_state = READ;
				end

				clr_baud_count = 1; // clear baud regardless
			end else begin
				next_state = READ;
			end
		end
		default: next_state = IDLE;
	endcase
end

endmodule
