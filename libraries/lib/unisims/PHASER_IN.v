// $Header: /devl/xcs/repo/env/Databases/CAEInterfaces/verunilibs/data/fuji/PHASER_IN.v,v 1.21 2012/05/22 18:05:22 robh Exp $
///////////////////////////////////////////////////////
//  Copyright (c) 2010 Xilinx Inc.
//  All Right Reserved.
///////////////////////////////////////////////////////
//
//   ____   ___
//  /   /\/   / 
// /___/  \  /     Vendor      : Xilinx 
// \  \    \/      Version : 10.1
//  \  \           Description : Xilinx Functional Simulation Library Component
//  /  /                         Fujisan PHASER IN
// /__/   /\       Filename    : PHASER_IN.v
// \  \  /  \ 
//  \__\/\__ \                    
//                                 
//  Revision: Comment:
//  22APR2010 Initial UNI/UNP/SIM version from yaml
//  03JUN2010 yaml update
//  12JUL2010 enable secureip
//  14SEP2010 yaml, rtl update
//  24SEP2010 yaml, rtl update
//  13OCT2010 yaml, rtl update
//  26OCT2010 rtl update
//  02NOV2010 yaml update
//  05NOV2010 secureip parameter name update
//  01DEC2010 yaml update, REFCLK_PERIOD max
//  09DEC2010 586079 yaml update, tie off defaults
//  20DEC2010 587097 yaml update, OUTPUT_CLK_SRC
//  02FEB2011 592485 yaml, rtl update
//  02JUN2011 610011 rtl update, ADD REFCLK_PERIOD parameter
//  27JUL2011 618669 REFCLK_PERIOD = 0 not allowed
//  15AUG2011 621681 yaml update, remove SIM_SPEEDUP make default
//  01DEC2011 635710 yaml update SEL_CLK_OFFSET = 0 per model alert
//  01MAR2012 637179 (and others) RTL update, TEST_OPT split apart
//  22MAY2012 660507 DQS_AUTO_RECAL default value change
///////////////////////////////////////////////////////

