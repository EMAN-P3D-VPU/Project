`timescale 1ns / 1ps
module tb_logic_time_wrapper();

// inputs
reg clk, rst;

//There is no ROM module for testing, going to mimic the behavior of the ROM module in my design
reg empty, blank; //The signal comming from the FIFO, meaning FIFO is empty if high
reg [23:0] fifo_color; 

// output
wire [7:0] pixel_r; 
wire [7:0] pixel_g;
wire [7:0] pixel_b;

wire stall, read_en;

logic_time_wrapper iDUT_ltw(.empty(empty),
			.fifo_color(fifo_color),
			.pixel_r(pixel_r),
			.pixel_g(pixel_g),
			.pixel_b(pixel_b),
			.read_en(read_en),
			.stall(stall),
			.blank(blank));

initial begin
	clk = 0;
	rst = 0;
	empty = 0;
	blank = 1;
	fifo_color = 24'h000000;
	@(negedge clk) rst = 1;
	@(negedge clk) rst = 0;
	///test case 1 below///
	repeat(1)@(negedge clk);
	fifo_color = 24'hFA0059;
	repeat(1)@(negedge clk);
	if(pixel_r == 8'hFA && pixel_g == 8'h00 && pixel_b == 8'h59)begin
		$display("test case 1 pass");
	end else begin
		$display("fail test 1");
		$finish();
	end
	///test case 2 below///
	repeat(1)@(negedge clk);
	fifo_color = 24'h60AAFF;
	repeat(1)@(negedge clk);
	if(pixel_r == 8'h60 && pixel_g == 8'hAA && pixel_b == 8'hFF)begin
		$display("test case 2 pass");
	end else begin
		$display("fail test 2");
		$finish();
	end
	///test case 3 below///
	repeat(1)@(negedge clk);
	empty = 1;
	repeat(1)@(negedge clk);
	if(stall == 1'b1 && read_en == 1'b0)begin
		$display("test case 3 pass");
	end else begin
		$display("fail test 3");
		$finish();
	end
	///test case 4 below///
	repeat(1)@(negedge clk);
	blank = 0;
	empty = 0;
	repeat(1)@(negedge clk);
	if(stall == 1'b0 && read_en == 1'b0)begin
		$display("test case 4 pass");
		$display("all correct!");
		$finish();
	end else begin
		$display("fail test 4");
		$finish();
	end
end

initial begin
	repeat(100)@(negedge clk);
	$display("runtime error");
	$finish();
end
	
always 
	#5 clk = ~clk;
	
endmodule