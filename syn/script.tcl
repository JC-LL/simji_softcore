#=============================================================================
# FPGA device
#=============================================================================
set partname "xc7a100tcsg324-1"
set xdc_constraints "./Nexys4DDR_Master.xdc"
#=============================================================================
# STEP#1: define the output directory area.
#=============================================================================
set outputDir ./SYNTH_OUTPUTS
file mkdir $outputDir
#=============================================================================
# STEP#2: setup design sources and constraints
#=============================================================================
#read_vhdl -library command_controler_lib ../hdl/pkg_shared_types.vhd
#read_vhdl -library command_controler_lib ../hdl/pkg_command_controler.vhd
#read_vhdl -library command_controler_lib ../hdl/comp_command_controler.vhd

read_vhdl [glob ../hdl/board_related/*.vhd ]
read_vhdl [glob ../hdl/simji_core/*.vhd ]
read_vhdl [glob ../hdl/uart_bus_master/*.vhd ]
read_vhdl [glob ../hdl/simji_soc/*.vhd ]
read_vhdl [glob ../hdl/top_level/*.vhd ]
read_xdc $xdc_constraints
#=============================================================================
# STEP#3: run synthesis, write design checkpoint, report timing,
# and utilization estimates
#=============================================================================
synth_design -top top -part $partname
write_checkpoint -force $outputDir/post_synth.dcp
report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
report_utilization -file $outputDir/post_synth_util.rpt

#=============================================================================
# Run custom script to report critical timing paths
#   reportCriticalPaths $outputDir/post_synth_critpath_report.csv
#
# STEP#4: run logic optimization, placement and physical logic optimization,
# write design checkpoint, report utilization and timing estimates
#=============================================================================
opt_design
#    reportCriticalPaths $outputDir/post_opt_critpath_report.csv
place_design
#     report_clock_utilization -file $outputDir/clock_util.rpt
#
write_checkpoint -force $outputDir/post_place.dcp
report_utilization -file $outputDir/post_place_util.rpt
report_timing_summary -file $outputDir/post_place_timing_summary.rpt

#=============================================================================
# STEP#5: run the router, write the post-route design checkpoint, report the routing
# status, report timing, power, and DRC, and finally save the Verilog netlist.
#=============================================================================
route_design
write_checkpoint -force $outputDir/post_route.dcp
report_route_status -file $outputDir/post_route_status.rpt
report_timing_summary -file $outputDir/post_route_timing_summary.rpt
report_power -file $outputDir/post_route_power.rpt
report_drc -file $outputDir/post_imp_drc.rpt
# write_verilog -force $outputDir/cpu_impl_netlist.v -mode timesim -sdf_anno true

#=============================================================================
# STEP#6: generate a bitstream
#=============================================================================
write_bitstream -force $outputDir/top.bit
exit
