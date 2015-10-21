------------------------------------------------------------------------
-- Author: <Aleksandr Gudilko>
-- Email: gudilkoalex@gmail.com
-- Input_filter_1channel.vhd
--
-- Description:
-- General-purpose input filter for FPGA signals (Majority filter)
-- Eliminates line "ringing" and create stable output for high speed logic.
------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity input_filter_1ch is
	port(
        reset                 :in std_logic; -- unfiltered input signal
        INPUT_CLK             :in std_logic; -- input clock signal
        INPUT_SIGNAL_1        :in std_logic; -- unfiltered input signal
		FILTERED_SIGNAL_1     :out std_logic -- output filtered signal
	);

end input_filter_1ch;

architecture arch of input_filter_1ch is
    signal in1       :std_logic_vector (2 downto 0);


begin

FILTERED_SIGNAL_1 <= (in1(0) and in1(1)) or (in1(1) and in1(2)) or (in1(2) and in1(0));

    proc1:
    process(INPUT_CLK, reset)
    	begin
            if reset = '0' then
               in1 <= "000";
            elsif rising_edge(input_clk) then
               in1(2) <= in1(1);
               in1(1) <= in1(0);
               in1(0) <= input_signal_1;
            end if;
	end process proc1;
end arch;