`timescale 1ns / 1ps
module uart_rx(
	output reg [7:0] receive_buffer, //the buffer contains the byte to be transferred to the I/O
	input rxd, //rxd is the receiving bus, transmitting 1 bit at a time
	output reg rda,
	input clk,
	input rx_en,
	input rst,
	input iocs,  //input/output chip selection, 1 means a read or write is happening
	input iorw, //iorw, 1 means processor is going to read the byte
	input [1:0] ioaddr); //the input to the mux for selecting the register
//The following parameters are for the states
parameter IDLE = 2'b00;
parameter START = 2'b01;
parameter SHIFT = 2'b10;
parameter RECEIVED = 2'b11;

// state variables
reg [1:0] state;
reg [1:0] nxt_state;

reg received; //this signal high means a byte of data has already been received

wire receive_status; //Signals the beginning of the receiving FROM the processor
assign receive_status = (iocs == 1'b1) ? ((ioaddr == 2'b00) ? ((iorw == 1'b1) ? 1 : 0) : 0) : 0;

// sequential logic
always@(posedge clk)begin
	if(rst)
		state <= IDLE;
	else
		state <= nxt_state;
end

reg receive_begin; //This signal means receive begins, and clear all the module

wire enable;
find_rising_edge re_enable(
				.clk(clk),
				.rst(rst),
				.enable(rx_en),
				.rising_edge(enable));

wire sample_en; //This comes from the sample control logic, which signals the middle of a bit transmitting
wire sample; //The signals to sample, it means a rising edge of sample_en signal has been detected
reg r_sample;

// This module is to determine when to sample a bit to the receiving register
sample sam(
		.clk(clk),
		.rst(rst || r_sample),
		.enable(enable),
		.start_from_middle(1'b0),
		.sample(sample_en));

find_rising_edge re_sample(
				.clk(clk),
				.rst(rst),
				.enable(sample_en),
				.rising_edge(sample));

//The following is for the other 3 modules and the 2 signals feeding into them
wire [3:0] bit_cnt;

bit_counter bc(
		.clk(clk),
		.rst(rst),
		.sample(sample),
		.start(receive_begin),
		.bits(bit_cnt));

// combinational logic
always @(*) begin
	nxt_state = IDLE;
	receive_begin = 0;
	received = 0;
	r_sample = 0;
	case(state)
		IDLE:
			if (!rxd) begin
				nxt_state = START;
				r_sample = 1;
			end else begin
				nxt_state = IDLE;
			end
		START:
			if (!rxd && sample) begin // Receiving begin since we got the Start Bit
				nxt_state = SHIFT;
				receive_begin = 1;
			end else begin
				nxt_state = START;
			end
		SHIFT: if(bit_cnt == 4'b1010)begin 
				received = 1;
				nxt_state = RECEIVED;
			end else begin
				nxt_state = SHIFT;
		 	end
		RECEIVED: if(receive_status)begin
					nxt_state = IDLE;
				end
				  else begin
					received = 1;
				  	nxt_state = RECEIVED;
				end
		default: nxt_state = IDLE;
	endcase
end

// output logic

// shift register
wire [7:0] r_buffer;
rx_shift_reg rsr(
			.clk(clk),
			.rst(rst),
			.sample(sample),
			.rxd(rxd),
			.receive_buffer(r_buffer));

// only put value into receive buffer when one word has been received
always @(posedge clk) begin
	if(rst) begin
		receive_buffer <= 8'b0;
	end else if (state == SHIFT && received == 1'b1) begin
		receive_buffer <= r_buffer;
	end else begin
		receive_buffer <= receive_buffer;
	end
end

// rda will only be set to one once an entire byte has been received
// this is indicated by the assertion of the received line
always@(posedge clk)begin
	if(rst)begin
		rda <= 0;
	end
	else if(received)begin
		rda <= 1;
	end
	else if(receive_status)begin
		rda <= 0;
	end
	else begin
		rda <= rda;
	end
end

endmodule