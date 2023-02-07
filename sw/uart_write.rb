require 'uart'

addr,data= ARGV.map(&:to_i)

def to_4bytes int
  (0..3).map{|i| (int >> i*8) & 0xff}
end

BUS_WR=0b11

uart = UART.open '/dev/ttyUSB1', 19200, '8N1'
uart.write [BUS_WR].pack('C')
uart.write to_4bytes(addr).pack('C*')
uart.write to_4bytes(data).pack('C*')
