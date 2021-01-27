require 'rubyserial'

serialport = Serial.new '/dev/ttyUSB1', 19200
addr,data=ARGV.map{|s| s.to_i(16)}
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
puts "writing bytes : #{bytes_hex}"

nb_bytes=serialport.write bytes.pack("C*")
puts "#{nb_bytes} bytes written"
