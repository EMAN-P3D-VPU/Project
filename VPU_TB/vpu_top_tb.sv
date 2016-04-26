`include "timescale.v"

module vpu_top_tb();

reg clkin, rst_n;
wire [15:0] x0_in_f1, x1_in_f1, y0_in_f1, y1_in_f1;

vpu_top vpu(.clkin(clkin), .rst_n(rst_n), .x0_in_f1(x0_in_f1), .y0_in_f1(y0_in_f1), .x1_in_f1(x1_in_f1), .y1_in_f1(y1_in_f1));

always #5 clkin = ~clkin;

initial begin
    clkin = 1'b0;
    rst_n = 1'b0;
    force vpu.clipper.timing.refresh_cnt = 0;
    @(posedge clkin);
    @(negedge clkin);
    rst_n = 1'b1;
    wait (vpu.cnt == 11);
    trigger_clipper();//trigger clipper
end

task trigger_clipper();
    force vpu.clipper.timing.refresh_cnt = 1666667;
    @(posedge clkin);
    release vpu.clipper.timing.refresh_cnt;
endtask

endmodule
