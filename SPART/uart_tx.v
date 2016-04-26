`timescale 1ns / 1ps
module uart_tx( input [7:0] transmit_buffer, //the buffer contains the byte to be transferred to the I/O
		output txd, //txd is the tranmitting bus, transmitting 1 bit at a time 
		output reg tbr,
		input clk,
		input tx_en,
		input rst,
		input iocs,  //input/output chip selection, 1 means a read or write is happening
		input iorw, //iorw, 0 means the processor has a byte that needs to sent to txd by this module
		input [1:0] ioaddr); //the input to the mux for selecting the register

//The following parameters are for the states
parameter IDLE = 1'b0;
parameter MID = 1'b1;

// state variables
reg state;
reg nxt_state;

wire transmit_begin; //Signals the beginning of the transmitting
assign transmit_begin = (iocs == 1) ? ((ioaddr == 2'b00) ? ((iorw == 1'b0) ? 1 : 0) : 0) : 0;

wire enable;
find_rising_edge te_enable(
				.clk(clk),
				.rst(rst),
				.enable(tx_en),
				.rising_edge(enable));


wire sample_en; //This comes from the sample control logic, which signals the middle of a bit transmitting
wire sample; //The signals to sample, it means a rising edge of sample_en signal has been detected

/*This module is to determine when to sample a bit to the receiving register*/
sample sam(
		.clk(clk),
		.rst(rst),
		.enable(enable),
		.start_from_middle(transmit_begin),
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
		.start(transmit_begin),
		.bits(bit_cnt));

// sequential logic
always@(posedge clk)begin
	if(rst) begin
		state <= IDLE;
	end else begin
		state <= nxt_state;
	end
end

// combinational logic
always @(*)begin
	nxt_state = IDLE;
	case(state)
		IDLE: if(!transmit_begin)begin
				nxt_state = IDLE;
			end else begin
				nxt_state = MID;
			end
		MID: if (bit_cnt == 4'b1011) begin
				nxt_state = IDLE;
			end else if (sample) begin
				nxt_state = MID;
			end else begin
				nxt_state = MID;
			end
		default: nxt_state = IDLE;
	endcase
end

// shift register, needed when sending a byte to tx
tx_shift_reg tsr(
		.clk(clk),
		.rst(rst),
		.transmit_begin(transmit_begin),
		.transmit_status((state == MID) && (bit_cnt != 4'b1011)),
		.shift((state == MID) && sample),
		.transmit_buffer(transmit_buffer),
		.txd(txd));

// tbr is asserted when there is not a byte being sent
always@(posedge clk)begin
	if(rst || transmit_begin) begin
		tbr <= 0;
	end else if((state == IDLE) || (bit_cnt == 4'b1011)) begin
		tbr <= 1;
	end else begin
		tbr <= tbr;
	end
end

endmodule