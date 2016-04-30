module clipping_line_handler(input clk,
                    input rst_n,
                    input [143:0] obj,
                    input cycle_1, cycle_2, cycle_3, cycle_4,
                    input obj_vld, prev_obj_vld,
                    output reg read_en,
                    output reg signed [15:0] x0_in_f0, x1_in_f0, y0_in_f0, y1_in_f0,
                    output reg [7:0] color_in_f0,
                    output [3:0] oc0_in, oc1_in, 
                    output reg f0_wr, clr_f0
                    );

//Pipeline regs for storing obj
reg signed [15:0] x0, y0, x1, y1, x2, y2, x3, y3;
reg [7:0] color_reg;
reg [1:0] type_reg;
//fifo inputs 

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        read_en <= 1'b0;
    end else begin
        if(cycle_2 && obj_vld) begin
            read_en <= 1'b1; //obj will be available on bus after 2 cycles
        end else begin
            read_en <= 1'b0;
        end
    end
end

//STAGE 1 - a new object is loaded from memory every 4th clk
always @(posedge clk) begin
        if(cycle_4 && obj_vld) begin
            x0 <= obj[15:0];
            y0 <= obj[31:16];
            x1 <= obj[47:32];
            y1 <= obj[63:48];
            x2 <= obj[79:64];
            y2 <= obj[95:80];
            x3 <= obj[111:96];
            y3 <= obj[127:112];
            color_reg <= obj[135:128];
            type_reg <= obj[143:142];
        end 
end

//STAGE 2 - obj is split into lines and stored in a fifo
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        x0_in_f0 <= 16'hx;
        y0_in_f0 <= 16'hx;
        x1_in_f0 <= 16'hx;
        y1_in_f0 <= 16'hx;
        clr_f0 <= 1'b1;
        f0_wr <= 1'b0;
    end else begin
        clr_f0 <= 1'b0;
        if(prev_obj_vld) begin 
            if(cycle_1 && type_reg == 0) begin //point
                x0_in_f0 <= x0;
                y0_in_f0 <= y0;
                x1_in_f0 <= x0;
                y1_in_f0 <= y0;
                f0_wr <= 1'b1;
            end else if(cycle_1 && type_reg >= 1) begin //or first line
                x0_in_f0 <= x0;
                y0_in_f0 <= y0;
                x1_in_f0 <= x1;
                y1_in_f0 <= y1;
                f0_wr <= 1'b1;
            end else if(cycle_2 && type_reg >= 2) begin //2nd line of tri or quad
                x0_in_f0 <= x1;
                y0_in_f0 <= y1;
                x1_in_f0 <= x2;
                y1_in_f0 <= y2;
                f0_wr <= 1'b1;
            end else if(cycle_3 && type_reg == 2) begin //3rd line of tri
                x0_in_f0 <= x2;
                y0_in_f0 <= y2;
                x1_in_f0 <= x0;
                y1_in_f0 <= y0;
                f0_wr <= 1'b1;
            end else if(cycle_3 && type_reg == 3) begin //3rd line of quad
                x0_in_f0 <= x2;
                y0_in_f0 <= y2;
                x1_in_f0 <= x3;
                y1_in_f0 <= y3;
                f0_wr <= 1'b1;
            end else if(cycle_4 && type_reg == 3) begin //4th line of quad
                x0_in_f0 <= x3;
                y0_in_f0 <= y3;
                x1_in_f0 <= x0;
                y1_in_f0 <= y0;
                f0_wr <= 1'b1;
            end else begin
                x0_in_f0 <= 16'hx;
                y0_in_f0 <= 16'hx;
                x1_in_f0 <= 16'hx;
                y1_in_f0 <= 16'hx;
                f0_wr <= 1'b0;
            end
            color_in_f0 <= color_reg;
        end
    end
end

assign oc0_in[3] = (y0_in_f0 > 480) ? 1'b1 : 1'b0;
assign oc0_in[2] = (y0_in_f0 < 0)   ? 1'b1 : 1'b0;
assign oc0_in[1] = (x0_in_f0 > 640) ? 1'b1 : 1'b0;
assign oc0_in[0] = (x0_in_f0 < 0)   ? 1'b1 : 1'b0;
assign oc1_in[3] = (y1_in_f0 > 480) ? 1'b1 : 1'b0;
assign oc1_in[2] = (y1_in_f0 < 0)   ? 1'b1 : 1'b0;
assign oc1_in[1] = (x1_in_f0 > 640) ? 1'b1 : 1'b0;
assign oc1_in[0] = (x1_in_f0 < 0)   ? 1'b1 : 1'b0;

endmodule
