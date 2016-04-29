module matrix_data(input clk,
            input rst_n,
            input signed [15:0] v0,
            input signed [15:0] v1,
            input signed [15:0] v2,
            input signed [15:0] v3,
            input signed [15:0] v4,
            input signed [15:0] v5,
            input signed [15:0] v6,
            input signed [15:0] v7,
            input [1:0] obj_type,
            input [7:0] obj_color,
            input [3:0] gmt_code,
            input go,
            input crt_cmd, trans_one,
            input writeback, writeback_cen, ld_obj_in, calc_from_cen, ldback_reg,
            input [2:0] point_cnt,
            input [144:0] obj_in,
            input signed [15:0] mat_res_x, mat_res_y,
            output [2:0] max_point_cnt,
            output reg [144:0] obj_out,
            output reg signed [15:0]  x0, y0, x1, y1, x2, y2, x3, y3
            );

reg [7:0] color_reg;
reg [1:0] type_reg;
wire pt0_vld, pt1_vld, pt2_vld, pt3_vld;
wire dont_touch_p0, dont_touch_p1, dont_touch_p2, dont_touch_p3;
wire signed [16:0] sum2_x, sum2_y;
wire signed [17:0] sum4_x, sum4_y;
wire signed [15:0] x_cen_tmp, y_cen_tmp;
reg signed [15:0] x_centroid, y_centroid;
wire signed [15:0] x0_with_cen, y0_with_cen, x1_with_cen, y1_with_cen, x2_with_cen, y2_with_cen, x3_with_cen, y3_with_cen;

