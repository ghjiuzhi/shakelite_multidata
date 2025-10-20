connect -url tcp:127.0.0.1:3121
targets -set -nocase -filter {name =~"APU*"}
rst -system
after 3000
targets -set -filter {jtag_cable_name =~ "Digilent JTAG-HS1 210512180081" && level==0} -index 1
fpga -file D:/fpga/shakelite2_save/vitis_1019/new/_ide/bitstream/cpu_wrapper.bit
targets -set -nocase -filter {name =~"APU*"}
loadhw -hw D:/fpga/shakelite2_save/vitis_1019/cpu_wrapper/export/cpu_wrapper/hw/cpu_wrapper.xsa -mem-ranges [list {0x40000000 0xbfffffff}]
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
source D:/fpga/shakelite2_save/vitis_1019/new/_ide/psinit/ps7_init.tcl
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "*A9*#0"}
dow D:/fpga/shakelite2_save/vitis_1019/new/Debug/new.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "*A9*#0"}
con
