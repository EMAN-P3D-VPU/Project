module video_mem_unit(input clk,
                    input rst_n,
                    input [4:0] mat_addr,
                    input [143:0] mat_obj_in,
                    input loadback,
                    input mat_rd_en,
                    input mat_wr_en,
                    input [4:0] clip_addr,
                    input clip_rd_en,
                    output reg [143:0] mat_obj_out,
                    output reg [143:0] clip_obj_out,
                    output reg cpu_wr_en,
                    output reg [15:0] ldback_x0,
                    output reg [15:0] ldback_x1,
                    output reg [15:0] ldback_x2,
                    output reg [15:0] ldback_x3,
                    output reg [15:0] ldback_y0,
                    output reg [15:0] ldback_y1,
                    output reg [15:0] ldback_y2,
                    output reg [15:0] ldback_y3
                    );

reg [143:0] ram[31:0];

always @(posedge clk) begin
    if(mat_wr_en)
        ram[mat_addr] <= mat_obj_in;
end

always @(posedge clk) begin
    if(mat_rd_en)
        mat_obj_out <= ram[mat_addr];
end

always @(posedge clk) begin
    if(clip_rd_en)
        clip_obj_out <= ram[clip_addr];
end

always @(posedge clk) begin
    if(loadback) begin
        ldback_x0 <= ram[mat_addr][15:0];
        ldback_y0 <= ram[mat_addr][31:16];
        ldback_x1 <= ram[mat_addr][47:32];
        ldback_y1 <= ram[mat_addr][63:48];
        ldback_x2 <= ram[mat_addr][79:64];
        ldback_y2 <= ram[mat_addr][95:80];
        ldback_x3 <= ram[mat_addr][111:96];
        ldback_y3 <= ram[mat_addr][127:112];
        //what about color and obj_type?
    end
end

always@(posedge clk)
    cpu_wr_en <= loadback;

endmodule
