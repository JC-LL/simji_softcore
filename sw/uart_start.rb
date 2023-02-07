require "uart"
uart = UART.open '/dev/ttyUSB1', 19200, '8N1'

START = 0b01
STOP  = 0b10

puts "sending command 'start' = 0x#{START.to_s(16)}"
uart.write [START].pack 'C'
