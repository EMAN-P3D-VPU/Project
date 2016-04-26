`timescale 1ns / 1ps
module tx_shift_reg(
		input clk,
		input rst,
		input transmit_begin,
		input transmit_status,
		input shift,
		input [7:0] transmit_buffer,
		output txd);

// shift register
reg [9:0] tx_shft_reg;

always @ (posedge clk) begin
	// defaults to all 1's
	if (rst) begin
		tx_shft_reg <= 10'h3FF;
	// when transmission begins, send in
	// start bit, stop bit, and the byte to send   
	end else if(transmit_begin) begin
		tx_shft_reg <= {1'b1, transmit_buffer, 1'b0};
	// only shift when the shift line is asserted
	end else if(shift) begin
		tx_shft_reg <= ( tx_shft_reg >> 1 );
	end else begin
		tx_shft_reg <= tx_shft_reg;
	end
end

// outputs to UART port
assign txd = transmit_status ? tx_shft_reg[0] : 1;

endmodule