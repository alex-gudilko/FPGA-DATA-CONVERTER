--------------------------------------------------------------------------------
-- Company: <Mehatronika>
-- Author: 	<Aleksandr Gudilko>
-- Email: 	gudilkoalex@gmail.com
--
-- File: Decoder_1hot_3-to-8.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- 1-hot decoder: decodes input number and makes only 1 output active (high), 
-- while other outputs remain disabled (low)
-- Decoder operation is clocked to avoid output jittering.
--
-- Targeted device: <Family::ProASIC3> <Die::M1A3P400> <Package::208 PQFP>
-- 
--
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;

entity decoder is
port (
reset_n: in std_logic;
input: in std_logic;
clk: in std_logic;
output: out std_logic_vector (7 downto 0)
);
end decoder;

architecture archi of decoder is
begin

state_control: process (RESET_N, CLK)
begin 
    if (RESET_N =  '0') then
        output <= "00000000";
    elsif (rising_edge(clk)) then
        case input is
            when '0'  	=>  output <=  "00000001";
            when '1'  	=>  output <=  "00000010";
            when '2'  	=>  output <=  "00000100";
            when '3'  	=>  output <=  "00001000";
            when '4'  	=>  output <=  "00010000";
            when '5'  	=>  output <=  "00100000";
            when '6'  	=>  output <=  "01000000";
            when '7'  	=>  output <=  "10000000";
			when others => output <=  "00000000";
        end case;
    end if;
end process;

end archi;
