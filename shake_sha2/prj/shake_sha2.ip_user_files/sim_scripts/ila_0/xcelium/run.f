-makelib xcelium_lib/xilinx_vip -sv \
  "D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
  "D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
  "D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
  "D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
  "D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
  "D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
  "D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
  "D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
  "D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/rst_vip_if.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../shake_sha2.gen/sources_1/ip/ila_0/sim/ila_0.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

