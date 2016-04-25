`timescale 1ns / 1ps
module driver(
	input clk,
	input rst,
	input [1:0] br_cfg,
	input rda,
	input tbr,
	output reg iocs,
	output reg iorw,
	output reg [1:0] ioaddr,
	inout [7:0] databus);

// baud rates
wire [15:0] baud4800;
wire [15:0] baud9600;
wire [15:0] baud19200;
wire [15:0] baud38400;

// which baud rate to choose based on br_cfg
wire [7:0] dbLow;
wire [7:0] dbHigh;

assign baud4800 = 16'h516;
assign baud9600 = 16'h28A;
assign baud19200 = 16'h145;
assign baud38400 = 16'hA2;

assign dbLow = br_cfg == 2'b00 ? baud4800[7:0] :
			(br_cfg == 2'b01 ? baud9600[7:0] :
			(br_cfg == 2'b10 ? baud19200[7:0] : baud38400[7:0]));

assign dbHigh = br_cfg == 2'b00 ? baud4800[15:8] :
			(br_cfg == 2'b01 ? baud9600[15:8] :
			(br_cfg == 2'b10 ? baud19200[15:8] : baud38400[15:8]));


// state variables
parameter BLOW = 2'b00, BHIGH = 2'b01, RECEIVE = 2'b10, TRANSMIT = 2'b11;
reg [1:0] next_state;
reg [1:0] state;

// combinational logic
always @(*) begin
	case(state)
		BLOW: next_state = BHIGH;
		BHIGH: next_state = RECEIVE;
		RECEIVE:
			begin
				if (rda == 1'b1) begin
					next_state = TRANSMIT;
				end else begin
					next_state = RECEIVE;
				end
			end
		TRANSMIT:
			begin
				if (tbr == 1'b1) begin
					next_state = RECEIVE;
				end else begin
					next_state = TRANSMIT;
				end
			end
		default: next_state = BLOW;
	endcase
end

// Sequential logic
always @(posedge clk) begin
	if (rst == 1'b1) begin
		state <= BLOW;
	end else begin
		state <= next_state;
	end
end

// Output logic
wire [7:0] dataIn;
reg [7:0] dataOut;

assign dataIn = databus;
assign databus = (iocs && ~iorw) ? dataOut : 8'bz;

// used to store character input so that in transmit, one can send it
reg [7:0] byteOfData;
always @(posedge clk) begin
	if (rst == 1'b1) begin
		byteOfData <= 8'b0;
	end else begin
		case(state)
			BLOW: byteOfData <= 8'b0;
			BHIGH: byteOfData <= 8'b0;
			RECEIVE: byteOfData <= dataIn;
			TRANSMIT: byteOfData <= byteOfData;
		endcase
	end
end

// logic for iocs, iorw, and ioaddr
// iocs is always 1 only when need to read or write, 0 otherwise
// iorw is 0 when writing, 1 when reading
// dataOut is when one needs to send a byte out in the databus
// ioaddr is what register to interface within the SPART
always @(*) begin
	case(state)
		BLOW:
			begin
				iocs = 1'b1;
				iorw = 1'b0;
				dataOut = dbLow;
				ioaddr = 2'b10;
			end
		BHIGH:
			begin
				iocs = 1'b1;
				iorw = 1'b0;
				dataOut = dbHigh;
				ioaddr = 2'b11;
			end
		RECEIVE:
			begin
				if (rda == 1'b1) begin
					iocs = 1'b1;
					iorw = 1'b1;
					dataOut = 8'bz;
					ioaddr = 2'b00;
				end else begin
					iocs = 1'b0;
					iorw = 1'b1;
					dataOut = 8'bz;
					ioaddr = 2'b00;
				end
			end
		TRANSMIT:
			begin
				if (tbr == 1'b1) begin
					iocs = 1'b1;
					iorw = 1'b0;
					dataOut = byteOfData;
					ioaddr = 2'b00;
				end else begin
					iocs = 1'b0;
					iorw = 1'b0;
					dataOut = byteOfData;
					ioaddr = 2'b00;
				end
			end
		default:
			begin
				iocs = 1'b0;
				iorw = 1'b0;
				dataOut = 8'bz;
				ioaddr = 2'b00;
			end
	endcase
end

endmodule
