module clipping_top(input clk,
                    input rst_n,
                    input [31:0] obj_map,
                    input [143:0] obj,
                    input raster_ready,
                    input writing, //from matrix_unit
                    input changed,
                    output [9:0] x0_out,
                    output [9:0] y0_out,
                    output [9:0] x1_out,
                    output [9:0] y1_out,
                    output [2:0] color_out,
                    output [4:0] addr,
                    output read_en,
                    output clr_changed, //to matrix unit
                    output reading, //to matrix_unit
                    output start_refresh,
                    output reg vld,
                    output reg end_of_obj
                    );

//Timing logic wires
wire refresh_en, end_refresh;
wire obj_vld, prev_obj_vld;
wire cycle_1, cycle_2, cycle_3, cycle_4;

//initial fifo inputs
wire signed [15:0] x0_in_f0, x1_in_f0, y0_in_f0, y1_in_f0;
wire [7:0] color_in_f0;
wire [3:0] oc0_in, oc1_in; 
wire f0_rd, f0_wr, clr_f0;

//initial fifo outputs
wire signed [15:0] x0_out_f0, x1_out_f0, y0_out_f0, y1_out_f0;
wire [7:0] color_out_f0;
wire [3:0] oc0_out, oc1_out;
wire f0_empty, f0_full;

//clipping algo wires
wire clip_done;
wire signed [31:0] quotient;
wire accept_line, reject_line, clip_line;

//clipping control wires
wire latch_line, store_line, clip_en;

//final fifo inputs
reg [15:0] x0_in_f1, x1_in_f1, y0_in_f1, y1_in_f1;
wire [7:0] color_in_f1;
reg  f1_rd;
wire f1_wr, clr_f1;

//final fifo outputs
wire [15:0] x0_out_f1, x1_out_f1, y0_out_f1, y1_out_f1;
wire [7:0] color_out_f1;
wire f1_empty, f1_full;


clipping_timing_logic timing(
                    .clk(clk),
                    .rst_n(rst_n),
                    .obj_map(obj_map),
                    .changed(changed),
                    .writing(writing),
                    .addr(addr),
                    .refresh_en(refresh_en),
                    .start_refresh(start_refresh),
                    .end_refresh(end_refresh),
                    .cycle_1(cycle_1),
                    .cycle_2(cycle_2),
                    .cycle_3(cycle_3),
                    .cycle_4(cycle_4),
                    .obj_vld(obj_vld),
                    .prev_obj_vld(prev_obj_vld)
                    );

clipping_line_handler line_handler(
                .clk(clk),
                .rst_n(rst_n),
                .obj(obj),
                .cycle_1(cycle_1),
                .cycle_2(cycle_2),
                .cycle_3(cycle_3),
                .cycle_4(cycle_4),
                .obj_vld(obj_vld),
                .prev_obj_vld(prev_obj_vld),
                .read_en(read_en),
                .x0_in_f0(x0_in_f0),
                .x1_in_f0(x1_in_f0),
                .y0_in_f0(y0_in_f0),
                .y1_in_f0(y1_in_f0),
                .color_in_f0(color_in_f0),
                .oc0_in(oc0_in),
                .oc1_in(oc1_in),
                .f0_wr(f0_wr),
                .clr_f0(clr_f0)
                );

//not sure if this fifo needs to be 128-deep
aFifo initial_fifo(
            .Data_out({oc1_out, oc0_out, color_out_f0, y1_out_f0, x1_out_f0, y0_out_f0, x0_out_f0}), 
            .Empty_out(f0_empty), 
            .ReadEn_in(f0_rd), 
            .RClk(clk),
            .Data_in({oc1_in, oc0_in, color_in_f0, y1_in_f0, x1_in_f0, y0_in_f0, x0_in_f0}),
            .Full_out(f0_full), 
            .WriteEn_in(f0_wr), 
            .WClk(clk), 
            .Clear_in(clr_f0)
            );


clipping_control control(.clk(clk),
                        .rst_n(rst_n),
                        .raster_ready(raster_ready),
                        .accept_line(accept_line),
                        .reject_line(reject_line),
                        .clip_line(clip_line),
                        .clip_done(clip_done),
                        .f0_empty(f0_empty),
                        .f0_rd(f0_rd),
                        .reading(reading),
                        .latch_line(latch_line),
                        .store_line(store_line),
                        .clip_en(clip_en)
                        );

clipping_algo algo(.clk(clk),
                    .rst_n(rst_n),
                    .latch_line(latch_line),
                    .store_line(store_line),
                    .clip_en(clip_en),
                    .x0_out_f0(x0_out_f0),
                    .x1_out_f0(x1_out_f0),
                    .y0_out_f0(y0_out_f0),
                    .y1_out_f0(y1_out_f0),
                    .color_out_f0(color_out_f0),
                    .oc0_out(oc0_out),
                    .oc1_out(oc1_out),
                    .x0_in_f1(x0_in_f1),
                    .x1_in_f1(x1_in_f1),
                    .y0_in_f1(y0_in_f1),
                    .y1_in_f1(y1_in_f1),
                    .color_in_f1(color_in_f1),
                    .f1_wr(f1_wr),
                    .clr_f1(clr_f1),
                    .clip_done(clip_done),
                    .quotient(quotient),
                    .accept_line(accept_line),
                    .reject_line(reject_line),
                    .clip_line(clip_line)
                    );


aFifo final_fifo(
            .Data_out({color_out_f1, y1_out1, x1_out_f1, y0_out_f1, x0_out_f1}), 
            .Empty_out(f1_empty), 
            .ReadEn_in(f1_rd), 
            .RClk(clk),
            .Data_in({8'b0, color_in_f1, y1_in_f1, x1_in_f1, y0_in_f1, x0_in_f1}),
            .Full_out(f1_full), 
            .WriteEn_in(f1_wr), 
            .WClk(clk), 
            .Clear_in(clr_f1)
            );


//OUTPUT STAGE

assign x0_out = x0_out_f1[9:0];
assign y0_out = y0_out_f1[9:0];
assign x1_out = x1_out_f1[9:0];
assign y1_out = y1_out_f1[9:0];
assign color_out = color_out_f1[2:0]; //8-bit color path has already been designed

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        end_of_obj <= 1'b0;
    end else begin
        if(start_refresh)
            end_of_obj <= 1'b0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        f1_rd <= 1'b0;
    end else begin
        if(raster_ready) begin //this will cause a 2-cycle delay in data
            f1_rd <= 1'b1;
        end else begin
            f1_rd <= 1'b0;
        end
    end
end

always @(posedge clk)
    vld <= f1_rd; //data will be valid in the next cycle of vld


endmodule
