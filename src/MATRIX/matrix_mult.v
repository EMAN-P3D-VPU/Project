module matrix_mult(input clk,
                    input rst_n,
                    input ld_trans_coeff, ld_scl_coeff, ld_rot_coeff,
                    input get_rotl_coeff, get_rotr_coeff,
                    input trans_one, trans_all, scl_cmd, rotl_cmd, rotr_cmd,
                    input trans_x, trans_y,
                    input [15:0] v0,
                    input [15:0] scl_coeff, scl_coeff_d,
                    input ld_point, do_mult, do_div,
                    input [2:0] point_cnt,
                    input signed [15:0]  x0, y0, x1, y1, x2, y2, x3, y3,
                    input [2:0] rot_amt,
                    output reg signed [15:0] mat_res_x, mat_res_y
                    );

wire signed[15:0] coeff_1, coeff_2, coeff_3, coeff_4;
reg signed [15:0] c11, c12, c13, c21, c22, c23; 
reg signed [15:0] reg_x, reg_y;
reg signed [31:0] mult_res1_x, mult_res1_y, mult_res2_x, mult_res2_y;
wire signed [31:0] sum_1, sum_2;
reg [3:0] coeff_addr;

coeff_ROM cff_ROM(.clk(clk), .addr(coeff_addr), .c1(coeff_1), .c2(coeff_2), .c3(coeff_3), .c4(coeff_4));

always @(posedge clk) begin
        if(get_rotl_coeff)
            coeff_addr <= rot_amt;
        if(get_rotr_coeff)
            coeff_addr <= 8 + rot_amt;
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        c11 <= 16'b0;
        c12 <= 16'b0;
        c13 <= 16'b0;
        c21 <= 16'b0;
        c22 <= 16'b0;
        c23 <= 16'b0;
    end else begin
        if (ld_trans_coeff) begin //translate amt should be in pixels
            c11 <= 1;
            c12 <= 0;
            c13 <= trans_x ? v0 : 0;
            c21 <= 0;
            c22 <= 1;
            c23 <= trans_y ? v0 : 0;
        end else if (ld_scl_coeff) begin
            c11 <= scl_coeff;
            c12 <= 0;
            c13 <= 0;
            c21 <= 0;
            c22 <= scl_coeff;
            c23 <= 0;
        end else if (ld_rot_coeff) begin
            c11 <= coeff_1;
            c12 <= coeff_2;
            c13 <= 16'h0;
            c21 <= coeff_3;
            c22 <= coeff_4;
            c23 <= 16'h0;
        end
    end
end

always @(posedge clk) begin
        if(ld_point) begin
            if (point_cnt == 4'h0) begin
                reg_x <= x0;
                reg_y <= y0;
            end else if (point_cnt == 4'h1) begin
                reg_x <= x1;
                reg_y <= y1;
            end else if (point_cnt == 4'h2) begin
                reg_x <= x2;
                reg_y <= y2;
            end else if (point_cnt == 4'h3) begin
                reg_x <= x3;
                reg_y <= y3;
            end
        end
end

always @(posedge clk) begin
        if(do_mult) begin
                mult_res1_x <= reg_x*c11;
                mult_res1_y <= reg_y*c12;
                mult_res2_x <= reg_x*c21;
                mult_res2_y <= reg_y*c22;
        end
end

//calculating sum of the multiplication terms
assign sum_1 = mult_res1_x + mult_res1_y;
assign sum_2 = mult_res2_x + mult_res2_y;

always @(posedge clk) begin
    if(do_div)
        if(trans_one || trans_all) begin
            mat_res_x <= sum_1[15:0] + c13;//no division required
            mat_res_y <= sum_2[15:0] + c23;
        end else if (scl_cmd && scl_coeff_d == 1) begin
            mat_res_x <= sum_1[15:0] + c13;//no div
            mat_res_y <= sum_2[15:0] + c23;
        end else if (scl_cmd && scl_coeff_d == 2) begin
            mat_res_x <= sum_1[16:1] + c13;//div by 2
            mat_res_y <= sum_2[16:1] + c23;
        end else if (scl_cmd && scl_coeff_d == 4) begin
            mat_res_x <= sum_1[17:2] + c13;//div by 4
            mat_res_y <= sum_2[17:2] + c23;
        end else if(rotl_cmd || rotr_cmd) begin
            mat_res_x <= sum_1[30:15] + c13;//div by 2^15
            mat_res_y <= sum_2[30:15] + c23;
        end
end

endmodule
