module object_unit(input clk,
                    input rst_n,
                    //FROM matrix_unit
                    //matrix_unit must wait for addr_vld to go high before giving new commands
                    input crt_obj, //should be a pulse - TESTED
                    input del_obj, //should be a pulse - TESTED
                    input del_all,
                    input ref_addr, //should be a pulse - TESTED
                    input [4:0] obj_num, // - TESTED
                    input changed_in,

                    //TO video_memory_unit
                    output reg[4:0] addr, // - TESTED
                    //to matrix_unit
                    output reg addr_vld, // - TESTED
                    output reg [4:0] lst_stored_obj,
                    output reg lst_stored_obj_vld,
                    output reg obj_mem_full,
                    //to clipping logic
                    output reg [31:0] obj_map, // - TESTED
                    //to framebuffer and rasterizer
                    output reg changed_out);

reg inc_nxt, set_mem_full, clr_mem_full, drive_addr, drive_ref_addr;
reg set_nxt_obj, clr_nxt_obj, ret_lst_stored_obj, store_in_map, del_from_map;
reg [4:0] curr_obj, nxt_obj;

localparam IDLE=2'b00, SET_NXT_OBJ=2'b01;
reg [1:0] st, nxt_st;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        obj_map <= 32'b0;
    end else begin
        if(del_all) 
            obj_map <= 32'b0;
        else if(store_in_map)
            obj_map[nxt_obj] <= 1'b1; 
        else if(del_from_map)
            obj_map[obj_num] <= 1'b0; 
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        nxt_obj <= 5'b0;
    end else begin
        if(inc_nxt)
            nxt_obj <= nxt_obj +1;
        else if (set_nxt_obj)
            nxt_obj <= obj_num;
        else if (clr_nxt_obj)
            nxt_obj <= 5'b0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        lst_stored_obj <= 5'bx;
    end else begin
        if (ret_lst_stored_obj)
            lst_stored_obj <= nxt_obj;
    end
end

//dont need this i think
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        lst_stored_obj_vld <= 1'b0;
    end else begin
        if (ret_lst_stored_obj)
            lst_stored_obj_vld <= 1'b1;
        else
            lst_stored_obj_vld <= 1'b0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        obj_mem_full <= 1'b0;
    end else begin
        if(set_mem_full)
            obj_mem_full <= 1'b1;
        if(clr_mem_full)
            obj_mem_full <= 1'b0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        addr <= 9'b0;
    end else begin
        if(drive_addr)
            addr <= curr_obj; //mem is 144-bit deep, so no need for multiplier
        else if (drive_ref_addr)
            addr <= obj_num;
        //else hold
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        addr_vld <= 1'b0;
    end else begin
        if(drive_addr || drive_ref_addr)
            addr_vld <= 1'b1;
        else
            addr_vld <= 1'b0;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        changed_out <= 1'b0;
    end else begin
        changed_out <= changed_in;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        st <= IDLE;
    end else begin
        st <= nxt_st;
    end
end

//if obj_mem_full is high, matrix_unit shouldn't be sending any more requests
always @(*) begin
inc_nxt = 1'b0;
set_mem_full = 1'b0;
clr_mem_full = 1'b0;
set_nxt_obj = 1'b0;
clr_nxt_obj = 1'b0;
drive_addr = 1'b0;
drive_ref_addr = 1'b0;
ret_lst_stored_obj = 1'b0;
store_in_map = 1'b0;
del_from_map = 1'b0;
case(st)
    IDLE:
        if (crt_obj) begin
            store_in_map = 1'b1; //write into the obj_map (is this synthesizable?)
            curr_obj = nxt_obj;//save this loc for driving addr later
            ret_lst_stored_obj = 1'b1;//return value of lst_stored_obj to CPU
            if(nxt_obj == 31) begin //check if obj mem is full
                set_mem_full = 1'b1;
                drive_addr = 1'b1;
                nxt_st = IDLE;
            end else begin //if memory is not full, set nxt_obj to the next free loc
                inc_nxt = 1'b1;
                nxt_st = SET_NXT_OBJ;
            end
        end else if (del_obj) begin
            clr_mem_full = 1'b1; //clear mem_full flag
            del_from_map = 1'b1; //clear obj_map entry
            if(obj_num < nxt_obj) //always use the free location with lowest index for nxt_obj
                set_nxt_obj = 1'b1;
                nxt_st = IDLE;
        //end else if (del_all) begin
        //    obj_map = 32'b0; //clear the entire obj_map
        //    clr_nxt_obj = 1'b1;//reset nxt_obj
        //    nxt_st = IDLE;
        end else if (ref_addr) begin //simply read the obj_num given by CPU and translate address
            drive_ref_addr = 1'b1;
            nxt_st = IDLE;
        end else begin
            nxt_st = IDLE;
        end
    SET_NXT_OBJ:
        if(obj_map[nxt_obj] == 1'b0) begin //if the incremented nxt_obj map entry is free
            drive_addr = 1'b1;
            nxt_st = IDLE;
        end else if (nxt_obj == 31) begin //if its not free and we've reached the end of map
            set_mem_full = 1'b1;
            drive_addr = 1'b1;
            nxt_st = IDLE;
        end else begin //else check the next loc in the obj_map
            inc_nxt = 1'b1;
            nxt_st = SET_NXT_OBJ;
        end
endcase
end

endmodule
