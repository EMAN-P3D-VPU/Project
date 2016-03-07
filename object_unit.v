module object_unit(input clk,
                    input rst_n,
                    //FROM matrix_unit
                    input crt_obj, //should be a pulse
                    input del_obj, //should be a pulse
                    input ref_addr, //should be a pulse
                    input [4:0] obj_num,
                    input changed_in,

                    //TO video_memory_unit
                    output reg[8:0] addr,
                    output reg addr_vld,
                    //to matrix_unit
                    output reg [4:0] lst_stored_obj,
                    output reg lst_stored_obj_vld,
                    output reg obj_mem_full,
                    //to clipping logic
                    output reg [31:0] obj_map,
                    //to framebuffer and rasterizer
                    output reg changed_out);

reg inc_nxt, set_mem_full, clr_mem_full, drive_addr, drive_ref_addr;
reg set_nxt_obj, set_lst_stored_obj;
reg [4:0] curr_obj, nxt_obj;

localparam IDLE=2'b00, SET_NXT_OBJ=2'b01, DRIVE_ADDR=2'b10, DRIVE_REF_ADDR=2'b11;
reg [1:0] st, nxt_st;

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
    end else begin
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        obj_map <= 32'b0;
    end
    //after reset, the SM will handle this
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        nxt_obj <= 5'b0;
    end else begin
        if(inc_nxt)
            nxt_obj <= nxt_obj +1;
        else if (set_nxt_obj)
            nxt_obj <= obj_num;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        lst_stored_obj <= 5'b0;
    end else begin
        if (set_lst_stored_obj)
            lst_stored_obj <= nxt_obj;
    end
end

always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        lst_stored_obj_vld <= 1'b0;
    end else begin
        if (set_lst_stored_obj)
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
            addr <= 12*curr_obj;
        else if (drive_ref_addr)
            addr <= 12*obj_num;
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
drive_addr = 1'b0;
drive_ref_addr = 1'b0;
set_lst_stored_obj = 1'b0;
case(st)
    IDLE:
        if (crt_obj) begin
            obj_map[nxt_obj] = 1'b1; //write into the obj_map (maybe not synthesizable)
            curr_obj = nxt_obj;//mark this loc as the curr obj
            set_lst_stored_obj = 1'b1;//return value of lst_stored_obj to CPU
            if(nxt_obj == 31) begin //1st check for full memory
                set_mem_full = 1'b1;
                nxt_st = DRIVE_ADDR;
            end else begin //if memory is not full, move nxt_obj to the next free loc
                inc_nxt = 1'b1;
                nxt_st = SET_NXT_OBJ;
            end
        end else if (del_obj) begin
            clr_mem_full = 1'b1; //clear mem_full flag
            obj_map[obj_num] = 1'b0; //clear obj_map
            if(obj_num < nxt_obj) //always use the free location with lowest index for nxt_obj
                set_nxt_obj = 1'b1;
                nxt_st = IDLE;
        end else if (ref_addr) begin //simply read the obj_num given by CPU and translate address
            nxt_st = DRIVE_REF_ADDR;
        end else begin
            nxt_st = IDLE;
        end
    SET_NXT_OBJ:
        if(obj_map[nxt_obj] == 1'b0) begin //fix this
            nxt_st = DRIVE_ADDR;
        end else if (nxt_obj == 31) begin //2nd check for full memory
            set_mem_full = 1'b1;
            nxt_st = DRIVE_ADDR;
        end else begin
            inc_nxt = 1'b1;
            nxt_st = SET_NXT_OBJ;
        end
    DRIVE_ADDR:
        begin
            drive_addr = 1'b1;
            nxt_st = IDLE;
        end
    DRIVE_REF_ADDR:
        begin
            drive_ref_addr = 1'b1;
            nxt_st = IDLE;
        end

endcase
end

endmodule
