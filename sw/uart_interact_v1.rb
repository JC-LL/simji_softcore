BUS_WR=0b11
BUS_RD=0b01

def to_4bytes int
  (0..3).map{|i| (int >> i*8) & 0xff}
end

def from_4bytes ary
  ary.each_with_index{|byte,idx| byte << (8*idx)}.sum
end

transactions=[
  [BUS_WR, 0x00000000,0x00000005],#wr LEDS 0b101
  [BUS_RD, 0x00000001,0x00000000],#rd SWITCHES
  # writing to BRAM1
  [BUS_WR, 0x00000002,0x000000AA],
  [BUS_WR, 0x00000003,0x000000AA],
  [BUS_WR, 0x00000004,0x000000AA],
  [BUS_WR, 0x00000005,0x000000AA],
  [BUS_WR, 0x00000006,0x000000AA],
  [BUS_WR, 0x00000101,0x000000AA],
  # WRITING to BRAM2
  [BUS_WR, 0x00000102,0x00000001],
  [BUS_WR, 0x00000103,0x00000002],
  [BUS_WR, 0x00000104,0x00000003],
  [BUS_WR, 0x00000105,0x00000004],
  [BUS_WR, 0x00000106,0x00000005],
  [BUS_WR, 0x00000201,0x00000006],
  # READING from BRAM2
  [BUS_RD, 0x00000102,0x00000000],
  [BUS_RD, 0x00000103,0x00000000],
  [BUS_RD, 0x00000104,0x00000000],
  [BUS_RD, 0x00000105,0x00000000],
  [BUS_RD, 0x00000106,0x00000000],
  [BUS_RD, 0x00000201,0x00000000],
  # READING from BRAM1
  [BUS_RD, 0x00000002,0x00000000],
  [BUS_RD, 0x00000003,0x00000000],
  [BUS_RD, 0x00000004,0x00000000],
  [BUS_RD, 0x00000005,0x00000000],
  [BUS_RD, 0x00000006,0x00000000],
  [BUS_RD, 0x00000101,0x00000000],
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
      bytes << byte.unpack('c') if byte
    end
    bytes.flatten!
    int32=from_4bytes(bytes)
    puts "0x%08x" % [int32]
  end

end
