
--------------------------------------------------------------------------------
-- Company: <Mehatronika>
-- Author: <Aleksandr Gudilko>
-- Email:  gudilkoalex@gmail.com
--
-- File: Pendant_decoder_testbench.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- Testbench for UART pendant decoder
--
-- Targeted device: <Family::ProASIC3> <Die::M1A3P400> <Package::208 PQFP>
--
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Pendant_decoder_testbench is
end Pendant_decoder_testbench;

architecture behavioral of Pendant_decoder_testbench is

    constant SYSCLK_PERIOD : time := 20 ns; -- 50MHZ
    constant SYSCLK_LF_PERIOD : time := 100 ns; -- 10MHZ
    constant SYSCLK_Khz_PERIOD : time := 0.256 us; -- 3900 Khz. REAL FREQ is 39 Khz (T=25.6 us)

    signal SYSCLK : std_logic := '0';
    signal SYSCLK_LF : std_logic := '0';
    signal SYSCLK_Khz : std_logic := '0';
    signal NSYSRESET : std_logic := '0';
    signal s_UART_DATA1_IN : std_logic_vector (7 downto 0);
    signal s_UART_DATA2_IN : std_logic_vector (7 downto 0);
    signal s_UART_DATA_OUT : std_logic_vector (7 downto 0);
    signal s_UART_Tx_Gate : std_logic;
    signal s_UART_Write_mode : std_logic;
    signal s_UART_DATA_OUT2 : std_logic_vector (7 downto 0);
    signal s_UART_Tx_Gate2 : std_logic;
    signal s_ACLR_UART_Rx_Out_N : std_logic;


    signal s_Disp_axis_reg : std_logic_vector (23 downto 0);
    signal s_Current_axis_reg : std_logic_vector (23 downto 0);

    signal s_MODE_out : std_logic_vector (2 downto 0);
    signal s_Mode_Ready_out : std_logic;

    signal s_AXIS_out : std_logic_vector (3 downto 0);
    signal s_Axis_Ready_out : std_logic;

    signal s_LED_reg : std_logic_vector (23 downto 0);
    signal s_Button_reg : std_logic_vector (23 downto 0);
    signal s_Speed_reg : std_logic_vector (23 downto 0);


    component PENDANT_DECODER
        -- ports
        port( 
            -- Inputs
            RESET_N : in std_logic;
            SCLK_IN : in std_logic;
            SCLK_Khz_IN      :	in std_logic; -- External SCLK xx Khz
            SCLK_LF_IN      :	in std_logic; -- External SCLK 10 Mhz
            UART_DATA1_IN : in std_logic_vector(7 downto 0);
            UART_DATA2_IN : in std_logic_vector(7 downto 0);
            Disp_axis_reg   :	in std_logic_vector(23 downto 0); -- Data FROM PMAC (confirmation of axis and mode selection)
            LED_reg         :	in std_logic_vector(23 downto 0); -- Data FROM PMAC (indicators on programmable LEDs)
            sw1 : in std_logic;
            sw2 : in std_logic;

            -- Outputs
            Current_axis_reg   :	out std_logic_vector(23 downto 0); -- Data TO PMAC
            Speed_reg   :	out std_logic_vector(23 downto 0); -- Data TO PMAC
            Button_reg   :	out std_logic_vector(23 downto 0); -- Data TO PMAC
            UART_DATA_OUT : out std_logic_vector(7 downto 0);
            UART_Tx_Gate    :	out std_logic;                     -- latch UART data in external Tx registers
            UART_Write_mode :	out std_logic;
            UART_DATA_OUT2   :	out std_logic_vector(7 downto 0); -- Data TO pendant (LED control)
            UART_Tx_Gate2    :	out std_logic;                     -- latch UART data in external Tx registers (LED control)
            MODE_out : out std_logic_vector(2 downto 0);
            Mode_Ready_out : out std_logic;
            AXIS_out : out std_logic_vector(3 downto 0);
            Axis_Ready_out : out std_logic;
            ACLR_UART_Rx_Out_N :	out std_logic;                     -- clear UART Rx reg (active low)
            flag1 : out std_logic

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

    -- Instantiate Unit Under Test:  PENDANT_DECODER
    PENDANT_DECODER_0 : PENDANT_DECODER
        -- port map
        port map( 
            -- Inputs
            RESET_N => NSYSRESET,
            SCLK_IN => SYSCLK,
            SCLK_LF_IN => SYSCLK_LF,
            SCLK_Khz_IN => SYSCLK_Khz,
            UART_DATA1_IN => s_UART_DATA1_IN,
            UART_DATA2_IN => s_UART_DATA2_IN,
            Disp_axis_reg => s_Disp_axis_reg,
            LED_reg => s_LED_reg,
            sw1 => '0',
            sw2 => '0',

            -- Outputs
            Current_axis_reg => s_Current_axis_reg,
            Speed_reg => s_Speed_reg,
            Button_reg => s_Button_reg,

            UART_DATA_OUT => s_UART_DATA_OUT,
            UART_Tx_Gate =>   s_UART_Tx_Gate,
            UART_Write_mode => s_UART_Write_mode,
            UART_DATA_OUT2 => s_UART_DATA_OUT2,
            UART_Tx_Gate2 =>   s_UART_Tx_Gate2,
            MODE_out => s_MODE_out,
            Mode_Ready_out =>  s_Mode_Ready_out,
            AXIS_out => s_Axis_out,
            Axis_Ready_out =>  s_Axis_Ready_out,
            ACLR_UART_Rx_Out_N => s_ACLR_UART_Rx_Out_N,
            flag1 =>  open

            -- Inouts

        );

process
begin
    
-----------------
--Initialization
--Reset for 10 clk cycles
-----------------
s_UART_DATA1_IN  <=  (others => '0');
s_UART_DATA2_IN  <=  (others => '0');
s_Disp_axis_reg  <= (others => '0');
s_LED_reg        <= (others => '0');

--AXIS CHANGE
--------------------------------------
--send axis X code
wait for ( SYSCLK_PERIOD * 20 );
s_UART_DATA1_IN  <=  x"55"; -- axis X (1st part)
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"16"; -- axis Y (2nd part) - wrong!
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"15"; -- axis X
-- emulate axis confirmation
wait for ( SYSCLK_PERIOD * 8 );
s_Disp_axis_reg   <= x"400000"; -- Y confirmation, FALSE
wait for ( SYSCLK_PERIOD * 3 );
s_Disp_axis_reg   <= x"880000"; -- false confirmation, FALSE
wait for ( SYSCLK_PERIOD * 3 );
s_Disp_axis_reg   <= x"800000"; -- X confirmation, TRUE

--------------------------------------
--send axis Y code
wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"56"; -- axis Y
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"16"; -- axis Y
-- emulate axis confirmation
wait for ( SYSCLK_PERIOD * 8 );
s_Disp_axis_reg   <= x"400000"; -- Y confirmation, TRUE
-------------------------------------
--send axis X code
wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"55"; -- axis X
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"15"; -- axis X
-- emulate axis confirmation
wait for ( SYSCLK_PERIOD * 8 );
s_Disp_axis_reg   <= x"800000"; -- X confirmation, TRUE
-------------------------------------
--send axis Y code
wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"56"; -- axis Y
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"16"; -- axis Y
-- emulate axis confirmation
wait for ( SYSCLK_PERIOD * 8 );
s_Disp_axis_reg   <= x"400000"; -- Y confirmation, TRUE
-------------------------------------
--send axis Z code
wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"57"; -- axis Z
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"17"; -- axis Z
--emulate Axis change before confirmation
wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"55"; -- axis X
wait for ( SYSCLK_PERIOD * 2 );
s_UART_DATA2_IN  <=  x"15"; -- axis X
-- emulate axis confirmation
wait for ( SYSCLK_PERIOD * 8 );
s_Disp_axis_reg   <= x"200000"; -- Z confirmation, TRUE
-------------------------------------
--send axis A4 code
wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"58"; -- axis 4
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"18"; -- axis 4

--emulate Axis change before confirmation
wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"55"; -- axis X
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"15"; -- axis X

-- emulate axis confirmation
wait for ( SYSCLK_PERIOD * 8 );
s_Disp_axis_reg   <= x"800000"; -- X confirmation, FALSE
wait for ( SYSCLK_PERIOD * 4 );
s_Disp_axis_reg   <= x"100000"; -- A4 confirmation, TRUE
-------------------------------------

--MODE CHANGE
--------------------------------------
--send mode MANU code
wait for ( SYSCLK_PERIOD * 15 );
s_UART_DATA1_IN  <=  x"52"; -- MANU
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"12"; -- MANU
-- emulate mode confirmation
wait for ( SYSCLK_PERIOD * 8 );
s_Disp_axis_reg   <= x"000002"; -- INC confirmation, FALSE
wait for ( SYSCLK_PERIOD * 4 );
s_Disp_axis_reg   <= x"000001"; -- MANU confirmation, TRUE
--------------------------------------
--send mode INC code
wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"53"; -- INC
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"13"; -- INC

--emulate Axis change before confirmation
wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"55"; -- axis X
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"15"; -- axis X

-- emulate mode confirmation
wait for ( SYSCLK_PERIOD * 8 );
s_Disp_axis_reg   <= x"000002"; -- INC confirmation, TRUE

--send mode HPG code
wait for ( SYSCLK_PERIOD * 7 );
s_UART_DATA1_IN  <=  x"54"; -- HPG
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"14"; -- HPG
-- emulate mode confirmation
wait for ( SYSCLK_PERIOD * 8 );
s_Disp_axis_reg   <= x"000004"; -- HPG confirmation, TRUE

--send mode MANU code
wait for ( SYSCLK_PERIOD * 7 );
s_UART_DATA1_IN  <=  x"52"; -- MANU
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"12"; -- MANU
-- emulate mode confirmation
wait for ( SYSCLK_PERIOD * 8 );
s_Disp_axis_reg   <= x"000001"; -- MANU confirmation, TRUE

--send mode INC code
wait for ( SYSCLK_PERIOD * 7 );
s_UART_DATA1_IN  <=  x"53"; -- INC
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"13"; -- INC
-- emulate mode confirmation
wait for ( SYSCLK_PERIOD * 8 );
s_Disp_axis_reg   <= x"000002"; -- INC confirmation, TRUE

--------------------------------------

wait for ( SYSCLK_PERIOD * 30 );

-------------------------------------

--BUTTONS press
--------------------------------------
--press F1
wait for ( SYSCLK_PERIOD * 50 );
s_UART_DATA1_IN  <=  x"41"; -- F1 press
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"01"; -- F1 release (will not be processed)
wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"01"; -- F1 release
-- emulate LED control
wait for ( SYSCLK_PERIOD * 8 );
s_LED_reg   <= x"000001"; -- LED1 ON


--press F2
wait for ( SYSCLK_PERIOD * 110 );
s_UART_DATA1_IN  <=  x"42"; -- F2 press
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"02"; -- F2 release (will not be processed)
wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"02"; -- F2 release
-- emulate LED control
wait for ( SYSCLK_PERIOD * 8 );
s_LED_reg   <= x"000003"; -- LED1 and LED2 ON


--press F3
wait for ( SYSCLK_PERIOD * 110 );
s_UART_DATA1_IN  <=  x"43"; -- F3 press
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"03"; -- F3 release (will not be processed)
wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"03"; -- F3 release
-- emulate LED control
wait for ( SYSCLK_PERIOD * 8 );
s_LED_reg   <= x"000004"; -- LED3 ON

wait for ( SYSCLK_PERIOD * 110 );
s_LED_reg   <= x"000000"; -- LED1-3 OFF

----------------------
-- TEST J+ and J-
----------------------
wait for ( SYSCLK_PERIOD * 110 );
s_UART_DATA1_IN  <=  x"5D"; -- J+ pressed (1st)
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"1D"; -- J+ released
wait for ( SYSCLK_PERIOD * 1 );
s_UART_DATA1_IN  <=  x"00"; -- UART1 reg cleared
s_UART_DATA2_IN  <=  x"00"; -- UART2 reg cleared

wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"5D"; -- J+ pressed (2nd)
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"1D"; -- J+ released
wait for ( SYSCLK_PERIOD * 1 );
s_UART_DATA1_IN  <=  x"00"; -- UART1 reg cleared
--s_UART_DATA2_IN  <=  x"00"; -- UART2 reg cleared

wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"5D"; -- J+ pressed (3rd)
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"1D"; -- J+ released
wait for ( SYSCLK_PERIOD * 1 );
s_UART_DATA1_IN  <=  x"00"; -- UART1 reg cleared
s_UART_DATA2_IN  <=  x"00"; -- UART2 reg cleared

wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"5D"; -- J+ pressed (4th)
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"1D"; -- J+ released
wait for ( SYSCLK_PERIOD * 1 );
s_UART_DATA1_IN  <=  x"00"; -- UART1 reg cleared
s_UART_DATA2_IN  <=  x"00"; -- UART2 reg cleared

wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"5D"; -- J+ pressed (5th)
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"1D"; -- J+ released
wait for ( SYSCLK_PERIOD * 1 );
s_UART_DATA1_IN  <=  x"00"; -- UART1 reg cleared
s_UART_DATA2_IN  <=  x"00"; -- UART2 reg cleared

wait for ( SYSCLK_PERIOD * 10 );
s_UART_DATA1_IN  <=  x"5C"; -- J- pressed (1st)
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"1C"; -- J- released
wait for ( SYSCLK_PERIOD * 1 );
s_UART_DATA1_IN  <=  x"00"; -- UART1 reg cleared
s_UART_DATA2_IN  <=  x"00"; -- UART2 reg cleared

wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"5C"; -- J- pressed (2nd)
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"1C"; -- J- released
wait for ( SYSCLK_PERIOD * 1 );
s_UART_DATA1_IN  <=  x"00"; -- UART1 reg cleared
s_UART_DATA2_IN  <=  x"00"; -- UART2 reg cleared

wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"5C"; -- J- pressed (3rd)
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"1C"; -- J- released
wait for ( SYSCLK_PERIOD * 1 );
s_UART_DATA1_IN  <=  x"00"; -- UART1 reg cleared
s_UART_DATA2_IN  <=  x"00"; -- UART2 reg cleared

wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"5C"; -- J- pressed (4th)
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"1C"; -- J- released
wait for ( SYSCLK_PERIOD * 1 );
s_UART_DATA1_IN  <=  x"00"; -- UART1 reg cleared
s_UART_DATA2_IN  <=  x"00"; -- UART2 reg cleared

wait for ( SYSCLK_PERIOD * 5 );
s_UART_DATA1_IN  <=  x"5C"; -- J- pressed (5th)
wait for ( SYSCLK_PERIOD * 3 );
s_UART_DATA2_IN  <=  x"1C"; -- J- released
wait for ( SYSCLK_PERIOD * 1 );
s_UART_DATA1_IN  <=  x"00"; -- UART1 reg cleared
s_UART_DATA2_IN  <=  x"00"; -- UART2 reg cleared

wait for ( SYSCLK_PERIOD * 800 );

end process;

end behavioral;

