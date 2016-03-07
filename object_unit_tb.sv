module object_unit_tb();
reg clk, rst_n;
reg crt_obj, del_obj, ref_addr, changed_in;
reg [4:0] obj_num;

object_unit obj_unit(.clk(clk),
                    .rst_n(rst_n),
                    .crt_obj(crt_obj),
                    .del_obj(del_obj),
                    .ref_addr(ref_addr),
                    .obj_num(obj_num),
                    .changed_in(changed_in)
                    );
initial begin
clk = 1'b0;
rst_n = 1'b0;
#10 rst_n = 1'b1;
crt_obj = 1'b1;
#10 crt_obj = 1'b0;
#30 crt_obj = 1'b1;
#10 crt_obj = 1'b0;
#30 crt_obj = 1'b1;
#10 crt_obj = 1'b0;
#30 crt_obj = 1'b1;
#10 crt_obj = 1'b0;
#30 crt_obj = 1'b1;
#10 crt_obj = 1'b0;
obj_num = 3;
del_obj = 1'b1;
#10 del_obj = 1'b0;
#30 crt_obj = 1'b1;
#10 crt_obj = 1'b0;
obj_num = 0;
del_obj = 1'b1;
#10 del_obj = 1'b0;
obj_num = 4;
del_obj = 1'b1;
#10 del_obj = 1'b0;
end

always #5 clk=~clk;
endmodule
