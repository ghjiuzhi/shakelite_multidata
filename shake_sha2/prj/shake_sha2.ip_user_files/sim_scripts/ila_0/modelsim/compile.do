vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xilinx_vip
vlib modelsim_lib/msim/xil_defaultlib

vmap xilinx_vip modelsim_lib/msim/xilinx_vip
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xilinx_vip  -incr -sv -L axi_vip_v1_1_8 -L processing_system7_vip_v1_0_10 -L xilinx_vip "+incdir+D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/include" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xil_defaultlib  -incr "+incdir+../../../../shake_sha2.gen/sources_1/ip/ila_0/hdl/verilog" "+incdir+D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/include" \
"../../../../shake_sha2.gen/sources_1/ip/ila_0/sim/ila_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

