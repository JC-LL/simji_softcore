require 'uart'

def to_4bytes int
  (0..3).map{|i| (int >> i*8) & 0xff}
end

BUS_WR=0b11

uart = UART.open '/dev/ttyUSB1', 19200, '8N1'
uart.write [BUS_WR].pack('C')
uart.write to_4bytes(0x00000000).pack('C*')
uart.write to_4bytes(42).pack('C*')
