BUS_WR=0b11
BUS_RD=0b01

def to_4bytes int
  (0..3).map{|i| (int >> i*8) & 0xff}
end

def from_4bytes bytes
  bytes.map.with_index{|e,i| (e << i*8)}.sum
end

transactions=[
  # writing to BRAM1
  [BUS_WR, 0x00000002,0x08200022],
  [BUS_WR, 0x00000003,0x08200023],
  [BUS_WR, 0x00000004,0x60e00024],
  [BUS_WR, 0x00000005,0x81000005],
  [BUS_WR, 0x00000006,0x7c000180],
  [BUS_WR, 0x00000007,0x48a00022],
  [BUS_WR, 0x00000008,0x60a00026],
  [BUS_WR, 0x00000009,0x8180000a],
  [BUS_WR, 0x0000000A,0x38e00023],
  [BUS_WR, 0x0000000B,0x7c000140],
  [BUS_WR, 0x0000000C,0x7c000220],
  [BUS_WR, 0x0000000D,0x7c000040],
  [BUS_WR, 0x0000000E,0x40a00022],
  [BUS_WR, 0x0000000F,0x60a80006],
  [BUS_WR, 0x00000010,0x8180000a],
  [BUS_WR, 0x00000011,0x38e00023],
  [BUS_WR, 0x00000012,0x7c000140],
  [BUS_WR, 0x00000013,0x08200209],
  [BUS_WR, 0x00000014,0x6260000a],
  [BUS_WR, 0x00000015,0x8a80000b],
  [BUS_WR, 0x00000016,0x12600029],
  [BUS_WR, 0x00000017,0x082fffe1],
  [BUS_WR, 0x00000018,0x88400018],
  [BUS_WR, 0x00000019,0x7c000240],
  [BUS_WR, 0x0000001A,0x10600021],
  [BUS_WR, 0x0000001B,0x7c0002c0],

  [BUS_WR, 0x00000202,0x00000001],

]

require 'uart'
uart = UART.open '/dev/ttyUSB1', 19200, '8N1'

transactions.each do |cmd,addr,data|
  if cmd==BUS_WR
    puts "write 0x%08x,   0x%08x" % [addr,data]
    uart.write [BUS_WR].pack 'C'
    uart.write to_4bytes(addr).pack 'C*'
    uart.write to_4bytes(data).pack 'C*'
  else
    print "read  0x%08x -> " % [addr]
    uart.write [BUS_RD].pack 'C'
    uart.write to_4bytes(addr).pack 'C*'
    bytes=[]
    while bytes.size !=4
      byte=uart.read(1)
      bytes << byte.unpack('C') if byte
    end
    bytes.flatten!
    int32=from_4bytes(bytes)
    puts "0x%08x" % [int32]
  end
end
