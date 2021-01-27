require 'rubyserial'

serialport = Serial.new '/dev/ttyUSB1', 19200

addr=ARGV.first.to_i(16)
puts "reading @ 0x#{addr.to_s(16)}"

mask=0xff
addr_bytes=[]
for i in 0..1
  addr_bytes.unshift (addr & mask)
  addr=addr >> 8
end

bytes =[0x2,addr_bytes].flatten

serialport.write bytes.pack("C*")

bytes_in=[]
for i in 0..3
  byte=nil
  byte=serialport.getbyte until byte
  bytes_in << byte
end

bytes_s=bytes_in.map{|b| "0x%02x" % b}.join(" ")
puts "read bytes : #{bytes_s}"
