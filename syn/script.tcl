set partname "xc7a100tcsg324-1"
set xdc_constraints "./nexysa7.xdc"
set outputDir ./SYNTH_OUTPUTS
file mkdir $outputDir
read_vhdl -library ip_lib    ../hdl/bram.vhd
read_vhdl -library ip_lib    ../hdl/fifo.vhd
read_vhdl -library ip_lib    ../hdl/ip_bram.vhd
read_vhdl -library ip_lib    ../hdl/ip_leds.vhd
read_vhdl -library ip_lib    ../hdl/ip_switches.vhd
read_vhdl -library ip_lib    ../hdl/simji_core.vhd
read_vhdl -library ip_lib    ../hdl/ip_simji.vhd

read_vhdl -library uart_lib  ../hdl/uart_cst.vhd
read_vhdl -library uart_lib  ../hdl/receiver.vhd
read_vhdl -library uart_lib  ../hdl/sender.vhd
read_vhdl -library uart_lib  ../hdl/tick_gen.vhd
read_vhdl -library uart_lib  ../hdl/uart.vhd

read_vhdl -library uart_bus_master_lib ../hdl/uart_bus_master_fsm.vhd
read_vhdl -library uart_bus_master_lib ../hdl/uart_bus_master.vhd

read_vhdl -library soc_lib ../hdl/soc_pkg.vhd
read_vhdl -library soc_lib ../hdl/soc.vhd

read_xdc $xdc_constraints
synth_design -top soc -part $partname
write_checkpoint -force $outputDir/post_synth.dcp
report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
report_utilization -file $outputDir/post_synth_util.rpt

opt_design
place_design

write_checkpoint -force $outputDir/post_place.dcp
report_utilization -file $outputDir/post_place_util.rpt
report_timing_summary -file $outputDir/post_place_timing_summary.rpt
route_design
write_checkpoint -force $outputDir/post_route.dcp
report_route_status -file $outputDir/post_route_status.rpt
report_timing_summary -file $outputDir/post_route_timing_summary.rpt
report_power -file $outputDir/post_route_power.rpt
report_drc -file $outputDir/post_imp_drc.rpt
write_bitstream -force $outputDir/top.bit
exit
