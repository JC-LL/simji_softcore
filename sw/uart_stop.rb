require "uart"
uart = UART.open '/dev/ttyUSB1', 19200, '8N1'

START = 0b01
STOP  = 0b10

puts "sending command 'stop'  = 0x#{ STOP.to_s(16)}"
uart.write [STOP].pack 'C'
