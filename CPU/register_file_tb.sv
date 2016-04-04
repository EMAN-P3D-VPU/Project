////////////////////////////////////////////////////////////////////////////////
// register_file_tb.sv
// Dan Wortmann
//
// Description:
// Simple Read/Write simulation to check if everything is connected properly.
// More exhaustive testing can be done when the CPU interface is connected up
// with the VPU, but there isn't much to test here given the simple nature
// of a regfile.
////////////////////////////////////////////////////////////////////////////////
module register_file_tb();
////////////
// Inputs /
//////////
logic 			clk, rst_n;
logic			cpu_flags_we, we_CPU_0, we_CPU_1, we_VPU;
logic	[4:0]	reg_addr_0, reg_addr_1, wrt_addr_0, wrt_addr_1;
logic	[15:0]	cpu_flags, wrt_data_0, wrt_data_1, wrt_V0, wrt_V1, wrt_V2,
				wrt_V3, wrt_V4, wrt_V5, wrt_V6, wrt_V7, return_obj;

integer i, j, k;
/////////////
// Outputs /
///////////
wire	[15:0]	reg_data_0, reg_data_1, read_V0, read_V1, read_V2, read_V3,
				read_V4, read_V5, read_V6, read_V7, read_RO;

///////////////////
// Interconnects /
/////////////////

////////////////////
// Instantiations /
//////////////////
register_file regfile(// Inputs //
					 .reg_addr_0(reg_addr_0), .reg_addr_1(reg_addr_1), .wrt_addr_0(wrt_addr_0), .wrt_addr_1(wrt_addr_1),
					 .cpu_flags(cpu_flags), .cpu_flags_we(cpu_flags_we), .we_VPU(we_VPU),
					 .wrt_data_0(wrt_data_0), .wrt_data_1(wrt_data_1), .we_CPU_0(we_CPU_0), .we_CPU_1(we_CPU_1),
					 .wrt_V0(wrt_V0), .wrt_V1(wrt_V1), .wrt_V2(wrt_V2), .wrt_V3(wrt_V3),
					 .wrt_V4(wrt_V4), .wrt_V5(wrt_V5), .wrt_V6(wrt_V6), .wrt_V7(wrt_V7),
					 .return_obj(return_obj),
					 // Outputs //
					 .reg_data_0(reg_data_0), .reg_data_1(reg_data_1), .read_RO(read_RO),
					 .read_V0(read_V0), .read_V1(read_V1), .read_V2(read_V2), .read_V3(read_V3),
					 .read_V4(read_V4), .read_V5(read_V5), .read_V6(read_V6), .read_V7(read_V7));

////////////////////////////////////////////////////////////////////////////////
// register_file_tb
////

// Clock //
always
	#2 clk = ~clk;

// Fail Safe Stop //
initial
	#1000 $stop;

// Main Test Loop //
initial begin
	i = 0; j = 0; k = 0;
	clk = 0;
	rst_n = 0;
	we_VPU = 0;
	we_CPU_0 = 0;
	we_CPU_1 = 0;
	cpu_flags_we = 0;
	reg_addr_0 = 5'd0;
	reg_addr_1 = 5'd0;
	wrt_addr_0 = 5'd0;
	wrt_addr_1 = 5'd0;
	wrt_data_0 = 16'h0000;
	wrt_data_1 = 16'h0000;
    wrt_V0 = 16'h0000;
    wrt_V1 = 16'h0000;
    wrt_V2 = 16'h0000;
    wrt_V3 = 16'h0000;
    wrt_V4 = 16'h0000;
    wrt_V5 = 16'h0000;
    wrt_V6 = 16'h0000;
    wrt_V7 = 16'h0000;
	return_obj = 16'h0000;
	cpu_flags = 16'h0000;

	$display("rst assert\n");
	@(negedge clk) rst_n = 1;
	$display("rst deassert\n");

	// Write data to each register //
	// R0 <= 0, R1 <= 1, ... , R31 <= 31 //
	we_CPU_0 = 1;
	we_VPU = 0;
	cpu_flags_we = 0;
	i = 0;
	repeat(32)begin
		@(posedge clk); 
		wrt_addr_0 = i;
		wrt_data_0 = i;
		@(posedge clk);
		i = i + 1;
		// Only write flags when WE is asserted //
		if(i == 16'd22)begin
			cpu_flags_we = 1;
			cpu_flags = i;
		end else begin
			cpu_flags_we = 0;
			cpu_flags = 0;
		end
		// Only write return object from VPU (user restricted) //
		if(i == 16'd23)begin
			we_VPU = 1;
			return_obj = i;
		end else begin
			we_VPU = 0;
			return_obj = 0;
		end
	end
	
	// Deassert WE signals for now //
	we_CPU_0 = 0;
	we_VPU = 0;
	cpu_flags_we = 0;
	i = 0;
	j = 0;
	k = 0;
	// Check Contents //
	repeat(32)begin
		@(posedge clk);
		reg_addr_0 = i;
		reg_addr_1 = j;
		@(negedge clk);
		// Port 0 //
		if(i !== reg_data_0)begin
			$display("Incorrect register contents R%d = %d\n", i, reg_data_0);
			$stop;
		end
		// Port 1 //
		if(j !== reg_data_1)begin
			$display("Incorrect register contents R%d = %d\n", j, reg_data_1);
			$stop;
		end
		// Update Indicies //
		i = i + 1;
		j = j + 2;
		if(j >= 32)
			j = 0;
	end

	// Write Vertex Registers //
	@(posedge clk);
    wrt_V0 = 16'hABCD;
    wrt_V1 = 16'hA165;
    wrt_V2 = 16'hDEF3;
    wrt_V3 = 16'h1234;
    wrt_V4 = 16'hAB56;
    wrt_V5 = 16'hFF99;
    wrt_V6 = 16'h88AD;
    wrt_V7 = 16'hCCEE;
	we_VPU = 1;
	@(posedge clk);
	// Check Contents - should write to all in parallel //
	if(read_V0 !== wrt_V0)begin
		$display("Incorrect vertex register contents: %h EXPECTED: %h", read_V0, wrt_V0);
		$stop;
	end
	if(read_V1 !== wrt_V1)begin
		$display("Incorrect vertex register contents: %h EXPECTED: %h", read_V1, wrt_V1);
		$stop;
	end
	if(read_V2 !== wrt_V2)begin
		$display("Incorrect vertex register contents: %h EXPECTED: %h", read_V2, wrt_V2);
		$stop;
	end
	if(read_V3 !== wrt_V3)begin
		$display("Incorrect vertex register contents: %h EXPECTED: %h", read_V3, wrt_V3);
		$stop;
	end
	if(read_V4 !== wrt_V4)begin
		$display("Incorrect vertex register contents: %h EXPECTED: %h", read_V4, wrt_V4);
		$stop;
	end
	if(read_V5 !== wrt_V5)begin
		$display("Incorrect vertex register contents: %h EXPECTED: %h", read_V5, wrt_V5);
		$stop;
	end
	if(read_V6 !== wrt_V6)begin
		$display("Incorrect vertex register contents: %h EXPECTED: %h", read_V6, wrt_V6);
		$stop;
	end
	if(read_V7 !== wrt_V7)begin
		$display("Incorrect vertex register contents: %h EXPECTED: %h", read_V7, wrt_V7);
		$stop;
	end

	// More Exhaustive Testing? This is just a simple regfile after all... //

	repeat(25) @(posedge clk);
	$stop;
end

endmodule
