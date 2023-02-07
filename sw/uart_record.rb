require "uart"

TTY='/dev/ttyUSB1'

uart = UART.open TTY, 19200, '8N1'

nb_samples=ARGV.first || 1000
samples=[]

puts "recording #{nb_samples} samples from #{TTY}"

nb_samples.times do
  sample=uart.read(1)
  samples << sample.unpack('c') if sample
end

puts "done."

pp samples.flatten!
File.open("samples.txt",'w'){|f| f.puts samples}

puts "samples saved in 'samples.txt'"
