# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: D:\Project\Vivado_prj\shake_sha2\vitis\shake_sha_system\_ide\scripts\debugger_shake_sha-emulation.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source D:\Project\Vivado_prj\shake_sha2\vitis\shake_sha_system\_ide\scripts\debugger_shake_sha-emulation.tcl
# 
connect -url tcp:localhost:4352
targets 3
dow D:/Project/Vivado_prj/shake_sha2/vitis/shake_sha/Debug/shake_sha.elf
targets 3
con
