vlib work
vlib riviera

vlib riviera/xilinx_vip
vlib riviera/xil_defaultlib

vmap xilinx_vip riviera/xilinx_vip
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xilinx_vip  -sv2k12 "+incdir+D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/include" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
"D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../shake_sha2.gen/sources_1/ip/ila_0/hdl/verilog" "+incdir+D:/Downloads/vivado_2020/Vivado/2020.2/data/xilinx_vip/include" \
"../../../../shake_sha2.gen/sources_1/ip/ila_0/sim/ila_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

