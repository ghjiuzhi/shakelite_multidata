#!/bin/sh

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
# 

echo "This script was generated under a different operating system."
echo "Please update the PATH and LD_LIBRARY_PATH variables below, before executing this script"
exit

if [ -z "$PATH" ]; then
  PATH=D:/Downloads/vivado_2020/Vitis/2020.2/bin;D:/Downloads/vivado_2020/Vivado/2020.2/ids_lite/ISE/bin/nt64;D:/Downloads/vivado_2020/Vivado/2020.2/ids_lite/ISE/lib/nt64:D:/Downloads/vivado_2020/Vivado/2020.2/bin
else
  PATH=D:/Downloads/vivado_2020/Vitis/2020.2/bin;D:/Downloads/vivado_2020/Vivado/2020.2/ids_lite/ISE/bin/nt64;D:/Downloads/vivado_2020/Vivado/2020.2/ids_lite/ISE/lib/nt64:D:/Downloads/vivado_2020/Vivado/2020.2/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=
else
  LD_LIBRARY_PATH=:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD='D:/Project/Vivado_prj/shake_sha2/ip/managed_ip_project/managed_ip_project.tmp/shake_sha2_ip_v1_0_project/shake_sha2_ip_v1_0_project.runs/synth_1'
cd "$HD_PWD"

HD_LOG=runme.log
/bin/touch $HD_LOG

ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

EAStep vivado -log shake_sha2_ip_v1_0.vds -m64 -product Vivado -mode batch -messageDb vivado.pb -notrace -source shake_sha2_ip_v1_0.tcl
