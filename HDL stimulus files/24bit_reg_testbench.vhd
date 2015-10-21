--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: 24bit_reg_testbench.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- <Description here>
--
-- Targeted device: <Family::ProASIC3> <Die::M1A3P400> <Package::208 PQFP>
-- Author: <Name>
--
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;

entity bit24_reg_testbench is
end bit24_reg_testbench;
architecture a_24bit_reg_testbench of bit24_reg_testbench is

   -- signal, component etc. declarations
    constant SYSCLK_PERIOD : time := 20 ns; -- 50MHZ

    signal SYSCLK : std_logic := '0';
    signal NSYSRESET : std_logic := '0';  
    signal Data_value : std_logic_vector(23 downto 0) := (others => '0');  

    component Reg_24B_NRes_Pload
        -- ports
    port( Data   : in    std_logic_vector(23 downto 0);
          Enable : in    std_logic;
          Aclr   : in    std_logic;
          Clock  : in    std_logic;
          Q      : out   std_logic_vector(23 downto 0) 
        );
    end component;

begin

--Data_value <= 0x"000000", 0x"AABBCC" after SYSCLK_PERIOD * 10, 0x"CCBBAA" after SYSCLK_PERIOD * 20;
Data_value <= "000000000000000000000000", "111111000000111111000000" after SYSCLK_PERIOD * 10, "000000111111000000111111" after SYSCLK_PERIOD * 20;
    process
        variable vhdl_initial : BOOLEAN := TRUE;

    begin
        if ( vhdl_initial ) then
            -- Assert Reset
            NSYSRESET <= '0';
            wait for ( SYSCLK_PERIOD * 5 );
            
            NSYSRESET <= '1';
            wait;
        end if;
    end process;

    -- Clock Driver
    SYSCLK <= not SYSCLK after (SYSCLK_PERIOD / 2.0 );

    -- Instantiate Unit Under Test:  MAIN_CANVAS
    Reg_24B_NRes_Pload_0 : Reg_24B_NRes_Pload
        -- port map
        port map( 
            -- Inputs
            Clock => SYSCLK,
            Enable => '1',
            Aclr => NSYSRESET,
            Data => Data_value,

            -- Outputs
            Q =>  open


        );

   -- architecture body
end a_24bit_reg_testbench;
