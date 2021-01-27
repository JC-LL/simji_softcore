library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package seven_seg_controler_pkg is

  constant NUMBER_OF_DIGITS : natural := 8;

  subtype digit_type is integer range -1 to 15;

  type digits_array is array(NUMBER_OF_DIGITS-1 downto 0) of digit_type;

  subtype segment_type is std_logic_vector(6 downto 0);

  function convert(digit : digit_type) return segment_type;

end package;

package body seven_seg_controler_pkg is
  function convert(digit : digit_type) return segment_type is
    variable ret : std_logic_vector(6 downto 0);
  begin
    ret := (others => '0');
    case digit is
      when -1     => ret := not("0000000");
      when 0      => ret := not("0111111");
      when 1      => ret := not("0000110");
      when 2      => ret := not("1011011");
      when 3      => ret := not("1001111");
      when 4      => ret := not("1100110");
      when 5      => ret := not("1101101");
      when 6      => ret := not("1111101");
      when 7      => ret := not("0000111");
      when 8      => ret := not("1111111");
      when 9      => ret := not("1101111");
      when 10     => ret := not("1110111");--A
      when 11     => ret := not("1111100");--B
      when 12     => ret := not("0111001");--C
      when 13     => ret := not("1011110");--D
      when 14     => ret := not("1111001");--E
      when 15     => ret := not("1110001");--F
      when others => null;
    end case;
    return ret;
  end function;

end package body;
