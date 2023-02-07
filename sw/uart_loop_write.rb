require 'uart'

pp ARGV
sleep_arg=ARGV.any? ? ARGV.first.to_f : 1

puts "sleep #{sleep_arg}"

def to_4bytes int
  (0..3).map{|i| (int >> i*8) & 0xff}
end


BUS_WR=0b11

uart = UART.open '/dev/ttyUSB1', 19200, '8N1'

addr=0x00000000
data=1
dir=true
while true
  data=dir ? data << 1 : data >> 1
  dir=!dir if data == 2**15 or data==1
  uart.write [BUS_WR].pack 'C'
  uart.write to_4bytes(addr).pack 'C*'
  uart.write to_4bytes(data).pack 'C*'
  sleep sleep_arg
end
