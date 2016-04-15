module vpu_top(input clkin,
                        input rst_n,
                        //input nxt_instr,
                        //input [1:0] obj_type,
                        //input [7:0] obj_color,
                        //input [4:0] obj_num_in,
                        //input [3:0] gmt_op,
                        //input [3:0] gmt_code,
                        //input go,
                        //output busy,
                        //output obj_mem_full_out,
                        //output [4:0] lst_stored_obj_out,
                        //for testing
                        output f1_wr_test,
                        output [15:0] x0_in_f1, x1_in_f1, y0_in_f1, y1_in_f1
                        );

wire clk;
clkgen clk_gen(.CLKIN_IN(clkin), .RST_IN(1'b0), .CLK0_OUT(clk), .LOCKED_OUT());

//CPU-matrix interface
reg signed [15:0] v0, v1, v2, v3, v4 ,v5, v6, v7;
reg [1:0] obj_type;
reg [7:0] obj_color;
reg [4:0] obj_num_in;
reg [3:0] gmt_op, gmt_code;
reg go, go_f;
wire busy;
wire obj_mem_full_out;
wire [4:0] lst_stored_obj_out;
//matrix-obj_unit interface
wire crt_obj, del_obj, del_all, ref_addr, changed_in, obj_mem_full_in, addr_vld;
wire [4:0] obj_num_out, lst_stored_obj_in;
//matrix-mem_unit interface
wire [143:0] mat_obj_in, mat_obj_out;
wire mat_rd_en, mat_wr_en, loadback;
//obj-mem interface
wire [4:0] mat_addr;
//clipping-matrix
wire writing, reading, changed, clr_changed;
//clipping-mem
wire clip_read_en;
wire [4:0] clip_addr;
wire [143:0] clip_obj_out;
//clipping-obj
wire [31:0] obj_map;
//clipping-raster

//TESTING

//internal state
reg crt, del, trans_one, trans, rotl, rotr, scale;
reg [1:0] typ;
reg [4:0] num;
reg [15:0] amt;
reg [1:0] xy, pt;
reg cen;


matrix_unit mat(.clk(clk), .rst_n(rst_n), .go(go_f), .v0(v0), .v1(v1), .v2(v2), .v3(v3), .v4(v4), .v5(v5), .v6(v6), .v7(v7),
                .obj_type(obj_type), .obj_color(obj_color), .obj_num_in(obj_num_in),
                .gmt_op(gmt_op), .gmt_code(gmt_code), .obj_in(mat_obj_out), .addr_vld(addr_vld), 
                .lst_stored_obj_in(lst_stored_obj_in), .lst_stored_obj_vld(lst_stored_obj_vld),
                .obj_mem_full_in(obj_mem_full_in), .clr_changed(clr_changed), .reading(reading),
                .busy(busy), .lst_stored_obj_out(lst_stored_obj_out), .obj_mem_full_out(obj_mem_full_out), 
                .crt_obj(crt_obj), .del_obj(del_obj), .del_all(del_all), .ref_addr(ref_addr),
                .obj_num_out(obj_num_out), .changed(changed_in), .obj_out(mat_obj_in), .rd_en(mat_rd_en), .wr_en(mat_wr_en),
                .loadback(loadback), .writing(writing));

video_mem_unit mem_unit(.clk(clk), .rst_n(rst_n), .mat_addr(mat_addr), .mat_obj_in(mat_obj_in), .loadback(loadback),
                .mat_rd_en(mat_rd_en), .mat_wr_en(mat_wr_en), .mat_obj_out(mat_obj_out),
                .clip_addr(clip_addr), .clip_rd_en(clip_rd_en), .clip_obj_out(clip_obj_out));

object_unit obj(.clk(clk), .rst_n(rst_n), .crt_obj(crt_obj), .del_obj(del_obj), .del_all(del_all),
                .ref_addr(ref_addr), .obj_num(obj_num_out), .changed_in(changed_in), .addr(mat_addr),
                .addr_vld(addr_vld), .lst_stored_obj(lst_stored_obj_in), .lst_stored_obj_vld(lst_stored_obj_vld),
                .obj_mem_full(obj_mem_full_in), .obj_map(obj_map), .changed_out(changed));

clipping_unit clipper(.clk(clk), .rst_n(rst_n), .obj_map(obj_map), .obj(clip_obj_out), .raster_ready(raster_ready),
                .writing(busy), .changed(changed), .addr(clip_addr), .read_en(clip_rd_en), .clr_changed(clr_changed), 
                .reading(reading), .f1_wr_test(f1_wr_test),
                .x0_in_f1(x0_in_f1), .y0_in_f1(y0_in_f1), .x1_in_f1(x1_in_f1), .y1_in_f1(y1_in_f1));

//assign test_result = (&x0_in_f1)^(|y0_in_f1)^(|x1_in_f1)^(&y1_in_f1);


always @(posedge clk) begin
    if(!rst_n) begin
        v0 <= 100;
        v1 <= 100;
        v2 <= 100;
        v3 <= 200;
        v4 <= 200;
        v5 <= 200;
        v6 <= 200;
        v7 <= 100;
    end else begin
        if(trans || trans_one) begin
            v0 <= amt;
        end
    end
end

always @(posedge clk) begin
    go_f <= go;
end

always @(posedge clk) begin
    if(crt)
        obj_type <= typ;
end

always @(posedge clk) begin
    if(crt) begin
        gmt_op <= 4'h0;
    end else if (del) begin
        gmt_op <= 4'h1;
    end else if (trans_one) begin
        gmt_op <= 4'h3;
    end else if (trans) begin
        gmt_op <= 4'h4;
    end else if (rotl) begin
        gmt_op <= 4'h6;
    end else if (rotr) begin
        gmt_op <= 4'h7;
    end else if (scale) begin
        gmt_op <= 4'h8;
    end
end

always @(posedge clk) begin
    if (trans) begin
        gmt_code <= {2'h0, xy};
    end else if (trans_one) begin
        gmt_code <= {pt, xy};
    end else if (rotl) begin
        gmt_code <= {cen, amt[2:0]};
    end else if (rotr) begin
        gmt_code <= {cen, amt[2:0]};
    end else if (scale) begin
        gmt_code <= {2'h0, amt[1:0]};
    end
end

always @(posedge clk) begin
    if (del || trans_one || trans || rotl || rotr || scale) begin
        obj_num_in <= num;
    end
end

reg [3:0] st, nxt_st;
reg [3:0] cnt;
reg inc_cnt, clr_cnt;
localparam INST=4'h0, WAIT=4'h1;

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 4'h0;
    end else begin
        if(inc_cnt)
            cnt <= cnt +1;
        if(clr_cnt)
            cnt <= 4'h0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        st <= INST;
    end else begin
        st <= nxt_st;
    end
end

always@(*) begin
go = 1'b0;
crt = 1'b0;
del = 1'b0;
trans_one = 1'b0;
trans = 1'b0;
rotl = 1'b0;
rotr = 1'b0;
scale = 1'b0;
typ = 2'h0;
num = 5'h0;
amt = 16'h0;
xy = 2'h0;
pt = 2'h0;
cen = 1'h0;
inc_cnt = 1'b0;
clr_cnt = 1'b0;
case(st)
    INST:
    begin
        if(cnt == 0) begin //obj0 - quad
            go = 1'b1;
            crt = 1'b1;
            typ = 2'h3;
            nxt_st = WAIT;
        end else if (cnt == 1) begin //obj1 - tri
            go = 1'b1;
            crt = 1'b1;
            typ = 2'h2;
            nxt_st = WAIT;
        end else if (cnt == 2) begin //obj2 - line
            go = 1'b1;
            crt = 1'b1;
            typ = 2'h1;
            nxt_st = WAIT;
        end else if (cnt == 3) begin //rotr obj0 by 30deg around cen
            go = 1'b1;
            rotr = 1'b1;
            num = 5'h0;
            amt = 16'h2;
            cen = 1'b1;
            nxt_st = WAIT;
        end else if (cnt == 4) begin //translate obj1 by 300 along y
            go = 1'b1;
            trans = 1'b1;
            num = 5'h1;
            amt = 16'd300;
            xy = 2'h2;
            nxt_st = WAIT;
        end else if (cnt == 5) begin //del the tri
            go = 1'b1;
            del = 1'b1;
            num = 5'h1;
            nxt_st = WAIT;
        end else if (cnt == 6) begin //crt a tri
            go = 1'b1;
            crt = 1'b1;
            typ = 2'h2;
            nxt_st = WAIT;
        end else if (cnt == 7) begin //tranlate obj0 by -150 on both x and y
            go = 1'b1;
            trans = 1'b1;
            num = 5'h0;
            amt = -150;
            xy = 2'h3;
            nxt_st = WAIT;
        end else if (cnt == 8) begin //trans pt 2 (0-based) of obj0 by 50 along x
            go = 1'b1;
            trans_one = 1'b1;
            num = 5'h0;
            amt = 16'd50;
            pt = 2'h1;
            xy = 2'h1;
            nxt_st = WAIT;
        end else if (cnt == 9) begin //rotl obj1 by 60deg around origin
            go = 1'b1;
            rotl = 1'b1;
            num = 5'h1;
            amt = 16'h4;
            cen = 1'h0;
            nxt_st = WAIT;
        end else if (cnt == 10) begin //rotr obj2 by 45deg around origin
            go = 1'b1;
            rotr = 1'b1;
            num = 5'h2;
            amt = 16'h3;
            cen = 1'h0;
            nxt_st = WAIT;
        end else if (cnt == 11) begin
            nxt_st = INST;
        end
    end
    WAIT: 
    begin
        if(busy) begin
            nxt_st = WAIT;
        end else begin
            inc_cnt = 1'b1;
            nxt_st = INST;
        end
    end

endcase
end

endmodule
