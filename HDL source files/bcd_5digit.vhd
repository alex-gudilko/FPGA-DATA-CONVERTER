--------------------------------------------------------------------------------
-- Company: <Mehatronika>
-- Author: <Aleksandr Gudilko>
-- Email: gudilkoalex@gmail.com
--
-- File: BCD_DECODER.vhd
-- File history:
--      <1.2>: <02/04/2015>: <added thousands and tens-thousands digits. MAX 65536 decimal>
--      <1.3>: <02/04/2015>: <MAX 131071 decimal>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- <Decode 16 bit input integer (max 99.999) into 5 digits in BCD code
--
-- Targeted device: <Family::ProASIC3> <Die::M1A3P400> <Package::208 PQFP>
--
--------------------------------------------------------------------------------

library IEEE;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity bcd_5dig is
   Port ( 
      number   : in  std_logic_vector (16 downto 0);
      tensthousands : out std_logic_vector (3 downto 0);
      thousands : out std_logic_vector (3 downto 0);
      hundreds : out std_logic_vector (3 downto 0);
      tens     : out std_logic_vector (3 downto 0);
      ones     : out std_logic_vector (3 downto 0)
   );
end bcd_5dig;
 
architecture Behavioral of bcd_5dig is
 
begin
 
   bin_to_bcd : process (number)
      -- Internal variable for storing bits
      variable shift : unsigned(36 downto 0);
      
	  -- Alias for parts of shift register
      alias num         is shift(16 downto 0);
      alias one         is shift(20 downto 17);
      alias ten         is shift(24 downto 21);
      alias hun         is shift(28 downto 25);
      alias thous       is shift(32 downto 29);
      alias tensthous   is shift(36 downto 33);

      --alias num         is shift(7 downto 0);
      --alias one         is shift(11 downto 8);
      --alias ten         is shift(15 downto 12);
      --alias hun         is shift(19 downto 16);
      --alias thous       is shift(19 downto 16);
      --alias tensthous   is shift(19 downto 16);

   begin
      -- Clear previous number and store new number in shift register
      num := unsigned(number);
      one := X"0";
      ten := X"0";
      hun := X"0";
      thous := X"0";
      tensthous := X"0";
      
	  -- Loop eight times
      for i in 1 to num'Length loop
	     -- Check if any digit is greater than or equal to 5
         if one >= 5 then
            one := one + 3;
         end if;
         
         if ten >= 5 then
            ten := ten + 3;
         end if;
         
         if hun >= 5 then
            hun := hun + 3;
         end if;

         if thous >= 5 then
            thous := thous + 3;
         end if;

         if tensthous >= 5 then
            tensthous := tensthous + 3;
         end if;
         
		 -- Shift entire register left once
         shift := shift_left(shift, 1);
      end loop;
      
	  -- Push decimal numbers to output
      tensthousands <= std_logic_vector(tensthous);
      thousands <= std_logic_vector(thous);
      hundreds <= std_logic_vector(hun);
      tens     <= std_logic_vector(ten);
      ones     <= std_logic_vector(one);
   end process;
 
end Behavioral;
