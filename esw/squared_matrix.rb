require 'colorize'

#pp String.color_samples

require_relative "reg_access"

puts "=======================================================".light_yellow
puts "squared 3x3 matrix program on [SIMJI softcore] on FPGA".light_yellow
puts "=======================================================".light_yellow
puts
puts "let's first program the FPGA with the bistream of the Simji SoC".light_yellow
hit_a_key
system("djtgcfg -d NexysA7 prog -i 0 -f ../syn/SYNTH_OUTPUTS/top.bit")

puts "-"*80
puts "Now let's now remind that we need to send binary code and data to our SoC".light_yellow
hit_a_key
puts "Let's load the binary program in the SoC :".light_yellow
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
program_mem.each_slice(2) do |addr_data|
  addr,data=*addr_data
  wr_reg addr,data,verbose=false
end
hit_a_key

puts "Now send the data code :".light_yellow
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
data_mem.each_slice(2) do |addr_data|
  addr,data=*addr_data
  wr_reg addr,data
end
hit_a_key

puts
puts "Simji softcore is now ready to run !"
puts
hit_a_key

puts " Before running the algorithm on the target, remind that : ".light_yellow
puts " | 1 2 3 |   | 1 2 3 |   | . . . | ".light_yellow
puts " | 4 5 6 | x | 4 5 6 | = | . . . |".light_yellow
puts " | 7 8 9 |   | 7 8 9 |   | . .150|".light_yellow
puts
puts " and note that 150 = 0x96".light_yellow
hit_a_key

puts "-"*80
puts "now let's start Simji softcore !".light_yellow
puts "we need to put a '1' on bit 2 (1<<2)=4 of CORE_CONTROL register, mapped at address 0x0002".light_yellow
wr_reg 0x0002,0x0004
hit_a_key

puts "-"*80
puts "Let's do polling on CORE_STATUS register, mapped at address 0x0003, ".light_yellow
puts "rd_reg 0x0003"
value=0
while value!=1
  puts "polling...".light_yellow
  value=rd_reg(0x0003,true)
end

hit_a_key

puts "It seems that the Simji processor is now stopped. That sounds good : it has hit a STOP instruction.".green
puts "-"*80
puts "Is the result correct ? Let's read the exact data memory location, where the 9th result matrix lies".light_yellow
puts "This coefficient is mapped at address 0x2411. Let's read it and check ".light_yellow
hit_a_key
value=rd_reg(0x2411,true)
if value==150
  puts "\n Success ! Simji has the right result ! 0x96 ".light_yellow
  hit_a_key
  puts "Hope you enjoyed this demo. Have fun !".light_yellow
else
  puts ":-( well. That is not the expected result 0x96.".red
  puts "check that with your instructor"
end
