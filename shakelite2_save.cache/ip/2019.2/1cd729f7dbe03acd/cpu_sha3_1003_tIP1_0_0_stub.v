// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Sat Oct 11 11:55:44 2025
// Host        : DESKTOP-HPA0FNB running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ cpu_sha3_1003_tIP1_0_0_stub.v
// Design      : cpu_sha3_1003_tIP1_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg400-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "sha3_1003_tIP1_v1_0,Vivado 2019.2" *)
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix(s0_axi_aclk, s0_axi_aresetn, s0_axi_awaddr, 
  s0_axi_awprot, s0_axi_awvalid, s0_axi_awready, s0_axi_wdata, s0_axi_wstrb, s0_axi_wvalid, 
  s0_axi_wready, s0_axi_bresp, s0_axi_bvalid, s0_axi_bready, s0_axi_araddr, s0_axi_arprot, 
  s0_axi_arvalid, s0_axi_arready, s0_axi_rdata, s0_axi_rresp, s0_axi_rvalid, s0_axi_rready)
/* synthesis syn_black_box black_box_pad_pin="s0_axi_aclk,s0_axi_aresetn,s0_axi_awaddr[7:0],s0_axi_awprot[2:0],s0_axi_awvalid,s0_axi_awready,s0_axi_wdata[31:0],s0_axi_wstrb[3:0],s0_axi_wvalid,s0_axi_wready,s0_axi_bresp[1:0],s0_axi_bvalid,s0_axi_bready,s0_axi_araddr[7:0],s0_axi_arprot[2:0],s0_axi_arvalid,s0_axi_arready,s0_axi_rdata[31:0],s0_axi_rresp[1:0],s0_axi_rvalid,s0_axi_rready" */;
  input s0_axi_aclk;
  input s0_axi_aresetn;
  input [7:0]s0_axi_awaddr;
  input [2:0]s0_axi_awprot;
  input s0_axi_awvalid;
  output s0_axi_awready;
  input [31:0]s0_axi_wdata;
  input [3:0]s0_axi_wstrb;
  input s0_axi_wvalid;
  output s0_axi_wready;
  output [1:0]s0_axi_bresp;
  output s0_axi_bvalid;
  input s0_axi_bready;
  input [7:0]s0_axi_araddr;
  input [2:0]s0_axi_arprot;
  input s0_axi_arvalid;
  output s0_axi_arready;
  output [31:0]s0_axi_rdata;
  output [1:0]s0_axi_rresp;
  output s0_axi_rvalid;
  input s0_axi_rready;
endmodule
