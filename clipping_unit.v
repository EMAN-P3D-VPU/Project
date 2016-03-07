module clipping_unit(input clk,
                    input rst_n,
                    input [31:0] obj_map,
                    input [147:0] obj,
                    input raster_ready,
                    output [9:0] x0,
                    output [9:0] y0,
                    output [9:0] x1,
                    output [7:0] y1,
                    output [2:0] color,
                    output vld,
                    output end_of_obj,
                    output [8:0] addr,
                    output read_en,
                    output clr_changed
                    );
endmodule
