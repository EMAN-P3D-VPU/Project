////////////////////////////////////////////////////////////////////////////////
// VPU_register.v
// Dan Wortmann
//
// Description:
// 
////////////////////////////////////////////////////////////////////////////////
module VPU_register(
    // Inputs //
    clk, rst_n, STALL,
    VPU_start,
    V0_in,
    V1_in,
    V2_in,
    V3_in,
    V4_in,
    V5_in,
    V6_in,
    V7_in,
    RO_in,
    // Outputs //
    VPU_start_out,
    V0_out,
    V1_out,
    V2_out,
    V3_out,
    V4_out,
    V5_out,
    V6_out,
    V7_out,
    RO_out
);
////////////
// Inputs /
//////////
input				clk, rst_n, STALL;
input				VPU_start;
input		[15:0]	V0_in, V1_in, V2_in, V3_in, V4_in, V5_in, V6_in, V7_in, RO_in;
/////////////
// Outputs /
///////////
output	reg			VPU_start_out;
output	reg	[15:0]	V0_out, V1_out, V2_out, V3_out, V4_out, V5_out, V6_out, V7_out, RO_out;

/////////////////////////////
// Signals/Logic/Registers /
///////////////////////////

///////////////////
// Interconnects /
/////////////////

////////////////////////////////////////////////////////////////////////////////
// VPU_register
////

// Flop VPU signals + registers //
always@(posedge clk)begin
	if(!rst_n)
		VPU_start_out <= 1'h0;
	else if(~STALL)
		VPU_start_out <= VPU_start;
	else
		VPU_start_out <= VPU_start_out;
end

always@(posedge clk)begin
	if(!rst_n)begin
        V0_out <= 16'h0000;
        V1_out <= 16'h0000;
        V2_out <= 16'h0000;
        V3_out <= 16'h0000;
        V4_out <= 16'h0000;
        V5_out <= 16'h0000;
        V6_out <= 16'h0000;
        V7_out <= 16'h0000;
        RO_out <= 16'h0000;
	end else if(~STALL)begin
        V0_out <= V0_in;
        V1_out <= V1_in;
        V2_out <= V2_in;
        V3_out <= V3_in;
        V4_out <= V4_in;
        V5_out <= V5_in;
        V6_out <= V6_in;
        V7_out <= V7_in;
        RO_out <= RO_in;
	end else begin
        V0_out <= V0_out;
        V1_out <= V1_out;
        V2_out <= V2_out;
        V3_out <= V3_out;
        V4_out <= V4_out;
        V5_out <= V5_out;
        V6_out <= V6_out;
        V7_out <= V7_out;
        RO_out <= RO_out;
	end
end

endmodule
