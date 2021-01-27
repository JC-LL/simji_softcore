require 'rubyserial'

$serialport = Serial.new '/dev/ttyUSB1', 19200

def wr_reg addr,data,verbose=false
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
  # command 0x3 is write, followed by address and data :
  bytes=[0x3,addr_bytes,data_bytes].flatten
  if verbose
    bytes_hex=bytes.map{|b| "0x%02x" % b}.join(" ")
    puts "sending bytes : #{bytes_hex}"
  end
  nb_bytes=$serialport.write bytes.pack("C*")
  puts "#bytes sent : #{nb_bytes}" if verbose
end

def rd_reg addr,verbose=false
  puts "reading @ 0x#{addr.to_s(16)}" if verbose

  mask=0xff
  addr_bytes=[]
  for i in 0..1
    addr_bytes.unshift (addr & mask)
    addr=addr >> 8
  end

  bytes =[0x2,addr_bytes].flatten

  $serialport.write bytes.pack("C*")

  bytes_in=[]
  ret_val=0
  for i in 0..3
    byte=nil
    byte=$serialport.getbyte until byte
    bytes_in << byte
    ret_val+=(byte << (3-i)*8)
  end

  if verbose
    bytes_s=bytes_in.map{|b| "0x%02x" % b}.join(" ")
    puts "read bytes : #{bytes_s}"
  end
  return ret_val
end

def hit_a_key
  puts "hit a key to continue"
  $stdin.gets
end
