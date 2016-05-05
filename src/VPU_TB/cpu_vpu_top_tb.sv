`include "timescale.v"

module cpu_vpu_top_tb();

reg clkin, rst_n;
wire hsync, vsync, blank, dvi_rst, clk_25mhz, clk_25mhz_n, scl_tri, sda_tri;
wire [11:0] D;

cpu_vpu_top top(.clkin(clkin), .rst_n(rst_n), .hsync(hsync), .vsync(vsync), .blank(blank), .D(D), .dvi_rst(dvi_rst),
                .clk_25mhz(clk_25mhz), .clk_25mhz_n(clk_25mhz_n), .scl_tri(scl_tri), .sda_tri(sda_tri));

always #5 clkin = ~clkin;

initial begin
    clkin = 1'b0;
    rst_n = 1'b0;
    force top.clipper.timing.refresh_cnt = 0;
    @(posedge clkin);
    @(negedge clkin);
    rst_n = 1'b1;
    #10us;
    trigger_clipper();//trigger clipper
    //#10us;
    //force_fb();
end

task trigger_clipper();
    force top.clipper.timing.refresh_cnt = 1666667;
    @(posedge clkin);
    release top.clipper.timing.refresh_cnt;
endtask

task force_fb();
    force top.raster.LINE_GENERATOR.nxt_state = 2'h2;
    @(posedge clkin);
    release top.raster.LINE_GENERATOR.nxt_state;
endtask

endmodule
