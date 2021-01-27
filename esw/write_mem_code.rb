require 'rubyserial'

$serialport = Serial.new '/dev/ttyUSB1', 19200

def wr_reg addr,data
  puts "writing @ 0x#{addr.to_s(16)} 0x#{data.to_s(16).rjust(8,'0')}"
  mask=0xff
  addr_bytes=[]
  for i in 0..1
    addr_bytes.unshift (addr & mask)
    addr=addr >> 8
  end

  mask=0xff
  data_bytes=[]
  for i in 0..3
    data_bytes.unshift (data & mask)
    data=data >> 8
  end

  bytes=[0x3,addr_bytes,data_bytes].flatten

  bytes_hex=bytes.map{|b| "0x%02x" % b}.join(" ")
  #puts "writing bytes : #{bytes_hex}"

  nb_bytes=$serialport.write bytes.pack("C*")
end

def rd_reg addr
  puts "reading @ 0x#{addr.to_s(16)}"

  mask=0xff
  addr_bytes=[]
  for i in 0..1
    addr_bytes.unshift (addr & mask)
    addr=addr >> 8
  end

  bytes =[0x2,addr_bytes].flatten

  $serialport.write bytes.pack("C*")

  bytes_in=[]
  for i in 0..3
    byte=nil
    byte=$serialport.getbyte until byte
    bytes_in << byte
  end

  bytes_s=bytes_in.map{|b| "0x%02x" % b}.join(" ")
  puts "read bytes : #{bytes_s}"
  return bytes_s
end

program_mem=[
  0x1000,0x0820006a,
  0x1001,0x1a80014b,
  0x1002,0x08200001,
  0x1003,0x50400142,
  0x1004,0x8080001e,
  0x1005,0x08200002,
  0x1006,0x50800148,
  0x1007,0x8200001c,
  0x1008,0x08200004,
  0x1009,0x08200005,
  0x100a,0x51400146,
  0x100b,0x81800016,
  0x100c,0x18400146,
  0x100d,0x098000a6,
  0x100e,0x19400147,
  0x100f,0x09c00047,
  0x1010,0x69800008,
  0x1011,0x69c00009,
  0x1012,0x1a000128,
  0x1013,0x09000104,
  0x1014,0x09600025,
  0x1015,0x7c000140,
  0x1016,0x18400146,
  0x1017,0x09800046,
  0x1018,0x09800166,
  0x1019,0x71a00004,
  0x101a,0x08a00022,
  0x101b,0x7c0000c0,
  0x101c,0x08600021,
  0x101d,0x7c000060,
  0x101e,0x00000000,
]

data_mem=[
  0x2400,0x00000001,
  0x2401,0x00000002,
  0x2402,0x00000003,
  0x2403,0x00000004,
  0x2404,0x00000005,
  0x2405,0x00000006,
  0x2406,0x00000007,
  0x2407,0x00000008,
  0x2408,0x00000009,

  0x2409,0x00000000,
  0x240a,0x00000000,
  0x240b,0x00000000,
  0x240c,0x00000000,
  0x240d,0x00000000,
  0x240e,0x00000000,
  0x240f,0x00000000,
  0x2410,0x00000000,
  0x2411,0x00000000,

]

program_mem.each_slice(2) do |addr_instr|
    addr,instr=addr_instr
    wr_reg addr,instr
end
# reread
puts "re-reading program mem"
rr_program_mem=[]
program_mem.each_slice(2).with_index do |addr_instr|
  addr,instr=*addr_instr
  puts "#{addr} #{instr}"
  rr_program_mem << [
    addr.to_s(16).rjust(4,'0'),
    instr.to_s(16).rjust(8,'0'),
    rd_reg(addr)]
end
pp rr_program_mem

puts "writing data memory : matrix (1 2...9)"
data_mem.each_slice(2) do |addr_instr|
    addr,instr=addr_instr
    wr_reg addr,instr
end

start_processor=[0x0002,0x00000004]

wr_reg *start_processor

rd_reg 0x2411
