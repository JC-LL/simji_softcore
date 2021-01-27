rm -rf *.cf
echo "=> compiling board LEDs and 7-segments"
ghdl -a ../hdl/board_related/seven_seg_controler_pkg.vhd
ghdl -a ../hdl/board_related/seven_seg_controler.vhd
ghdl -a ../hdl/board_related/slow_ticker.vhd
echo "=> compiling UART"
ghdl -a ../hdl/uart_bus_master/mod_m_counter.vhd
ghdl -a ../hdl/uart_bus_master/flag_buf.vhd
ghdl -a ../hdl/uart_bus_master/fifo.vhd
ghdl -a ../hdl/uart_bus_master/uart_tx.vhd
ghdl -a ../hdl/uart_bus_master/uart_rx.vhd
ghdl -a ../hdl/uart_bus_master/uart.vhd
echo "=> compiling UART bus master"
ghdl -a ../hdl/uart_bus_master/uart_bus_master_controler.vhd
ghdl -a ../hdl/uart_bus_master/uart_bus_master.vhd
echo "=> compiling simji core"
ghdl -a ../hdl/simji_core/ram.vhd
ghdl -a ../hdl/simji_core/simji_core.vhd
echo "=> compiling simji soc"
ghdl -a ../hdl/simji_soc/simji_soc.vhd
echo "=> compiling top level"
ghdl -a ../hdl/top_level/top.vhd
