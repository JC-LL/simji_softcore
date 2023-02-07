require 'uart'

addr= ARGV.first.to_i

def to_4bytes int
  (0..3).map{|i| (int >> i*8) & 0xff}
end

def from_4bytes bytes
  bytes.map.with_index{|e,i| (e << i*8)}.sum
end

BUS_RD=0b01

uart = UART.open '/dev/ttyUSB1', 19200, '8N1'
# send read command to the bus :
uart.write [BUS_RD].pack 'C'
uart.write to_4bytes(addr).pack 'C*'


# get back value :
bytes=[]
while bytes.size !=4
  byte=uart.read(1)
  bytes << byte.unpack('C') if byte
end
bytes.flatten!

int32=from_4bytes(bytes)
puts "read value #{int32}"
