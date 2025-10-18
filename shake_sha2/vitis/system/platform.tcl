# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\Project\Vivado_prj\shake_sha2\vitis\system\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\Project\Vivado_prj\shake_sha2\vitis\system\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {system}\
-hw {D:\Project\Vivado_prj\shake_sha2\vitis\system_wrapper.xsa}\
-proc {ps7_cortexa9_0} -os {standalone} -fsbl-target {psu_cortexa53_0} -out {D:/Project/Vivado_prj/shake_sha2/vitis}

platform write
platform generate -domains 
platform active {system}
platform generate
