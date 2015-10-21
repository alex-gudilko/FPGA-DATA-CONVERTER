

--------------------------------------------------------------------------------
-- Company: <Mehatronika>
-- Author: <Aleksandr Gudilko>
-- Email: gudilkoalex@gmail.com
--
-- File: BCD_decoder_testbench.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- Testbench for 4/5 digits Integer-to-BCD decoder
--
-- Targeted device: <Family::ProASIC3> <Die::M1A3P400> <Package::208 PQFP>
-- 
--
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity BCD_decoder_testbench is
GENERIC(
    d_width   : INTEGER := 24 -- data width 
	      );
end BCD_decoder_testbench;

architecture behavioral of BCD_decoder_testbench is

    constant SYSCLK_PERIOD : time := 20 ns; -- 50MHZ
    constant SYSCLK_LF_PERIOD : time := 100 ns; -- 10MHZ
    constant SYSCLK_Khz_PERIOD : time := 0.256 us; -- 3900 Khz. REAL FREQ is 39 Khz (T=25.6 us)

    signal SYSCLK : std_logic := '0';
    signal SYSCLK_LF : std_logic := '0';
    signal SYSCLK_Khz : std_logic := '0';
    signal NSYSRESET : std_logic := '0';

    signal s_Latch_data_IN: std_logic;
    signal s_X_Pos_Int_in: std_logic_vector(d_width-1 downto 0);
    signal s_X_pos_Fract_in: std_logic_vector(d_width-1 downto 0);
    signal s_Y_Pos_Int_in: std_logic_vector(d_width-1 downto 0);
    signal s_Y_pos_Fract_in: std_logic_vector(d_width-1 downto 0);
    signal s_Z_Pos_Int_in: std_logic_vector(d_width-1 downto 0);
    signal s_Z_pos_Fract_in: std_logic_vector(d_width-1 downto 0);
    signal s_A4_Pos_Int_in: std_logic_vector(d_width-1 downto 0);
    signal s_A4_pos_Fract_in: std_logic_vector(d_width-1 downto 0);
    signal s_active_axis: std_logic_vector (3 downto 0);
 
    signal s_Position_to_decode: std_logic_vector(7 downto 0);
    signal s_Data_ready_out: std_logic;
    signal s_Position_Tx_gate: std_logic;
    signal s_Pos_Int_dig12_out: std_logic_vector(7 downto 0);
    signal s_Pos_Int_dig34_out: std_logic_vector(7 downto 0);
    signal s_Pos_Int_dig56_out: std_logic_vector(7 downto 0);
    signal s_Pos_Fract_dig12_out: std_logic_vector(7 downto 0);
    signal s_Pos_Fract_dig34_out: std_logic_vector(7 downto 0);




    component Position_INT_to_BCD_decoder
        -- ports
        port( 
            -- Inputs
            RESET_N : in std_logic;
            SCLK_IN : in std_logic;
            SCLK_LF_IN : in std_logic;
            SCLK_Hz_IN : in std_logic;
            Latch_data_IN : in std_logic;
            Data_ready_IN   :	in std_logic; 
            Pos_update_request    :	in std_logic; 
            Update_freq           :	in std_logic;  
            X_Pos_Int_in : in std_logic_vector(23 downto 0);
            X_pos_Fract_in : in std_logic_vector(23 downto 0);
            Y_Pos_Int_in : in std_logic_vector(23 downto 0);
            Y_pos_Fract_in : in std_logic_vector(23 downto 0);
            Z_Pos_Int_in : in std_logic_vector(23 downto 0);
            Z_pos_Fract_in : in std_logic_vector(23 downto 0);
            A4_Pos_Int_in : in std_logic_vector(23 downto 0);
            A4_pos_Fract_in : in std_logic_vector(23 downto 0);
            active_axis : in std_logic_vector(3 downto 0);

            -- Outputs
            Position_to_decode :  	out std_logic_vector(7 downto 0);
            Data_ready_out : out std_logic;
            Position_Tx_gate : out std_logic;
            Pos_Int_dig12_out : out std_logic_vector(7 downto 0);
            Pos_Int_dig34_out : out std_logic_vector(7 downto 0);
            Pos_Int_dig56_out : out std_logic_vector(7 downto 0);
            Pos_Fract_dig12_out : out std_logic_vector(7 downto 0);
            Pos_Fract_dig34_out : out std_logic_vector(7 downto 0)

            -- Inouts

        );
    end component;