assign max_point_cnt = type_reg;
assign pt0_vld = (type_reg >= 0);
assign pt1_vld = (type_reg >= 1);
assign pt2_vld = (type_reg >= 2);
assign pt3_vld = (type_reg == 3);
assign dont_touch_p0 = (trans_one && gmt_code[3:2] != 2'h0)? 1'b1 : 1'b0;
assign dont_touch_p1 = (trans_one && gmt_code[3:2] != 2'h1)? 1'b1 : 1'b0;
assign dont_touch_p2 = (trans_one && gmt_code[3:2] != 2'h2)? 1'b1 : 1'b0;
assign dont_touch_p3 = (trans_one && gmt_code[3:2] != 2'h3)? 1'b1 : 1'b0;
//centroid ops not supported on triangle because it'll need div-by-3
assign sum2_x = x0 + x1;
assign sum2_y = y0 + y1;
assign sum4_x = x0 + x1 + x2 + x3;
assign sum4_y = y0 + y1 + y2 + y3;
assign x_cen_tmp = (type_reg == 2'h0) ? x0 :
                    (type_reg == 2'h1) ? sum2_x[16:1] :
                    (type_reg == 2'h3) ? sum4_x[17:2] : 16'hx;
assign y_cen_tmp = (type_reg == 2'h0) ? y0 :
                    (type_reg == 2'h1) ? sum2_y[16:1] :
                    (type_reg == 2'h3) ? sum4_y[17:2] : 16'hx;
// OBJECT REGISTERS AND BUSES
assign x0_with_cen = x0 + x_centroid;
assign y0_with_cen = y0 + y_centroid;
assign x1_with_cen = x1 + x_centroid;
assign y1_with_cen = y1 + y_centroid;
assign x2_with_cen = x2 + x_centroid;
assign y2_with_cen = y2 + y_centroid;
assign x3_with_cen = x3 + x_centroid;
assign y3_with_cen = y3 + y_centroid;



always @(posedge clk) begin
    if(calc_from_cen) begin
        x_centroid <= x_cen_tmp;
        y_centroid <= y_cen_tmp;
    end
end

always @(posedge clk) begin
        if(ld_obj_in) begin
            x0 <= obj_in[15:0];
            y0 <= obj_in[31:16];
            x1 <= obj_in[47:32];
            y1 <= obj_in[63:48];
            x2 <= obj_in[79:64];
            y2 <= obj_in[95:80];
            x3 <= obj_in[111:96];
            y3 <= obj_in[127:112];
            color_reg <= obj_in[135:128];
            type_reg <= obj_in[143:142];
        end else if (calc_from_cen) begin
            x0 <= x0 - x_cen_tmp;
            x1 <= x1 - x_cen_tmp;
            x2 <= x2 - x_cen_tmp;
            x3 <= x3 - x_cen_tmp;
            y0 <= y0 - y_cen_tmp;
            y1 <= y1 - y_cen_tmp;
            y2 <= y2 - y_cen_tmp;
            y3 <= y3 - y_cen_tmp;
        end else if (ldback_reg) begin //
            if(pt0_vld && !dont_touch_p0 && point_cnt == 0) begin //point
                x0 <= mat_res_x;
                y0 <= mat_res_y;
            end
            if(pt1_vld && !dont_touch_p1 && point_cnt == 1) begin //line
                x1 <= mat_res_x;
                y1 <= mat_res_y;
            end
            if(pt2_vld && !dont_touch_p2 && point_cnt == 2) begin //tri
                x2 <= mat_res_x;
                y2 <= mat_res_y;
            end
            if(pt3_vld && !dont_touch_p3 && point_cnt == 3) begin //quad
                x3 <= mat_res_x;
                y3 <= mat_res_y;
            end
        end
end

always @(posedge clk) begin
        if (go && crt_cmd) begin //obj_out gets automatically created without the SM's inteference
            if (obj_type >= 0) begin
                obj_out[15:0] <= v0;
                obj_out[31:16] <= v1;
            end else begin
                obj_out[15:0] <= 16'hx;
                obj_out[31:16] <= 16'hx;
            end
            if (obj_type >= 1) begin
                obj_out[47:32] <= v2;
                obj_out[63:48] <= v3;
            end else begin
                obj_out[47:32] <= 16'hx;
                obj_out[63:48] <= 16'hx;
            end
            if (obj_type >= 2) begin
                obj_out[79:64] <= v4;
                obj_out[95:80] <= v5;
            end else begin
                obj_out[79:64] <= 16'hx;
                obj_out[95:80] <= 16'hx;
            end
            if (obj_type == 3) begin
                obj_out[111:96] <= v6;
                obj_out[127:112] <= v7;
            end else begin
                obj_out[111:96] <= 16'hx;
                obj_out[127:112] <= 16'hx;
            end
            obj_out[135:128] <= obj_color;
            obj_out[143:136] <= {obj_type, 6'h0};
        end else if (writeback) begin
            if (pt0_vld) begin
                obj_out[15:0] <= x0;
                obj_out[31:16] <= y0;
            end else begin
                obj_out[15:0] <= 16'hx;
                obj_out[31:16] <= 16'hx;
            end 
            if (pt1_vld) begin
                obj_out[47:32] <= x1;
                obj_out[63:48] <= y1;
            end else begin
                obj_out[47:32] <= 16'hx;
                obj_out[63:48] <= 16'hx;
            end 
            if (pt2_vld) begin
                obj_out[79:64] <= x2;
                obj_out[95:80] <= y2;
            end else begin
                obj_out[79:64] <= 16'hx;
                obj_out[95:80] <= 16'hx;
            end 
            if (pt3_vld) begin
                obj_out[111:96] <= x3;
                obj_out[127:112] <= y3;
            end else begin
                obj_out[111:96] <= 16'hx;
                obj_out[127:112] <= 16'hx;
            end
            obj_out[135:128] <= color_reg;
            obj_out[143:136] <= {type_reg, 6'b0};
        end else if (writeback_cen) begin
            if (pt0_vld) begin
                obj_out[15:0] <= x0_with_cen;
                obj_out[31:16] <= y0_with_cen;
            end else begin
                obj_out[15:0] <= 16'hx;
                obj_out[31:16] <= 16'hx;
            end 
            if (pt1_vld) begin
                obj_out[47:32] <= x1_with_cen;
                obj_out[63:48] <= y1_with_cen;
            end else begin
                obj_out[47:32] <= 16'hx;
                obj_out[63:48] <= 16'hx;
            end 
            if (pt2_vld) begin
                obj_out[79:64] <= x2_with_cen;
                obj_out[95:80] <= y2_with_cen;
            end else begin
                obj_out[79:64] <= 16'hx;
                obj_out[95:80] <= 16'hx;
            end 
            if (pt3_vld) begin
                obj_out[111:96] <= x3_with_cen;
                obj_out[127:112] <= y3_with_cen;
            end else begin
                obj_out[111:96] <= 16'hx;
                obj_out[127:112] <= 16'hx;
            end
            obj_out[135:128] <= color_reg;
            obj_out[143:136] <= {type_reg, 6'b0};
        end
end

endmodule
