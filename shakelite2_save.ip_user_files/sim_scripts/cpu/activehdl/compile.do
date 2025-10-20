vlib work
vlib activehdl

vlib activehdl/xilinx_vip
vlib activehdl/xpm
vlib activehdl/xil_defaultlib
vlib activehdl/axi_infrastructure_v1_1_0
vlib activehdl/axi_vip_v1_1_6
vlib activehdl/processing_system7_vip_v1_0_8
vlib activehdl/lib_cdc_v1_0_2
vlib activehdl/proc_sys_reset_v5_0_13
vlib activehdl/generic_baseblocks_v2_1_0
vlib activehdl/fifo_generator_v13_2_5
vlib activehdl/axi_data_fifo_v2_1_19
vlib activehdl/axi_register_slice_v2_1_20
vlib activehdl/axi_protocol_converter_v2_1_20

vmap xilinx_vip activehdl/xilinx_vip
vmap xpm activehdl/xpm
vmap xil_defaultlib activehdl/xil_defaultlib
vmap axi_infrastructure_v1_1_0 activehdl/axi_infrastructure_v1_1_0
vmap axi_vip_v1_1_6 activehdl/axi_vip_v1_1_6
vmap processing_system7_vip_v1_0_8 activehdl/processing_system7_vip_v1_0_8
vmap lib_cdc_v1_0_2 activehdl/lib_cdc_v1_0_2
vmap proc_sys_reset_v5_0_13 activehdl/proc_sys_reset_v5_0_13
vmap generic_baseblocks_v2_1_0 activehdl/generic_baseblocks_v2_1_0
vmap fifo_generator_v13_2_5 activehdl/fifo_generator_v13_2_5
vmap axi_data_fifo_v2_1_19 activehdl/axi_data_fifo_v2_1_19
vmap axi_register_slice_v2_1_20 activehdl/axi_register_slice_v2_1_20
vmap axi_protocol_converter_v2_1_20 activehdl/axi_protocol_converter_v2_1_20

vlog -work xilinx_vip  -sv2k12 "+incdir+D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/include" \
"D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
"D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
"D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xpm  -sv2k12 "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ec67/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/2d50/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ip/cpu_processing_system7_0_0" "+incdir+D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/include" \
"D:/ruanjian/Vivado/Vivado/2019.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"D:/ruanjian/Vivado/Vivado/2019.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"D:/ruanjian/Vivado/Vivado/2019.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ec67/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/2d50/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ip/cpu_processing_system7_0_0" "+incdir+D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/include" \
"../../../bd/cpu/ip/cpu_processing_system7_0_0/cpu_processing_system7_0_0_sim_netlist.v" \

vcom -work xil_defaultlib -93 \
"../../../bd/cpu/ip/cpu_processing_system7_0_0/cpu_processing_system7_0_0_sim_netlist.vhdl" \

vlog -work axi_infrastructure_v1_1_0  -v2k5 "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ec67/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/2d50/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ip/cpu_processing_system7_0_0" "+incdir+D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/include" \
"../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work axi_vip_v1_1_6  -sv2k12 "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ec67/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/2d50/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ip/cpu_processing_system7_0_0" "+incdir+D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/include" \
"../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/dc12/hdl/axi_vip_v1_1_vl_rfs.sv" \

vlog -work processing_system7_vip_v1_0_8  -sv2k12 "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ec67/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/2d50/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ip/cpu_processing_system7_0_0" "+incdir+D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/include" \
"../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/2d50/hdl/processing_system7_vip_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ec67/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/2d50/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ip/cpu_processing_system7_0_0" "+incdir+D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/include" \
"../../../bd/cpu/ip/cpu_processing_system7_0_0/sim/cpu_processing_system7_0_0.v" \
"../../../bd/cpu/ip/cpu_rst_ps7_0_50M_0/cpu_rst_ps7_0_50M_0_sim_netlist.v" \

vcom -work xil_defaultlib -93 \
"../../../bd/cpu/ip/cpu_rst_ps7_0_50M_0/cpu_rst_ps7_0_50M_0_sim_netlist.vhdl" \

vcom -work lib_cdc_v1_0_2 -93 \
"../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ef1e/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_13 -93 \
"../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/8842/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../bd/cpu/ip/cpu_rst_ps7_0_50M_0/sim/cpu_rst_ps7_0_50M_0.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ec67/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/2d50/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ip/cpu_processing_system7_0_0" "+incdir+D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/include" \
"../../../bd/cpu/ipshared/a5b1/src/keccak_round.v" \
"../../../bd/cpu/ipshared/a5b1/src/keccak_round_constants_gen.v" \
"../../../bd/cpu/ipshared/a5b1/src/keccak_top.v" \
"../../../bd/cpu/ipshared/a5b1/src/sha256.v" \
"../../../bd/cpu/ipshared/a5b1/src/sha2_top.v" \
"../../../bd/cpu/ipshared/a5b1/src/sha512.v" \
"../../../bd/cpu/ipshared/a5b1/hdl/shake_sha2_ip_v1_0_S00_AXI.v" \
"../../../bd/cpu/ipshared/a5b1/src/shake_sha2_top.v" \
"../../../bd/cpu/ipshared/a5b1/src/shake_top.v" \
"../../../bd/cpu/ipshared/a5b1/hdl/shake_sha2_ip_v1_0.v" \
"../../../bd/cpu/ip/cpu_shake_sha2_ip_0_0/sim/cpu_shake_sha2_ip_0_0.v" \

vlog -work generic_baseblocks_v2_1_0  -v2k5 "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ec67/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/2d50/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ip/cpu_processing_system7_0_0" "+incdir+D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/include" \
"../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/b752/hdl/generic_baseblocks_v2_1_vl_rfs.v" \

vlog -work fifo_generator_v13_2_5  -v2k5 "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ec67/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/2d50/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ip/cpu_processing_system7_0_0" "+incdir+D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/include" \
"../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/276e/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_5 -93 \
"../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/276e/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_5  -v2k5 "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ec67/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/2d50/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ip/cpu_processing_system7_0_0" "+incdir+D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/include" \
"../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/276e/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work axi_data_fifo_v2_1_19  -v2k5 "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ec67/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/2d50/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ip/cpu_processing_system7_0_0" "+incdir+D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/include" \
"../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/60de/hdl/axi_data_fifo_v2_1_vl_rfs.v" \

vlog -work axi_register_slice_v2_1_20  -v2k5 "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ec67/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/2d50/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ip/cpu_processing_system7_0_0" "+incdir+D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/include" \
"../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/72d4/hdl/axi_register_slice_v2_1_vl_rfs.v" \

vlog -work axi_protocol_converter_v2_1_20  -v2k5 "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ec67/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/2d50/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ip/cpu_processing_system7_0_0" "+incdir+D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/include" \
"../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/c4a6/hdl/axi_protocol_converter_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/ec67/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ipshared/2d50/hdl" "+incdir+../../../../shakelite2_save.srcs/sources_1/bd/cpu/ip/cpu_processing_system7_0_0" "+incdir+D:/ruanjian/Vivado/Vivado/2019.2/data/xilinx_vip/include" \
"../../../bd/cpu/ip/cpu_auto_pc_0/sim/cpu_auto_pc_0.v" \
"../../../bd/cpu/sim/cpu.v" \

vlog -work xil_defaultlib \
"glbl.v"