`timescale 1 ps / 1 ps 

module PHASER_IN (
  COUNTERREADVAL,
  FINEOVERFLOW,
  ICLK,
  ICLKDIV,
  ISERDESRST,
  RCLK,

  COUNTERLOADEN,
  COUNTERLOADVAL,
  COUNTERREADEN,
  DIVIDERST,
  EDGEADV,
  FINEENABLE,
  FINEINC,
  FREQREFCLK,
  MEMREFCLK,
  PHASEREFCLK,
  RANKSEL,
  RST,
  SYNCIN,
  SYSCLK
);

  parameter integer CLKOUT_DIV = 4;
  parameter DQS_BIAS_MODE = "FALSE";
  parameter EN_ISERDES_RST = "FALSE";
  parameter integer FINE_DELAY = 0;
  parameter FREQ_REF_DIV = "NONE";
  parameter real MEMREFCLK_PERIOD = 0.000;
  parameter OUTPUT_CLK_SRC = "PHASE_REF";
  parameter real PHASEREFCLK_PERIOD = 0.000;
  parameter real REFCLK_PERIOD = 0.000;
  parameter integer SEL_CLK_OFFSET = 5;
  parameter SYNC_IN_DIV_RST = "FALSE";
  
  localparam in_delay = 1;
  localparam out_delay = 1;
  localparam INCLK_DELAY = 0;
  localparam OUTCLK_DELAY = 1;
  localparam MODULE_NAME = "PHASER_IN";

  output FINEOVERFLOW;
  output ICLK;
  output ICLKDIV;
  output ISERDESRST;
  output RCLK;
  output [5:0] COUNTERREADVAL;

  input COUNTERLOADEN;
  input COUNTERREADEN;
  input DIVIDERST;
  input EDGEADV;
  input FINEENABLE;
  input FINEINC;
  input FREQREFCLK;
  input MEMREFCLK;
  input PHASEREFCLK;
  input RST;
  input SYNCIN;
  input SYSCLK;
  input [1:0] RANKSEL;
  input [5:0] COUNTERLOADVAL;

  reg MEMREFCLK_PERIOD_BINARY;
  reg PHASEREFCLK_PERIOD_BINARY;
  reg REFCLK_PERIOD_BINARY;
  reg [0:0] BURST_MODE_BINARY;
  reg [0:0] CALIB_EDGE_IN_INV_BINARY;
  reg [0:0] CTL_MODE_BINARY;
  reg [0:0] DQS_AUTO_RECAL_BINARY;
  reg [0:0] DQS_BIAS_MODE_BINARY;
  reg [0:0] EN_ISERDES_RST_BINARY;
  reg [0:0] EN_TEST_RING_BINARY;
  reg [0:0] GATE_SET_CLK_MUX_BINARY;
  reg [0:0] HALF_CYCLE_ADJ_BINARY;
  reg [0:0] ICLK_TO_RCLK_BYPASS_BINARY;
  reg [0:0] PHASER_IN_EN_BINARY;
  reg [0:0] REG_OPT_1_BINARY;
  reg [0:0] REG_OPT_2_BINARY;
  reg [0:0] REG_OPT_4_BINARY;
  reg [0:0] RST_SEL_BINARY;
  reg [0:0] SEL_OUT_BINARY;
  reg [0:0] SYNC_IN_DIV_RST_BINARY;
  reg [0:0] TEST_BP_BINARY;
  reg [0:0] UPDATE_NONACTIVE_BINARY;
  reg [0:0] WR_CYCLES_BINARY;
  reg [1:0] FREQ_REF_DIV_BINARY;
  reg [1:0] RD_ADDR_INIT_BINARY;
  reg [2:0] DQS_FIND_PATTERN_BINARY;
  reg [2:0] PD_REVERSE_BINARY;
  reg [2:0] SEL_CLK_OFFSET_BINARY;
  reg [2:0] STG1_PD_UPDATE_BINARY;
  reg [3:0] CLKOUT_DIV_BINARY;
  reg [3:0] CLKOUT_DIV_POS_BINARY;
  reg [3:0] CLKOUT_DIV_ST_BINARY;
  reg [3:0] OUTPUT_CLK_SRC_BINARY;
  reg [5:0] FINE_DELAY_BINARY;

  tri0 GSR = glbl.GSR;

  initial begin
    BURST_MODE_BINARY <= 1'b0;

    case (CLKOUT_DIV)
      4 : CLKOUT_DIV_BINARY <= 4'b0010;
      2 : CLKOUT_DIV_BINARY <= 4'b0000;
      3 : CLKOUT_DIV_BINARY <= 4'b0001;
      5 : CLKOUT_DIV_BINARY <= 4'b0011;
      6 : CLKOUT_DIV_BINARY <= 4'b0100;
      7 : CLKOUT_DIV_BINARY <= 4'b0101;
      8 : CLKOUT_DIV_BINARY <= 4'b0110;
      9 : CLKOUT_DIV_BINARY <= 4'b0111;
      10 : CLKOUT_DIV_BINARY <= 4'b1000;
      11 : CLKOUT_DIV_BINARY <= 4'b1001;
      12 : CLKOUT_DIV_BINARY <= 4'b1010;
      13 : CLKOUT_DIV_BINARY <= 4'b1011;
      14 : CLKOUT_DIV_BINARY <= 4'b1100;
      15 : CLKOUT_DIV_BINARY <= 4'b1101;
      16 : CLKOUT_DIV_BINARY <= 4'b1110;
      default : begin
        $display("Attribute Syntax Error : The Attribute CLKOUT_DIV on %s instance %m is set to %d.  Legal values for this attribute are 2 to 16.", MODULE_NAME, CLKOUT_DIV);
        $finish;
      end
    endcase

    CTL_MODE_BINARY <= 1'b0; // model alert

    case (DQS_BIAS_MODE)
      "FALSE" : DQS_BIAS_MODE_BINARY <= 1'b0;
      "TRUE" : DQS_BIAS_MODE_BINARY <= 1'b1;
      default : begin
        $display("Attribute Syntax Error : The Attribute DQS_BIAS_MODE on %s instance %m is set to %s.  Legal values for this attribute are FALSE or TRUE.", MODULE_NAME, DQS_BIAS_MODE);
        $finish;
      end
    endcase

    case (EN_ISERDES_RST)
      "FALSE" : EN_ISERDES_RST_BINARY <= 1'b0;
      "TRUE" : EN_ISERDES_RST_BINARY <= 1'b1;
      default : begin
        $display("Attribute Syntax Error : The Attribute EN_ISERDES_RST on %s instance %m is set to %s.  Legal values for this attribute are FALSE or TRUE.", MODULE_NAME, EN_ISERDES_RST);
        $finish;
      end
    endcase

    EN_TEST_RING_BINARY <= 1'b0;

    case (FREQ_REF_DIV)
      "NONE" : FREQ_REF_DIV_BINARY <= 2'b00;
      "DIV2" : FREQ_REF_DIV_BINARY <= 2'b01;
      default : begin
        $display("Attribute Syntax Error : The Attribute FREQ_REF_DIV on %s instance %m is set to %s.  Legal values for this attribute are NONE or DIV2.", MODULE_NAME, FREQ_REF_DIV);
        $finish;
      end
    endcase

    HALF_CYCLE_ADJ_BINARY <= 1'b0;

    ICLK_TO_RCLK_BYPASS_BINARY <= 1'b1;

    case (OUTPUT_CLK_SRC)
      "PHASE_REF" : OUTPUT_CLK_SRC_BINARY <= 4'b0000;
      "DELAYED_MEM_REF" : OUTPUT_CLK_SRC_BINARY <= 4'b0101;
      "DELAYED_PHASE_REF" : OUTPUT_CLK_SRC_BINARY <= 4'b0011;
      "DELAYED_REF" : OUTPUT_CLK_SRC_BINARY <= 4'b0001;
      "FREQ_REF" : OUTPUT_CLK_SRC_BINARY <= 4'b1000;
      "MEM_REF" : OUTPUT_CLK_SRC_BINARY <= 4'b0010;
      default : begin
        $display("Attribute Syntax Error : The Attribute OUTPUT_CLK_SRC on %s instance %m is set to %s.  Legal values for this attribute are PHASE_REF, DELAYED_MEM_REF, DELAYED_PHASE_REF, DELAYED_REF, FREQ_REF or MEM_REF.", MODULE_NAME, OUTPUT_CLK_SRC);
        $finish;
      end
    endcase

    PD_REVERSE_BINARY <= 3'b011;

    PHASER_IN_EN_BINARY <= 1'b1;

    STG1_PD_UPDATE_BINARY <= 3'b000;

    case (SYNC_IN_DIV_RST)
      "FALSE" : SYNC_IN_DIV_RST_BINARY <= 1'b0;
      "TRUE" : SYNC_IN_DIV_RST_BINARY <= 1'b1;
      default : begin
        $display("Attribute Syntax Error : The Attribute SYNC_IN_DIV_RST on %s instance %m is set to %s.  Legal values for this attribute are FALSE or TRUE.", MODULE_NAME, SYNC_IN_DIV_RST);
        $finish;
      end
    endcase

    UPDATE_NONACTIVE_BINARY <= 1'b0;

    WR_CYCLES_BINARY <= 1'b0;

    CALIB_EDGE_IN_INV_BINARY <= 1'b0;

    case (CLKOUT_DIV)
        2   : CLKOUT_DIV_POS_BINARY <= 4'b0001;
        3   : CLKOUT_DIV_POS_BINARY <= 4'b0001;
        4   : CLKOUT_DIV_POS_BINARY <= 4'b0010;
        5   : CLKOUT_DIV_POS_BINARY <= 4'b0010;
        6   : CLKOUT_DIV_POS_BINARY <= 4'b0011;
        7   : CLKOUT_DIV_POS_BINARY <= 4'b0011;
        8   : CLKOUT_DIV_POS_BINARY <= 4'b0100;
        9   : CLKOUT_DIV_POS_BINARY <= 4'b0100;
       10   : CLKOUT_DIV_POS_BINARY <= 4'b0101;
       11   : CLKOUT_DIV_POS_BINARY <= 4'b0101;
       12   : CLKOUT_DIV_POS_BINARY <= 4'b0110;
       13   : CLKOUT_DIV_POS_BINARY <= 4'b0110;
       14   : CLKOUT_DIV_POS_BINARY <= 4'b0111;
       15   : CLKOUT_DIV_POS_BINARY <= 4'b0111;
       16   : CLKOUT_DIV_POS_BINARY <= 4'b1000;
     default: CLKOUT_DIV_POS_BINARY <= 4'b0010;
    endcase

    CLKOUT_DIV_ST_BINARY <= 4'b0000;

    DQS_AUTO_RECAL_BINARY <= 1'b1;

    DQS_FIND_PATTERN_BINARY <= 3'b001;

    if ((FINE_DELAY >= 0) && (FINE_DELAY <= 63))
      FINE_DELAY_BINARY <= FINE_DELAY;
    else begin
      $display("Attribute Syntax Error : The Attribute FINE_DELAY on %s instance %m is set to %d.  Legal values for this attribute are 0 to 63.", MODULE_NAME, FINE_DELAY);
      $finish;
    end

    GATE_SET_CLK_MUX_BINARY <= 1'b0;

    if ((MEMREFCLK_PERIOD >  0.000) && (MEMREFCLK_PERIOD <= 5.000))
      MEMREFCLK_PERIOD_BINARY <= 1'b1;
    else begin
      $display("Attribute Syntax Error : The Attribute MEMREFCLK_PERIOD on %s instance %m is set to %2.3f.  Legal values for this attribute are greater than 0.000 but less than or equal 5.000.", MODULE_NAME, MEMREFCLK_PERIOD);
      $finish;
    end

    if ((PHASEREFCLK_PERIOD >  0.000) && (PHASEREFCLK_PERIOD <= 5.000))
      PHASEREFCLK_PERIOD_BINARY <= 1'b1;
    else begin
      $display("Attribute Syntax Error : The Attribute PHASEREFCLK_PERIOD on %s instance %m is set to %2.3f.  Legal values for this attribute are greater than 0.000 but less than or equal 5.000.", MODULE_NAME, PHASEREFCLK_PERIOD);
      $finish;
    end

    RD_ADDR_INIT_BINARY <= 2'b00;


    if ((REFCLK_PERIOD >  0.000) && (REFCLK_PERIOD <= 2.500))
      REFCLK_PERIOD_BINARY <= 1'b1;
    else begin
      $display("Attribute Syntax Error : The Attribute REFCLK_PERIOD on %s instance %m is set to %2.3f.  Legal values for this attribute are greater than 0.000 but less than or equal to 2.500.", MODULE_NAME, REFCLK_PERIOD);
      $finish;
    end

    REG_OPT_1_BINARY <= 1'b0;

    REG_OPT_2_BINARY <= 1'b0;

    REG_OPT_4_BINARY <= 1'b0;

    RST_SEL_BINARY <= 1'b0;

    if ((SEL_CLK_OFFSET >= 0) && (SEL_CLK_OFFSET <= 7))
      SEL_CLK_OFFSET_BINARY <= 0; // Model Alert
    else begin
      $display("Attribute Syntax Error : The Attribute SEL_CLK_OFFSET on %s instance %m is set to %d.  Legal values for this attribute are 0 to 7.", MODULE_NAME, SEL_CLK_OFFSET);
      $finish;
    end

    SEL_OUT_BINARY <= 1'b0;

    TEST_BP_BINARY <= 1'b0;

  end

  wire [3:0] delay_TESTOUT;
  wire [5:0] delay_COUNTERREADVAL;
  wire [8:0] delay_STG1REGR;
  wire delay_DQSFOUND;
  wire delay_DQSOUTOFRANGE;
  wire delay_FINEOVERFLOW;
  wire delay_ICLK;
  wire delay_ICLKDIV;
  wire delay_ISERDESRST;
  wire delay_PHASELOCKED;
  wire delay_RCLK;
  wire delay_SCANOUT;
  wire delay_STG1OVERFLOW;
  wire delay_WRENABLE;

  wire [13:0] delay_TESTIN = 14'h3fff;
  wire [1:0] delay_ENCALIB = 2'b11;
  wire [1:0] delay_ENCALIBPHY = 2'b0;
  wire [1:0] delay_RANKSEL;
  wire [1:0] delay_RANKSELPHY = 2'b0;
  wire [5:0] delay_COUNTERLOADVAL;
  wire [8:0] delay_STG1REGL = 9'h1ff;
  wire delay_BURSTPENDING = 1'b1;
  wire delay_BURSTPENDINGPHY = 1'b0;
  wire delay_COUNTERLOADEN;
  wire delay_COUNTERREADEN;
  wire delay_DIVIDERST;
  wire delay_EDGEADV;
  wire delay_ENSTG1 = 1'b1;
  wire delay_ENSTG1ADJUSTB = 1'b1;
  wire delay_FINEENABLE;
  wire delay_FINEINC;
  wire delay_FREQREFCLK;
  wire delay_MEMREFCLK;
  wire delay_PHASEREFCLK;
  wire delay_RST;
  wire delay_RSTDQSFIND = 1'b1;
  wire delay_SCANCLK = 1'b1;
  wire delay_SCANENB = 1'b1;
  wire delay_SCANIN = 1'b1;
  wire delay_SCANMODEB = 1'b1;
  wire delay_SELCALORSTG1 = 1'b1;
  wire delay_STG1INCDEC = 1'b1;
  wire delay_STG1LOAD = 1'b1;
  wire delay_STG1READ = 1'b1;
  wire delay_SYNCIN;
  wire delay_SYSCLK;
  wire delay_GSR;

  assign #(OUTCLK_DELAY) ICLK = delay_ICLK;
  assign #(OUTCLK_DELAY) ICLKDIV = delay_ICLKDIV;
  assign #(OUTCLK_DELAY) RCLK = delay_RCLK;

  assign #(out_delay) COUNTERREADVAL = delay_COUNTERREADVAL;
  assign #(out_delay) FINEOVERFLOW = delay_FINEOVERFLOW;
  assign #(out_delay) ISERDESRST = delay_ISERDESRST;

  assign #(INCLK_DELAY) delay_SYSCLK = SYSCLK;

  assign #(in_delay) delay_COUNTERLOADEN = COUNTERLOADEN;
  assign #(in_delay) delay_COUNTERLOADVAL = COUNTERLOADVAL;
  assign #(in_delay) delay_COUNTERREADEN = COUNTERREADEN;
  assign #(in_delay) delay_DIVIDERST = DIVIDERST;
  assign #(in_delay) delay_EDGEADV = EDGEADV;
  assign #(in_delay) delay_FINEENABLE = FINEENABLE;
  assign #(in_delay) delay_FINEINC = FINEINC;
  assign #(in_delay) delay_FREQREFCLK = FREQREFCLK;
  assign #(in_delay) delay_MEMREFCLK = MEMREFCLK;
  assign #(in_delay) delay_PHASEREFCLK = PHASEREFCLK;
  assign #(in_delay) delay_RANKSEL = RANKSEL;
  assign #(in_delay) delay_RST = RST;
  assign #(in_delay) delay_SYNCIN = SYNCIN;
  assign delay_GSR = GSR;

  SIP_PHASER_IN # (
    .REFCLK_PERIOD (REFCLK_PERIOD)
    ) PHASER_IN_INST (
    .BURST_MODE (BURST_MODE_BINARY),
    .CALIB_EDGE_IN_INV (CALIB_EDGE_IN_INV_BINARY),
    .CLKOUT_DIV (CLKOUT_DIV_BINARY),
    .CLKOUT_DIV_ST (CLKOUT_DIV_ST_BINARY),
    .CTL_MODE (CTL_MODE_BINARY),
    .DQS_AUTO_RECAL (DQS_AUTO_RECAL_BINARY),
    .DQS_BIAS_MODE (DQS_BIAS_MODE_BINARY),
    .DQS_FIND_PATTERN (DQS_FIND_PATTERN_BINARY),
    .EN_ISERDES_RST (EN_ISERDES_RST_BINARY),
    .EN_TEST_RING (EN_TEST_RING_BINARY),
    .FINE_DELAY (FINE_DELAY_BINARY),
    .FREQ_REF_DIV (FREQ_REF_DIV_BINARY),
    .GATE_SET_CLK_MUX (GATE_SET_CLK_MUX_BINARY),
    .HALF_CYCLE_ADJ (HALF_CYCLE_ADJ_BINARY),
    .ICLK_TO_RCLK_BYPASS (ICLK_TO_RCLK_BYPASS_BINARY),
    .OUTPUT_CLK_SRC (OUTPUT_CLK_SRC_BINARY),
    .PD_REVERSE (PD_REVERSE_BINARY),
    .PHASER_IN_EN (PHASER_IN_EN_BINARY),
    .RD_ADDR_INIT (RD_ADDR_INIT_BINARY),
    .REG_OPT_1 (REG_OPT_1_BINARY),
    .REG_OPT_2 (REG_OPT_2_BINARY),
    .REG_OPT_4 (REG_OPT_4_BINARY),
    .RST_SEL (RST_SEL_BINARY),
    .SEL_CLK_OFFSET (SEL_CLK_OFFSET_BINARY),
    .SEL_OUT (SEL_OUT_BINARY),
    .STG1_PD_UPDATE (STG1_PD_UPDATE_BINARY),
    .SYNC_IN_DIV_RST (SYNC_IN_DIV_RST_BINARY),
    .TEST_BP (TEST_BP_BINARY),
    .UPDATE_NONACTIVE (UPDATE_NONACTIVE_BINARY),
    .WR_CYCLES (WR_CYCLES_BINARY),
    .CLKOUT_DIV_POS (CLKOUT_DIV_POS_BINARY),

    .COUNTERREADVAL (delay_COUNTERREADVAL),
    .DQSFOUND (delay_DQSFOUND),
    .DQSOUTOFRANGE (delay_DQSOUTOFRANGE),
    .FINEOVERFLOW (delay_FINEOVERFLOW),
    .ICLK (delay_ICLK),
    .ICLKDIV (delay_ICLKDIV),
    .ISERDESRST (delay_ISERDESRST),
    .PHASELOCKED (delay_PHASELOCKED),
    .RCLK (delay_RCLK),
    .SCANOUT (delay_SCANOUT),
    .STG1OVERFLOW (delay_STG1OVERFLOW),
    .STG1REGR (delay_STG1REGR),
    .TESTOUT (delay_TESTOUT),
    .WRENABLE (delay_WRENABLE),
    .BURSTPENDING (delay_BURSTPENDING),
    .BURSTPENDINGPHY (delay_BURSTPENDINGPHY),
    .COUNTERLOADEN (delay_COUNTERLOADEN),
    .COUNTERLOADVAL (delay_COUNTERLOADVAL),
    .COUNTERREADEN (delay_COUNTERREADEN),
    .DIVIDERST (delay_DIVIDERST),
    .EDGEADV (delay_EDGEADV),
    .ENCALIB (delay_ENCALIB),
    .ENCALIBPHY (delay_ENCALIBPHY),
    .ENSTG1 (delay_ENSTG1),
    .ENSTG1ADJUSTB (delay_ENSTG1ADJUSTB),
    .FINEENABLE (delay_FINEENABLE),
    .FINEINC (delay_FINEINC),
    .FREQREFCLK (delay_FREQREFCLK),
    .MEMREFCLK (delay_MEMREFCLK),
    .PHASEREFCLK (delay_PHASEREFCLK),
    .RANKSEL (delay_RANKSEL),
    .RANKSELPHY (delay_RANKSELPHY),
    .RST (delay_RST),
    .RSTDQSFIND (delay_RSTDQSFIND),
    .SCANCLK (delay_SCANCLK),
    .SCANENB (delay_SCANENB),
    .SCANIN (delay_SCANIN),
    .SCANMODEB (delay_SCANMODEB),
    .SELCALORSTG1 (delay_SELCALORSTG1),
    .STG1INCDEC (delay_STG1INCDEC),
    .STG1LOAD (delay_STG1LOAD),
    .STG1READ (delay_STG1READ),
    .STG1REGL (delay_STG1REGL),
    .SYNCIN (delay_SYNCIN),
    .SYSCLK (delay_SYSCLK),
    .TESTIN (delay_TESTIN),
    .GSR (delay_GSR)
  );

endmodule // PHASER_IN