begin

    process
        variable vhdl_initial : BOOLEAN := TRUE;

    begin
        if ( vhdl_initial ) then
            -- Assert Reset
            NSYSRESET <= '0';
            wait for ( SYSCLK_PERIOD * 10 );
            
            NSYSRESET <= '1';
            wait;
        end if;
    end process;

    -- Clock Driver
    SYSCLK <= not SYSCLK after (SYSCLK_PERIOD / 2.0 );
    SYSCLK_LF <= not SYSCLK_LF after (SYSCLK_LF_PERIOD / 2.0 );
    SYSCLK_Khz <= not SYSCLK_Khz after (SYSCLK_Khz_PERIOD / 2.0 );

    -- Instantiate Unit Under Test:  Position_INT_to_BCD_decoder
    Position_INT_to_BCD_decoder_0 : Position_INT_to_BCD_decoder
        -- port map
        port map( 
            -- Inputs
            RESET_N => NSYSRESET,
            SCLK_IN => SYSCLK,
            SCLK_LF_IN => SYSCLK_LF,
            SCLK_Hz_IN => SYSCLK_Khz,
            Latch_data_IN => s_Latch_data_IN,
            Data_ready_IN => '1',
            Pos_update_request => '0',
            Update_freq => '0',
            X_Pos_Int_in => s_X_Pos_Int_in,
            X_pos_Fract_in => s_X_pos_Fract_in,
            Y_Pos_Int_in => s_Y_Pos_Int_in,
            Y_pos_Fract_in => s_Y_pos_Fract_in,
            Z_Pos_Int_in => s_Z_Pos_Int_in,
            Z_pos_Fract_in => s_Z_pos_Fract_in,
            A4_Pos_Int_in => s_A4_Pos_Int_in,
            A4_pos_Fract_in => s_A4_pos_Fract_in,
            active_axis => s_active_axis,

            -- Outputs
            Position_to_decode => s_Position_to_decode,
            Data_ready_out =>  s_Data_ready_out,
            Position_Tx_gate =>  s_Position_Tx_gate,
            Pos_Int_dig12_out => s_Pos_Int_dig12_out,
            Pos_Int_dig34_out => s_Pos_Int_dig34_out,
            Pos_Int_dig56_out => s_Pos_Int_dig56_out,
            Pos_Fract_dig12_out => s_Pos_Fract_dig12_out,
            Pos_Fract_dig34_out => s_Pos_Fract_dig34_out

            -- Inouts

        );

process
begin
    
-----------------
--Initialization
--Reset for 10 clk cycles
-----------------
s_X_Pos_Int_in     <=  (others => '0');
s_X_pos_Fract_in   <=  (others => '0');
s_Y_Pos_Int_in     <=  (others => '0');
s_Y_pos_Fract_in   <=  (others => '0');
s_Z_Pos_Int_in     <=  (others => '0');
s_Z_pos_Fract_in   <=  (others => '0');
s_A4_Pos_Int_in    <=  (others => '0');
s_A4_pos_Fract_in  <=  (others => '0');
s_Latch_data_IN    <= '0';
s_active_axis      <= (others => '0');

-----------------
--set IN data
-----------------
wait for ( SYSCLK_PERIOD * 30 );
s_X_Pos_Int_in     <=  x"1A1B4A";
s_X_pos_Fract_in   <=  x"1D1E1F";
s_Y_Pos_Int_in     <=  x"2A2B5D";
s_Y_pos_Fract_in   <=  x"2D2E25";
s_Z_Pos_Int_in     <=  x"3A3B7F";
s_Z_pos_Fract_in   <=  x"3D3E3F";
s_A4_Pos_Int_in    <=  x"4A4B91";
s_A4_pos_Fract_in  <=  x"4D4E4F";

-----------------
--Emulate LATCH DATA IN signal
-----------------
wait for ( SYSCLK_LF_PERIOD * 5 );
s_active_axis   <= "1000";  --X
wait for ( SYSCLK_LF_PERIOD * 2 );
s_Latch_data_IN    <= '1';
wait for ( SYSCLK_LF_PERIOD * 2 );
s_Latch_data_IN    <= '0';

wait for ( SYSCLK_LF_PERIOD * 3 );
s_active_axis   <= "0100";  --Y
wait for ( SYSCLK_LF_PERIOD * 2 );
s_Latch_data_IN    <= '1';
wait for ( SYSCLK_LF_PERIOD * 2 );
s_Latch_data_IN    <= '0';

wait for ( SYSCLK_LF_PERIOD * 3 );
s_active_axis   <= "0010";  --Z
wait for ( SYSCLK_LF_PERIOD * 2 );
s_Latch_data_IN    <= '1';
wait for ( SYSCLK_LF_PERIOD * 2 );
s_Latch_data_IN    <= '0';

wait for ( SYSCLK_LF_PERIOD * 3 );
s_active_axis   <= "0001";  --A4
wait for ( SYSCLK_LF_PERIOD * 2 );
s_Latch_data_IN    <= '1';
wait for ( SYSCLK_LF_PERIOD * 2 );
s_Latch_data_IN    <= '0';

wait for ( SYSCLK_LF_PERIOD * 3 );
s_active_axis   <= "0000";  --false
wait for ( SYSCLK_LF_PERIOD * 2 );
s_Latch_data_IN    <= '1';
wait for ( SYSCLK_LF_PERIOD * 2 );
s_Latch_data_IN    <= '0';

wait for ( SYSCLK_LF_PERIOD * 3 );
s_active_axis   <= "0101";  --false
wait for ( SYSCLK_LF_PERIOD * 2 );
s_Latch_data_IN    <= '1';
wait for ( SYSCLK_LF_PERIOD * 2 );
s_Latch_data_IN    <= '0';

wait for ( SYSCLK_LF_PERIOD * 40 );

end process;

end behavioral;

