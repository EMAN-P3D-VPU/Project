module object_unit_tb();
reg clk, rst_n;
reg crt_obj, del_obj, del_all, ref_addr, changed_in;
reg [4:0] obj_num;
wire addr_vld;

object_unit obj_unit(.clk(clk),
                    .rst_n(rst_n),
                    .crt_obj(crt_obj),
                    .del_obj(del_obj),
                    .del_all(del_all),
                    .ref_addr(ref_addr),
                    .obj_num(obj_num),
                    .changed_in(changed_in),
                    .addr_vld(addr_vld)
                    );
initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    crt_obj = 1'b0;
    del_obj = 1'b0;
    #10 rst_n = 1'b1;
    
    //create 5 objects
    @(posedge clk);
    crt_obj = 1'b1;
    @(posedge clk);
    crt_obj = 1'b0;
    wait(addr_vld == 1);

    @(posedge clk);
    crt_obj = 1'b1;
    @(posedge clk);
    crt_obj = 1'b0;
    wait(addr_vld == 1);

    @(posedge clk);
    crt_obj = 1'b1;
    @(posedge clk);
    crt_obj = 1'b0;
    wait(addr_vld == 1);

    @(posedge clk);
    crt_obj = 1'b1;
    @(posedge clk);
    crt_obj = 1'b0;
    wait(addr_vld == 1);

    @(posedge clk);
    crt_obj = 1'b1;
    @(posedge clk);
    crt_obj = 1'b0;
    wait(addr_vld == 1);

    //delete the 3rd
    @(posedge clk);
    obj_num = 3;
    del_obj = 1'b1;
    @(posedge clk);
    del_obj = 1'b0;
    
    //create 1 more
    @(posedge clk);
    crt_obj = 1'b1;
    @(posedge clk);
    crt_obj = 1'b0;
    wait(addr_vld == 1);

    //delete 2 more
    @(posedge clk);
    obj_num = 0;
    del_obj = 1'b1;
    @(posedge clk);
    del_obj = 1'b0;
    
    @(posedge clk);
    obj_num = 4;
    del_obj = 1'b1;
    @(posedge clk);
    del_obj = 1'b0;
    
    //create 2 more
    @(posedge clk);
    crt_obj = 1'b1;
    @(posedge clk);
    crt_obj = 1'b0;
    wait(addr_vld == 1);

    @(posedge clk);
    crt_obj = 1'b1;
    @(posedge clk);
    crt_obj = 1'b0;
    wait(addr_vld == 1);

    @(posedge clk);
    del_all = 1'b1;
    @(posedge clk);
    del_all = 1'b0;
    
end

always #5 clk=~clk;
endmodule
