------------------------------------------------------------------------
-- Author: 	Aleksandr Gudilko
-- Email: 	gudilkoalex@gmail.com
--
-- File:Input_filter_4channel.vhd
--
-- Description:
--
-- General-purpose input filter for FPGA signals (Majority filter)
-- Eliminates line "ringing" and create stable output for high speed logic.
------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity input_filter_4ch is
	port(
        reset                 :in std_logic; -- unfiltered input signal
        INPUT_CLK             :in std_logic; -- input clock signal

        INPUT_SIGNAL_1        :in std_logic; -- unfiltered input signal
        INPUT_SIGNAL_2        :in std_logic; -- unfiltered input signal
        INPUT_SIGNAL_3        :in std_logic; -- unfiltered input signal
        INPUT_SIGNAL_4        :in std_logic; -- unfiltered input signal


		FILTERED_SIGNAL_1     :out std_logic; -- output filtered signal
		FILTERED_SIGNAL_2     :out std_logic; -- output filtered signal
		FILTERED_SIGNAL_3     :out std_logic; -- output filtered signal
		FILTERED_SIGNAL_4     :out std_logic -- output filtered signal

	);

end input_filter_4ch;

architecture arch of input_filter_4ch is
    signal in1       :std_logic_vector (2 downto 0);
    signal in2       :std_logic_vector (2 downto 0);
    signal in3       :std_logic_vector (2 downto 0);
    signal in4       :std_logic_vector (2 downto 0);

begin

FILTERED_SIGNAL_1 <= (in1(0) and in1(1)) or (in1(1) and in1(2)) or (in1(2) and in1(0));
FILTERED_SIGNAL_2 <= (in2(0) and in2(1)) or (in2(1) and in2(2)) or (in2(2) and in2(0));
FILTERED_SIGNAL_3 <= (in3(0) and in3(1)) or (in3(1) and in3(2)) or (in3(2) and in3(0));
FILTERED_SIGNAL_4 <= (in4(0) and in4(1)) or (in4(1) and in4(2)) or (in4(2) and in4(0));

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

    proc2:
    process(INPUT_CLK, reset)
    	begin
            if reset = '0' then
               in2 <= "000";
            elsif rising_edge(input_clk) then
               in2(2) <= in2(1);
               in2(1) <= in2(0);
               in2(0) <= input_signal_2;
            end if;
	end process proc2;

    proc3:
    process(INPUT_CLK, reset)
    	begin
            if reset = '0' then
               in3 <= "000";
            elsif rising_edge(input_clk) then
               in3(2) <= in3(1);
               in3(1) <= in3(0);
               in3(0) <= input_signal_3;
            end if;
	end process proc3;

    proc4:
    process(INPUT_CLK, reset)
    	begin
            if reset = '0' then
               in4 <= "000";
            elsif rising_edge(input_clk) then
               in4(2) <= in4(1);
               in4(1) <= in4(0);
               in4(0) <= input_signal_4;
            end if;
	end process proc4;
end arch;