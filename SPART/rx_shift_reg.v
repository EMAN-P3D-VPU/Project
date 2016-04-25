`timescale 1ns / 1ps
module rx_shift_reg(
		input clk,
		input rst,
		input sample,
		input rxd,
		output [7:0] receive_buffer);

reg [8:0] rx_shift_reg;

always @ (posedge clk) begin
	// reset to 1 as this is the default state for incoming data
	if (rst) begin
		rx_shift_reg <= 9'h1FF;
	// shift when sample is asserted
	end else if (sample) begin
		rx_shift_reg <= {rxd, rx_shift_reg[8:1]};
	end else begin
		rx_shift_reg <= rx_shift_reg;
	end
end

// the receive buffer is what to send the databus
// it is the first 8 bits as this is a right shift register
// and there is no need to send the start or stop bits
assign receive_buffer = rx_shift_reg[7:0];

endmodule