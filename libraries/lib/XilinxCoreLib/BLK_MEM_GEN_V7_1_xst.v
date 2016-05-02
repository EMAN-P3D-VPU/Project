/******************************************************************************
-- (c) Copyright 2006 - 2011 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
 *****************************************************************************
 *
 * Filename: BLK_MEM_GEN_V7_1.v
 *
 * Description:
 *   This file is the Verilog behvarial model for the
 *       Block Memory Generator Core.
 *
 *****************************************************************************
 * Author: Xilinx
 *
 * History: September 6, 2005 Initial revision
 *****************************************************************************/
`timescale 1ps/1ps

module BLK_MEM_GEN_V7_1_xst
  #(parameter C_FAMILY                  = "virtex5",
    parameter C_XDEVICEFAMILY           = "virtex5",
    parameter C_ELABORATION_DIR         = "",
    parameter C_INTERFACE_TYPE          = 0,
    parameter C_ENABLE_32BIT_ADDRESS    = 0,
    parameter C_AXI_TYPE                = 0,
    parameter C_AXI_SLAVE_TYPE          = 0,
    parameter C_HAS_AXI_ID              = 0,
    parameter C_AXI_ID_WIDTH            = 4,
    parameter C_MEM_TYPE                = 2,
    parameter C_BYTE_SIZE               = 9,
    parameter C_ALGORITHM               = 1,
    parameter C_PRIM_TYPE               = 3,
    parameter C_LOAD_INIT_FILE          = 0,
    parameter C_INIT_FILE_NAME          = "",
    parameter C_USE_DEFAULT_DATA        = 0,
    parameter C_DEFAULT_DATA            = "0",
    parameter C_RST_TYPE                = "SYNC",
    parameter C_HAS_RSTA                = 0,
    parameter C_RST_PRIORITY_A          = "CE",
    parameter C_RSTRAM_A                = 0,
    parameter C_INITA_VAL              = "0",
    parameter C_HAS_ENA                 = 1,
    parameter C_HAS_REGCEA              = 0,
    parameter C_USE_BYTE_WEA            = 0,
    parameter C_WEA_WIDTH               = 1,
    parameter C_WRITE_MODE_A            = "WRITE_FIRST",
    parameter C_WRITE_WIDTH_A           = 32,
    parameter C_READ_WIDTH_A            = 32,
    parameter C_WRITE_DEPTH_A           = 64,
    parameter C_READ_DEPTH_A            = 64,
    parameter C_ADDRA_WIDTH             = 5,
    parameter C_HAS_RSTB                = 0,
    parameter C_RST_PRIORITY_B          = "CE",
    parameter C_RSTRAM_B                = 0,
    parameter C_INITB_VAL              = "0",
    parameter C_HAS_ENB                 = 1,
    parameter C_HAS_REGCEB              = 0,
    parameter C_USE_BYTE_WEB            = 0,
    parameter C_WEB_WIDTH               = 1,
    parameter C_WRITE_MODE_B            = "WRITE_FIRST",
    parameter C_WRITE_WIDTH_B           = 32,
    parameter C_READ_WIDTH_B            = 32,
    parameter C_WRITE_DEPTH_B           = 64,
    parameter C_READ_DEPTH_B            = 64,
    parameter C_ADDRB_WIDTH             = 5,
    parameter C_HAS_MEM_OUTPUT_REGS_A   = 0,
    parameter C_HAS_MEM_OUTPUT_REGS_B   = 0,
    parameter C_HAS_MUX_OUTPUT_REGS_A   = 0,
    parameter C_HAS_MUX_OUTPUT_REGS_B   = 0,
    parameter C_HAS_SOFTECC_INPUT_REGS_A = 0,
    parameter C_HAS_SOFTECC_OUTPUT_REGS_B= 0,
    parameter C_MUX_PIPELINE_STAGES     = 0,
    parameter C_USE_SOFTECC             = 0,
    parameter C_USE_ECC                 = 0,
    parameter C_HAS_INJECTERR           = 0,
    parameter C_SIM_COLLISION_CHECK     = "NONE",
    parameter C_COMMON_CLK              = 1,
    parameter C_DISABLE_WARN_BHV_COLL   = 0,
    parameter C_DISABLE_WARN_BHV_RANGE  = 0
)
  (input                       CLKA,
   input                       RSTA,
   input                       ENA,
   input                       REGCEA,
   input [C_WEA_WIDTH-1:0]     WEA,
   input [C_ADDRA_WIDTH-1:0]   ADDRA,
   input [C_WRITE_WIDTH_A-1:0] DINA,
   output [C_READ_WIDTH_A-1:0] DOUTA,
   input                       CLKB,
   input                       RSTB,
   input                       ENB,
   input                       REGCEB,
   input [C_WEB_WIDTH-1:0]     WEB,
   input [C_ADDRB_WIDTH-1:0]   ADDRB,
   input [C_WRITE_WIDTH_B-1:0] DINB,
   output [C_READ_WIDTH_B-1:0] DOUTB,
   input                       INJECTSBITERR,
   input                       INJECTDBITERR,
   output                      SBITERR,
   output                      DBITERR,
   output [C_ADDRB_WIDTH-1:0]  RDADDRECC,

  //AXI BMG Input and Output Port Declarations

  //AXI Global Signals
  input                         S_ACLK,
  input                         S_ARESETN,

  //AXI                        Full/Lite Slave Write (write side)
  input  [C_AXI_ID_WIDTH-1:0]   S_AXI_AWID,
  input  [31:0]                 S_AXI_AWADDR,
  input  [7:0]                  S_AXI_AWLEN,
  input  [2:0]                  S_AXI_AWSIZE,
  input  [1:0]                  S_AXI_AWBURST,
  input                         S_AXI_AWVALID,
  output                        S_AXI_AWREADY,
  input  [C_WRITE_WIDTH_A-1:0]  S_AXI_WDATA,
  input  [C_WEA_WIDTH-1:0]      S_AXI_WSTRB,
  input                         S_AXI_WLAST,
  input                         S_AXI_WVALID,
  output                        S_AXI_WREADY,
  output [C_AXI_ID_WIDTH-1:0]   S_AXI_BID,
  output [1:0]                  S_AXI_BRESP,
  output                        S_AXI_BVALID,
  input                         S_AXI_BREADY,

  //AXI                        Full/Lite Slave Read (Write side)
  input  [C_AXI_ID_WIDTH-1:0]   S_AXI_ARID,
  input  [31:0]                 S_AXI_ARADDR,
  input  [7:0]                  S_AXI_ARLEN,
  input  [2:0]                  S_AXI_ARSIZE,
  input  [1:0]                  S_AXI_ARBURST,
  input                         S_AXI_ARVALID,
  output                        S_AXI_ARREADY,
  output [C_AXI_ID_WIDTH-1:0]   S_AXI_RID,
  output [C_WRITE_WIDTH_B-1:0]  S_AXI_RDATA,
  output [1:0]                  S_AXI_RRESP,
  output                        S_AXI_RLAST,
  output                        S_AXI_RVALID,
  input                         S_AXI_RREADY,

  //AXI                        Full/Lite Sideband Signals
  input                         S_AXI_INJECTSBITERR,
  input                         S_AXI_INJECTDBITERR,
  output                        S_AXI_SBITERR,
  output                        S_AXI_DBITERR,
  output [C_ADDRB_WIDTH-1:0]    S_AXI_RDADDRECC 

);

// Note: C_ELABORATION_DIR parameter is only used in synthesis 
// (and doesn't get mentioned in the instantiation template Coregen generates). 
// This wrapper file has to work both in simulation and synthesis. So, this 
// parameter exists. It is not used by the behavioral model 
// (BLK_MEM_GEN_V7_1.vhd)

localparam C_FAMILY_LOCALPARAM =      (C_FAMILY=="virtex7" ? "virtex6" : (C_FAMILY=="virtex7l" ? "virtex6" : (C_FAMILY=="qvirtex7" ? "virtex6" : (C_FAMILY=="kintex7" ? "virtex6" : (C_FAMILY=="kintex7l" ? "virtex6" : (C_FAMILY=="qkintex7" ? "virtex6" : (C_FAMILY=="qkintex7l" ? "virtex6" : (C_FAMILY=="artix7" ? "virtex6" : (C_FAMILY=="artix7l" ? "virtex6" : (C_FAMILY=="qartix7" ? "virtex6" : (C_FAMILY=="qartix7l" ? "virtex6" : (C_FAMILY=="aartix7" ? "virtex6" : (C_FAMILY=="zynq" ? "virtex6" : (C_FAMILY=="azynq" ? "virtex6" : (C_FAMILY=="qzynq" ? "virtex6" : (C_FAMILY=="virtex6l" ? "virtex6" : (C_FAMILY=="qvirtex6" ? "virtex6" : (C_FAMILY=="qvirtex6l" ? "virtex6" : (C_FAMILY=="spartan6l" ? "spartan6" : (C_FAMILY=="aspartan6" ? "spartan6" : C_FAMILY))))))))))))))))))));

  BLK_MEM_GEN_V7_1
  #(
    .C_CORENAME                ("blk_mem_gen_v7_1"),
    .C_FAMILY                  (C_FAMILY_LOCALPARAM),
    .C_XDEVICEFAMILY           (C_XDEVICEFAMILY),
    .C_INTERFACE_TYPE          (C_INTERFACE_TYPE),
    .C_ENABLE_32BIT_ADDRESS    (C_ENABLE_32BIT_ADDRESS),
    .C_AXI_TYPE                (C_AXI_TYPE),
    .C_AXI_SLAVE_TYPE          (C_AXI_SLAVE_TYPE),
    .C_HAS_AXI_ID              (C_HAS_AXI_ID),
    .C_AXI_ID_WIDTH            (C_AXI_ID_WIDTH),
    .C_MEM_TYPE                (C_MEM_TYPE),
    .C_BYTE_SIZE               (C_BYTE_SIZE),
    .C_ALGORITHM               (C_ALGORITHM),
    .C_PRIM_TYPE               (C_PRIM_TYPE),
    .C_LOAD_INIT_FILE          (C_LOAD_INIT_FILE),
    .C_INIT_FILE_NAME          (C_INIT_FILE_NAME),
    .C_USE_DEFAULT_DATA        (C_USE_DEFAULT_DATA),
    .C_DEFAULT_DATA            (C_DEFAULT_DATA),
    .C_RST_TYPE                (C_RST_TYPE),
    .C_HAS_RSTA                (C_HAS_RSTA),
    .C_RST_PRIORITY_A          (C_RST_PRIORITY_A),
    .C_RSTRAM_A                (C_RSTRAM_A),
    .C_INITA_VAL               (C_INITA_VAL),
    .C_HAS_ENA                 (C_HAS_ENA),
    .C_HAS_REGCEA              (C_HAS_REGCEA),
    .C_USE_BYTE_WEA            (C_USE_BYTE_WEA),
    .C_WEA_WIDTH               (C_WEA_WIDTH),
    .C_WRITE_MODE_A            (C_WRITE_MODE_A),
    .C_WRITE_WIDTH_A           (C_WRITE_WIDTH_A),
    .C_READ_WIDTH_A            (C_READ_WIDTH_A),
    .C_WRITE_DEPTH_A           (C_WRITE_DEPTH_A),
    .C_READ_DEPTH_A            (C_READ_DEPTH_A),
    .C_ADDRA_WIDTH             (C_ADDRA_WIDTH),
    .C_HAS_RSTB                (C_HAS_RSTB),
    .C_RST_PRIORITY_B          (C_RST_PRIORITY_B),
    .C_RSTRAM_B                (C_RSTRAM_B),
    .C_INITB_VAL               (C_INITB_VAL),
    .C_HAS_ENB                 (C_HAS_ENB),
    .C_HAS_REGCEB              (C_HAS_REGCEB),
    .C_USE_BYTE_WEB            (C_USE_BYTE_WEB),
    .C_WEB_WIDTH               (C_WEB_WIDTH),
    .C_WRITE_MODE_B            (C_WRITE_MODE_B),
    .C_WRITE_WIDTH_B           (C_WRITE_WIDTH_B),
    .C_READ_WIDTH_B            (C_READ_WIDTH_B),
    .C_WRITE_DEPTH_B           (C_WRITE_DEPTH_B),
    .C_READ_DEPTH_B            (C_READ_DEPTH_B),
    .C_ADDRB_WIDTH             (C_ADDRB_WIDTH),
    .C_HAS_MEM_OUTPUT_REGS_A   (C_HAS_MEM_OUTPUT_REGS_A),
    .C_HAS_MEM_OUTPUT_REGS_B   (C_HAS_MEM_OUTPUT_REGS_B),
    .C_HAS_MUX_OUTPUT_REGS_A   (C_HAS_MUX_OUTPUT_REGS_A),
    .C_HAS_MUX_OUTPUT_REGS_B   (C_HAS_MUX_OUTPUT_REGS_B),
    .C_HAS_SOFTECC_INPUT_REGS_A   (C_HAS_SOFTECC_INPUT_REGS_A),
    .C_HAS_SOFTECC_OUTPUT_REGS_B  (C_HAS_SOFTECC_OUTPUT_REGS_B),
    .C_MUX_PIPELINE_STAGES     (C_MUX_PIPELINE_STAGES),
    .C_USE_SOFTECC             (C_USE_SOFTECC),
    .C_USE_ECC                 (C_USE_ECC),
    .C_HAS_INJECTERR           (C_HAS_INJECTERR),
    .C_SIM_COLLISION_CHECK     (C_SIM_COLLISION_CHECK),
    .C_COMMON_CLK              (C_COMMON_CLK),
    .C_DISABLE_WARN_BHV_COLL   (C_DISABLE_WARN_BHV_COLL),
    .C_DISABLE_WARN_BHV_RANGE  (C_DISABLE_WARN_BHV_RANGE)
    ) blk_mem_gen_v7_1_dut (
    .CLKA          (CLKA),
    .RSTA          (RSTA),
    .ENA           (ENA),
    .REGCEA        (REGCEA),
    .WEA           (WEA),
    .ADDRA         (ADDRA),
    .DINA          (DINA),
    .DOUTA         (DOUTA),
    .CLKB          (CLKB),
    .RSTB          (RSTB),
    .ENB           (ENB),
    .REGCEB        (REGCEB),
    .WEB           (WEB),
    .ADDRB         (ADDRB),
    .DINB          (DINB),
    .DOUTB         (DOUTB),
    .INJECTSBITERR (INJECTSBITERR),
    .INJECTDBITERR (INJECTDBITERR),
    .SBITERR       (SBITERR),
    .DBITERR       (DBITERR),
    .RDADDRECC     (RDADDRECC),
    .S_ACLK        (S_ACLK),
    .S_ARESETN           (S_ARESETN),
    .S_AXI_AWID          (S_AXI_AWID),
    .S_AXI_AWADDR        (S_AXI_AWADDR),
    .S_AXI_AWLEN         (S_AXI_AWLEN),
    .S_AXI_AWSIZE        (S_AXI_AWSIZE),
    .S_AXI_AWBURST (S_AXI_AWBURST),
    .S_AXI_AWVALID (S_AXI_AWVALID),
    .S_AXI_AWREADY (S_AXI_AWREADY),
    .S_AXI_WDATA   (S_AXI_WDATA),
    .S_AXI_WSTRB   (S_AXI_WSTRB),
    .S_AXI_WLAST   (S_AXI_WLAST),
    .S_AXI_WVALID  (S_AXI_WVALID),
    .S_AXI_WREADY  (S_AXI_WREADY),
    .S_AXI_BID     (S_AXI_BID),
    .S_AXI_BRESP   (S_AXI_BRESP),
    .S_AXI_BVALID  (S_AXI_BVALID),
    .S_AXI_BREADY  (S_AXI_BREADY),
    .S_AXI_ARID    (S_AXI_ARID),
    .S_AXI_ARADDR  (S_AXI_ARADDR),
    .S_AXI_ARLEN   (S_AXI_ARLEN),
    .S_AXI_ARSIZE  (S_AXI_ARSIZE),
    .S_AXI_ARBURST (S_AXI_ARBURST),
    .S_AXI_ARVALID (S_AXI_ARVALID),
    .S_AXI_ARREADY (S_AXI_ARREADY),
    .S_AXI_RID     (S_AXI_RID),
    .S_AXI_RDATA   (S_AXI_RDATA),
    .S_AXI_RRESP         (S_AXI_RRESP),
    .S_AXI_RLAST         (S_AXI_RLAST),
    .S_AXI_RVALID        (S_AXI_RVALID),
    .S_AXI_RREADY        (S_AXI_RREADY),
    .S_AXI_INJECTSBITERR (S_AXI_INJECTSBITERR),
    .S_AXI_INJECTDBITERR (S_AXI_INJECTDBITERR),
    .S_AXI_SBITERR       (S_AXI_SBITERR),
    .S_AXI_DBITERR(S_AXI_DBITERR),
    .S_AXI_RDADDRECC(S_AXI_RDADDRECC)
);

endmodule

