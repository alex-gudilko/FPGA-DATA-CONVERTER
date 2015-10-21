--------------------------------------------------------------------------------
-- Company: <Mehatronika>
-- Author: <Aleksandr Gudilko>
-- Email: gudilkoalex@gmail.com
--
-- File: PENDANT_DECODER.vhd
-- File history:
--      <1.0>: <24/03/2015>: <Only Mode and Axis>
--      <2.0>: <25/03/2015>: <Buttons F1-F3, +,- , ampersand>
--      <3.0>: <03/04/2015>: <Improvements and corrections made. Release version>
--
-- Description: 
--
-- <Module decodes pendant signals and set flags to PMAC>
--
-- Targeted device: <Family::ProASIC3> <Die::M1A3P400> <Package::208 PQFP>
--
--
--------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity PENDANT_DECODER is

GENERIC(
    COUNTER_WIDTH   : INTEGER := 11 -- UART write mode duration 
	      );
-- 01bit counter -> 51  us  period clock 19,5 kHz
-- 02bit counter -> 102 us  period clock 9,75  kHz
-- 03bit counter -> 204 us  period clock 4,8  kHz
-- 04bit counter -> 409 us  period clock 2,4 kHz
-- 05bit counter -> 820 us  period clock 1,2  kHz
-- 06bit counter -> 1.6 ms  period clock 610  Hz
-- 07bit counter -> 3.2 ms  period clock 305  Hz
-- 08bit counter -> 6.5 ms  period clock 152  Hz
-- 09bit counter -> 13  ms  period clock 76   Hz
-- 10bit counter -> 26  ms  period clock 38   Hz
-- 11bit counter -> 52  ms  period clock 19   Hz
-- 12bit counter -> 104 ms  period clock 9,5  Hz
-- 13bit counter -> 209 ms  period clock 4,75 Hz
-- 14bit counter -> 419 ms  period clock 2,35 Hz
-- 15bit counter -> 838 ms  period clock 1,2  Hz


port (
		RESET_N         :	in std_logic; -- RESET. Active low. 
		SCLK_IN         :	in std_logic; -- External SCLK 50 Mhz
		SCLK_LF_IN      :	in std_logic; -- External SCLK 10 Mhz
		SCLK_Khz_IN      :	in std_logic; -- External SCLK xx Khz

        UART_DATA1_IN    :	in std_logic_vector(7 downto 0); -- Data FROM pendant
        UART_DATA2_IN    :	in std_logic_vector(7 downto 0); -- Data FROM pendant

        Disp_axis_reg   :	in std_logic_vector(23 downto 0); -- Data FROM PMAC (confirmation of axis and mode selection)
        LED_reg         :	in std_logic_vector(23 downto 0); -- Data FROM PMAC (indicators on programmable LEDs)

		sw1 	        :	in std_logic;     --switch 1
		sw2 	        :	in std_logic;     --switch 2

        Current_axis_reg   :	out std_logic_vector(23 downto 0); -- Data TO PMAC
        Speed_reg   :	out std_logic_vector(23 downto 0); -- Data TO PMAC
        Button_reg   :	out std_logic_vector(23 downto 0); -- Data TO PMAC

        UART_DATA_OUT   :	out std_logic_vector(7 downto 0); -- Data TO pendant (Axis and mode)
        UART_Tx_Gate    :	out std_logic;                     -- latch UART data in external Tx registers (buttons confirmation)
        UART_Write_mode :	out std_logic;                     -- enter UART transmit mode

        UART_DATA_OUT2   :	out std_logic_vector(23 downto 0); -- Data TO pendant (LED control, 3x 8 bit)
        UART_Tx_Gate2    :	out std_logic;                     -- latch UART data in external Tx registers (LED control)

        UART_DATA_OUT3   :	out std_logic_vector(7 downto 0); -- Data TO pendant (Speed register)
        UART_Tx_Gate3    :	out std_logic;                     -- latch UART data in external Tx registers (Speed register)

        MODE_out 	     :	out std_logic_vector (2 downto 0); -- Selected MODE (simulation of handwheel)
        Mode_Ready_out   :	out std_logic;                     -- mode may be switched
        AXIS_out 	     :	out std_logic_vector (3 downto 0); -- Selected AXIS (simulation of handwheel)
        Axis_Ready_out   :	out std_logic;                     -- axis may be switched

        ACLR_UART_Rx_Out_N :	out std_logic;                     -- clear UART Rx reg (active low)
		
        flag1 	:	out std_logic --temp out 1


);
end PENDANT_DECODER;

architecture behavioral of PENDANT_DECODER is
   -- signal, component etc. declarations
type axis_values is (X,Y,Z,A4);
type mode_values is (MANU, INC, HPG);
type discret_values is (JOG_MINUS,JOG_PLUS);

signal current_axis : axis_values;
signal next_axis : axis_values;

signal current_mode : mode_values;
signal next_mode : mode_values;

signal Mode_feedback   : std_logic_vector (2 downto 0);  -- active mode in CNC
signal Axis_feedback   : std_logic_vector (3 downto 0);  -- active axis in CNC
signal Led_feedback   : std_logic_vector (2 downto 0);  -- status of LEDs on F1-F3 buttons
signal Previous_Led   : std_logic_vector (2 downto 0);  -- previous status of LEDs on F1-F3 buttons

signal Axis_reg_block_pmac : std_logic;
signal Axis_reg_block_uart : std_logic;
signal Mode_reg_block_pmac : std_logic;
signal Mode_reg_block_uart : std_logic;
signal speed_reg_block : std_logic;
signal reset_speed_reg_flag : std_logic;
signal reset_speed_reg_R : std_logic;


signal mode_out_b : std_logic_vector(2 downto 0) ; -- internal register (updated after button is released)
signal axis_out_b : std_logic_vector(3 downto 0) ; -- internal register (updated after button is released)

signal mode_out_r : std_logic_vector(2 downto 0) ; -- buffered output (updated only after PMAC confirmation)
signal axis_out_r : std_logic_vector(3 downto 0) ; -- buffered output (updated only after PMAC confirmation)
signal buttons_out_r : std_logic_vector(5 downto 0) ;
signal speed_out_r : std_logic_vector(3 downto 0) ;

signal Current_axis_reg_R : std_logic_vector(23 downto 0) ;
signal Speed_reg_R : std_logic_vector(23 downto 0) ;
signal Button_reg_R : std_logic_vector(23 downto 0) ;

signal UART_DATA_OUT_R : std_logic_vector(7 downto 0) ;
signal UART_DATA_OUT_LED_R : std_logic_vector(23 downto 0) ;
signal UART_DATA_OUT_SPEED_R : std_logic_vector(7 downto 0) ;

signal UART_DATA_AXIS : std_logic_vector(7 downto 0) ;
signal UART_Tx_Gate_R1 : std_logic;
signal UART_Tx_Gate_flag1 : std_logic;
signal UART_Tx_Start_R1 : std_logic;
signal Axis_Ready_out_R : std_logic;

signal UART_DATA_MODE : std_logic_vector(7 downto 0) ;
signal UART_Tx_Gate_R2 : std_logic;
signal UART_Tx_Gate_flag2 : std_logic;
signal UART_Tx_Start_R2 : std_logic;


signal UART_DATA_LED : std_logic_vector(23 downto 0) ;
signal UART_Tx_Gate_R3 : std_logic;
signal UART_Tx_Gate_flag3 : std_logic;

signal UART_DATA_SPEED : std_logic_vector(7 downto 0) ;
signal UART_Tx_Gate_R4 : std_logic;
signal UART_Tx_Gate_flag4 : std_logic;

signal UART_Tx_flags : std_logic;
signal UART_Tx_Gate_R : std_logic;

signal counter : std_logic_vector (COUNTER_WIDTH-1 downto 0);
signal UART_Write_mode_R : std_logic;
signal stop_counter : std_logic;
signal start_counter : std_logic;
signal Reset_Write_mode : std_logic;


  component impulse_gen_N_2cycle
port (
        RESET_N          :in std_logic; -- reset
        IN_SIGNAL        :in std_logic; -- input signal
        IN_CLK           :in std_logic; -- input clock signal

		OUT_SIGNAL_P       :out std_logic; -- output impluse Active High
		OUT_SIGNAL_N       :out std_logic -- output impluse Active Low
);
  end component;

component Latch_trigger is
    port( Data   : in    std_logic;
          Enable : in    std_logic;
          Aclr   : in    std_logic;
          Aset   : in    std_logic;
          Clock  : in    std_logic;
          Q      : out   std_logic
        );
  end component;


begin
-- writing outputs from buffers
    MODE_out            <=  mode_out_r;
    Axis_out            <=  axis_out_r;
    Current_axis_reg    <=  Current_axis_reg_R;
    Speed_reg           <=  Speed_reg_R;
    Button_reg          <=  Button_reg_R;
    UART_DATA_OUT       <=  UART_DATA_OUT_R;        -- load buttons confirmation to UART
    UART_Tx_Gate        <=  UART_Tx_Gate_R;
    UART_DATA_OUT2      <=  UART_DATA_OUT_LED_R;    -- load LED control commands to UART
    UART_Tx_Gate2       <=  UART_Tx_Gate_R3;        -- latch LED control commands to UART
    UART_DATA_OUT3      <=  UART_DATA_OUT_SPEED_R;  -- load speed commands to UART
    UART_Tx_Gate3       <=  UART_Tx_Gate_R4;        -- latch speed commands to UART

    UART_Write_mode     <=  UART_Write_mode_R;      -- enter UART transmit mode after new Tx data was latched

    Axis_Ready_out  <= Axis_Ready_out_R;      
    Mode_Ready_out  <= not(Mode_reg_block_pmac);

    ACLR_UART_Rx_Out_N  <= '1'; -- ACLR not active

    flag1   <= '0';

-- wiring inputs
    Mode_feedback   <= Disp_axis_reg (2 downto 0); -- extract Active mode code from CNC feedback
    Axis_feedback   <= Disp_axis_reg (23 downto 20); -- extract Active axis code from CNC feedback
    Led_feedback    <= LED_reg (2 downto 0);        -- extract LED1 - LED3 status from CNC feedback

-- wiring registers and internal signals
    Current_axis_reg_R(23 downto 20)  <=  axis_out_b;   -- write selected axis code to Current_Axis_reg (bits 23-20)
    Current_axis_reg_R(19 downto 17)   <= "000";       -- reserved for more axes (7 axis max)
    Current_axis_reg_R(16 downto 13)   <= Axis_feedback;   -- show active axis selected on CNC
    Current_axis_reg_R(12)   <= not(Axis_reg_block_pmac);   -- 1 when ready to select new axis
    Current_axis_reg_R(11)   <= not(Mode_reg_block_pmac);   -- 1 when ready to select new mode
    Current_axis_reg_R(10 downto 8)   <= Mode_feedback;   -- show active mode selected on CNC    
--    Current_axis_reg_R(7 downto 3)   <= "00000";        -- reserved for more modes
    Current_axis_reg_R(7)   <= UART_Tx_Gate_flag2;   -- 
    Current_axis_reg_R(6 downto 3)   <= "0000";        -- reserved for more modes
    Current_axis_reg_R(2 downto 0)    <=  mode_out_b;   -- write selected mode code to Current_Axis_reg (bits 2-0)
    
    Speed_reg_R (3 downto 0) <=  speed_out_r;
    Speed_reg_R (23 downto 4) <= (OTHERS => '0');    

    Button_reg_R(23 downto 6)  <=  (OTHERS => '0');  
    Button_reg_R(5 downto 0)   <=  Buttons_out_r; -- show status of all buttons real-time 

    UART_Tx_Gate_R      <=  UART_Tx_Gate_R1 or UART_Tx_Gate_R2; -- latch AXIS(1), MODE(2) codes to UART in position #1
    UART_Tx_flags       <=  UART_Tx_Start_R1 or UART_Tx_Start_R2 or UART_Tx_Gate_flag4 or UART_Tx_Gate_flag3; -- New data is available (2 SCLK_Khz width = 50us)

    Reset_Write_mode <= RESET_N and not(stop_counter);

\UART_Tx_Gate_impulse_gen1\ : impulse_gen_N_2cycle -- generate signal to latch data in UART Tx registers (2 clk width) (from AXIS process)
    port map(IN_SIGNAL => UART_Tx_Gate_flag1, IN_CLK => SCLK_LF_IN, RESET_N => RESET_N , OUT_SIGNAL_N => open, OUT_SIGNAL_P => UART_Tx_Gate_R1);

\UART_Tx_Gate_impulse_gen2\ : impulse_gen_N_2cycle -- generate signal to latch data in UART Tx registers (2 clk width) (from MODE process)
    port map(IN_SIGNAL => UART_Tx_Gate_flag2, IN_CLK => SCLK_LF_IN, RESET_N => RESET_N , OUT_SIGNAL_N => open, OUT_SIGNAL_P => UART_Tx_Gate_R2);

\UART_Tx_Gate_impulse_gen3\ : impulse_gen_N_2cycle -- generate signal to latch data in UART Tx registers (2 clk width) (from LED process)
    port map(IN_SIGNAL => UART_Tx_Gate_flag3, IN_CLK => SCLK_LF_IN, RESET_N => RESET_N , OUT_SIGNAL_N => open, OUT_SIGNAL_P => UART_Tx_Gate_R3);

\UART_Tx_Gate_impulse_gen4\ : impulse_gen_N_2cycle -- generate signal to latch data in UART Tx registers (2 clk width) (from SPEED process)
    port map(IN_SIGNAL => UART_Tx_Gate_flag4, IN_CLK => SCLK_LF_IN, RESET_N => RESET_N , OUT_SIGNAL_N => open, OUT_SIGNAL_P => UART_Tx_Gate_R4);

\UART_Tx_start_impulse_gen1\ : impulse_gen_N_2cycle -- generate signal to transmit UART data (2 clk width) (from AXIS process)
    port map(IN_SIGNAL => UART_Tx_Gate_flag1, IN_CLK => SCLK_Khz_IN, RESET_N => RESET_N , OUT_SIGNAL_N => open, OUT_SIGNAL_P => UART_Tx_Start_R1);

\UART_Tx_start_impulse_gen2\ : impulse_gen_N_2cycle -- generate signal to transmit UART data (2 clk width) (from MODE process)
    port map(IN_SIGNAL => UART_Tx_Gate_flag2, IN_CLK => SCLK_Khz_IN, RESET_N => RESET_N , OUT_SIGNAL_N => open, OUT_SIGNAL_P => UART_Tx_Start_R2);

\speed_reg_reset_impulse_gen2\ : impulse_gen_N_2cycle -- generate signal to reset speed reg in new mode (2 clk width) (from MODE process)
    port map(IN_SIGNAL => reset_speed_reg_flag, IN_CLK => SCLK_Khz_IN, RESET_N => RESET_N , OUT_SIGNAL_N => open, OUT_SIGNAL_P => reset_speed_reg_R);

\Axis_ready_impulse_gen1\ : impulse_gen_N_2cycle -- generate signal to latch axis data (2 clk width) (from AXIS process)
    port map(IN_SIGNAL => UART_Tx_Gate_flag1, IN_CLK => SCLK_Khz_IN, RESET_N => RESET_N , OUT_SIGNAL_N => open, OUT_SIGNAL_P => Axis_Ready_out_R);


\UART_write_trigger\ : Latch_trigger -- generate '1' once Tx_flags = 1 and hold it until being reset
    port map(Data => '0', Enable => '0', Aclr => Reset_Write_mode, Aset => UART_Tx_flags , Clock => SCLK_LF_IN, Q => start_counter);
    
Axis_select: process( RESET_N, SCLK_IN)    
begin
 if ( RESET_N ='0')then
    axis_out_b   <= "1000"; -- Axis: X 
    axis_out_r   <= "1000"; -- Axis: X 
    Axis_reg_block_pmac  <= '0';
    Axis_reg_block_uart  <= '0';
    current_axis    <= X;
    next_axis       <= X;
	UART_Tx_Gate_flag1   <= '0';     -- clear flag.
    UART_DATA_AXIS <= (OTHERS => '0');

  elsif (rising_edge(SCLK_IN)) then
    if (Axis_reg_block_pmac = '0') then      -- if axis select is allowed
        if (Axis_reg_block_uart = '0')then   -- if no other button is pressed
            case (UART_DATA1_IN) is         
               when x"55"  =>  Axis_reg_block_uart <=  '1'; -- Axis: X 
               when x"56"  =>  Axis_reg_block_uart <=  '1'; -- Axis: Y 
               when x"57"  =>  Axis_reg_block_uart <=  '1'; -- Axis: Z
               when x"58"  =>  Axis_reg_block_uart <=  '1'; -- Axis: 4  
               when others  => null;               
            end case;
     
        elsif (Axis_reg_block_uart = '1') then  -- button is pressed, uart block is set until button is released                   
            case (UART_DATA1_IN) is         
               when x"15"  => axis_out_b <= "1000"; next_axis <= X;  Axis_reg_block_uart <= '0'; Axis_reg_block_pmac <= '1'; UART_DATA_AXIS <= x"C5"; -- Axis: X 
               when x"16"  => axis_out_b <= "0100"; next_axis <= Y;  Axis_reg_block_uart <= '0'; Axis_reg_block_pmac <= '1'; UART_DATA_AXIS <= x"C6"; -- Axis: Y 
               when x"17"  => axis_out_b <= "0010"; next_axis <= Z;  Axis_reg_block_uart <= '0'; Axis_reg_block_pmac <= '1'; UART_DATA_AXIS <= x"C7"; -- Axis: Z
               when x"18"  => axis_out_b <= "0001"; next_axis <= A4; Axis_reg_block_uart <= '0'; Axis_reg_block_pmac <= '1'; UART_DATA_AXIS <= x"C8"; -- Axis: 4  
               when others     => null;     
            end case;        
        else null;
        end if; 

    elsif (Axis_feedback = axis_out_b) then  -- Axis_reg_block_pmac = 1, got axis confirmation from PMAC 
           current_axis    <=  next_axis;
           axis_out_r      <=  axis_out_b;   -- output new axis value (to update position)
           Axis_reg_block_pmac  <= '0';      -- clear register block
           UART_Tx_Gate_flag1   <= '1';     -- set flag to form short Gate impulse to latch Data into UART Tx registers       
    else                                     -- Axis_reg_block_pmac = 1, waiting for axis confirmation from PMAC
           UART_Tx_Gate_flag1   <= '0';     -- clear flag
    end if;

 end if;
end process axis_select;

Mode_select: process( RESET_N, SCLK_IN)    
begin
 if ( RESET_N ='0')then
    mode_out_b <= "001"; -- Mode: MANU 
    mode_out_r <= "001"; -- Mode: MANU 
    Mode_reg_block_uart   <= '0';
    Mode_reg_block_pmac   <= '0';
    current_mode    <= MANU;
    next_mode       <= MANU;
	UART_Tx_Gate_flag2   <= '0';     -- clear flag.
    UART_DATA_MODE <= (OTHERS => '0'); 
    reset_speed_reg_flag <= '0';     -- clear flag.

  elsif (rising_edge(SCLK_IN)) then

    if (Mode_reg_block_pmac = '0') then      -- if mode select is allowed
        if (Mode_reg_block_uart = '0')then   -- if no other button is pressed
           UART_Tx_Gate_flag2   <=  '0';     -- clear flag
            case (UART_DATA1_IN) is         
               when x"52"    => Mode_reg_block_uart <=  '1'; -- Mode: MANU 
               when x"53"    => Mode_reg_block_uart <=  '1'; -- Mode: INC
               when x"54"    => Mode_reg_block_uart <=  '1'; -- Mode: HPG
               when others   => null;               
            end case;
     
        elsif (Mode_reg_block_uart = '1') then  -- button is pressed, uart block is set until button is released 
           UART_Tx_Gate_flag2   <=  '0';     -- clear flag                  
            case (UART_DATA1_IN) is         
               when x"12"  => Mode_out_b <= "001"; next_mode <= MANU; Mode_reg_block_uart <= '0'; Mode_reg_block_pmac <= '1'; UART_DATA_MODE <= x"C2"; -- Mode: MANU  
               when x"13"  => Mode_out_b <= "010"; next_mode <= INC;  Mode_reg_block_uart <= '0'; Mode_reg_block_pmac <= '1'; UART_DATA_MODE <= x"C3"; -- Mode: INC  
               when x"14"  => Mode_out_b <= "100"; next_mode <= HPG;  Mode_reg_block_uart <= '0'; Mode_reg_block_pmac <= '1'; UART_DATA_MODE <= x"C4"; -- Mode: HPG 
               when others     => null;     
            end case;        
        else null;
        end if; 

    elsif (Mode_feedback = mode_out_b) then  -- Axis_reg_block_pmac = 1, got mode confirmation from PMAC 
           current_mode    <=  next_mode;
           Mode_out_r      <=  Mode_out_b;   -- output new mode value
           Mode_reg_block_pmac  <= '0';      -- clear register block
           UART_Tx_Gate_flag2   <=  '1';     -- set flag to form short Gate impulse to latch Data into UART Tx registers   
           reset_speed_reg_flag <= '1';      -- set flag to form short Gate impulse to reset speed register   
    else                                     -- Axis_reg_block_pmac = 1, waiting for axis confirmation from PMAC
           UART_Tx_Gate_flag2   <=  '0';     -- clear flag
           reset_speed_reg_flag <=  '0';     -- clear flag
    end if;

 end if;
end process mode_select;


buttons_reg: process( RESET_N, SCLK_IN)    
begin
 if ( RESET_N ='0')then
    Buttons_out_r <= (OTHERS => '0');
 elsif (rising_edge(SCLK_IN)) then
     case (UART_DATA1_IN) is        
         when x"41"    => Buttons_out_r(0)   <= '1';  -- Button: F1 is pressed
         when x"01"    => Buttons_out_r(0)   <= '0';  -- Button: F1 is released
 
         when x"42"    => Buttons_out_r(1)   <= '1';  -- Button: F2 is pressed
         when x"02"    => Buttons_out_r(1)   <= '0';  -- Button: F2 is released
  
         when x"43"    => Buttons_out_r(2)   <= '1';  -- Button: F3 is pressed
         when x"03"    => Buttons_out_r(2)   <= '0';  -- Button: F1 is released  

         when x"5A"    => Buttons_out_r(3)   <= '1';  -- Button: minus is pressed
         when x"1A"    => Buttons_out_r(3)   <= '0';  -- Button: minus is released

         when x"5B"    => Buttons_out_r(4)   <= '1';  -- Button: ampersand is pressed
         when x"1B"    => Buttons_out_r(4)   <= '0';  -- Button: ampersand is released

         when x"59"    => Buttons_out_r(5)   <= '1';  -- Button: plus is pressed
         when x"19"    => Buttons_out_r(5)   <= '0';  -- Button: plus is released

         when others     => null;
     end case;
 end if;
end process buttons_reg;

speed_reg_proc: process( RESET_N, SCLK_Khz_IN)    
begin
 if ( RESET_N ='0')then
    speed_out_r <= "0001";
    speed_reg_block <=  '0';        -- clear block, speed change is allowed on next J+/J- press
    UART_DATA_SPEED <=  x"00";      -- jog speed: 0
    UART_Tx_Gate_flag4    <= '0';   -- clear flag.

 elsif (rising_edge(SCLK_Khz_IN)) then -- !!!!!!!!!!!!!!!!!!!!!  WAS SCLK_IN !!!!!!!!!!!!!!!!!!!!!
    
      if (reset_speed_reg_R = '1') then -- occurs when entering new mode (2 clk_lf impulse)
            speed_out_r <= "0001";

            if (CURRENT_MODE = INC) then
                UART_DATA_SPEED <=  x"91"; UART_Tx_Gate_flag4 <= '1'; -- INC PLSR: x1
            elsif  (CURRENT_MODE = MANU) then
                UART_DATA_SPEED <=  x"88"; UART_Tx_Gate_flag4 <= '1'; -- jog speed: 5
            elsif (CURRENT_MODE = HPG) then
                UART_DATA_SPEED <=  x"A1"; UART_Tx_Gate_flag4 <= '1'; -- INC RAPD: x1
            else
                UART_DATA_SPEED <=  x"00"; UART_Tx_Gate_flag4 <= '1'; -- send null
            end if;          

      elsif (UART_DATA1_IN = x"5D" and speed_reg_block = '0') then  -- J+ pressed, speed change allowed  
                if (CURRENT_MODE = INC) then
                   case (speed_out_r) is      
                        when "0000" => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"91"; UART_Tx_Gate_flag4 <= '1'; -- INC PLSR: x1
                        when "0001" => speed_out_r <= "0010"; UART_DATA_SPEED <=  x"92"; UART_Tx_Gate_flag4 <= '1'; -- INC PLSR: x10
                        when "0010" => speed_out_r <= "0100"; UART_DATA_SPEED <=  x"93"; UART_Tx_Gate_flag4 <= '1'; -- INC PLSR: x100
                        when "0100" => speed_out_r <= "0100"; UART_DATA_SPEED <=  x"93"; UART_Tx_Gate_flag4 <= '1'; -- INC PLSR: x100 
                        when others => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"91"; UART_Tx_Gate_flag4 <= '1'; -- INC PLSR: x1
                    end case;
                elsif  (CURRENT_MODE = MANU) then
                   case (speed_out_r) is      
                        when "0000" => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"88"; UART_Tx_Gate_flag4 <= '1'; -- jog speed: 5
                        when "0001" => speed_out_r <= "0010"; UART_DATA_SPEED <=  x"89"; UART_Tx_Gate_flag4 <= '1'; -- jog speed: 20
                        when "0010" => speed_out_r <= "0100"; UART_DATA_SPEED <=  x"8A"; UART_Tx_Gate_flag4 <= '1'; -- jog speed: 50
                        when "0100" => speed_out_r <= "1000"; UART_DATA_SPEED <=  x"8B"; UART_Tx_Gate_flag4 <= '1'; -- jog speed: 100
                        when "1000" => speed_out_r <= "1000"; UART_DATA_SPEED <=  x"8B"; UART_Tx_Gate_flag4 <= '1'; -- jog speed: 100   
                        when others => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"88"; UART_Tx_Gate_flag4 <= '1'; -- jog speed: 5
                    end case;
                elsif (CURRENT_MODE = HPG) then
                     case (speed_out_r) is      
                        when "0000" => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"A1"; UART_Tx_Gate_flag4 <= '1'; -- INC RAPD: x1
                        when "0001" => speed_out_r <= "0010"; UART_DATA_SPEED <=  x"A2"; UART_Tx_Gate_flag4 <= '1'; -- INC RAPD: x10
                        when "0010" => speed_out_r <= "0100"; UART_DATA_SPEED <=  x"A3"; UART_Tx_Gate_flag4 <= '1'; -- INC RAPD: x100
                        when "0100" => speed_out_r <= "0100"; UART_DATA_SPEED <=  x"A3"; UART_Tx_Gate_flag4 <= '1'; -- INC RAPD: x100  
                        when others => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"A1"; UART_Tx_Gate_flag4 <= '1'; -- INC RAPD: x1
                    end case;
                else 
                    speed_out_r <= "0001"; UART_DATA_SPEED <=  x"00"; UART_Tx_Gate_flag4 <= '0';   
                end if;

                speed_reg_block <=  '1';        -- set block to change speed only 1 time

        elsif (UART_DATA1_IN = x"5C" and speed_reg_block = '0') then  -- J- pressed, speed change allowed
                 if (CURRENT_MODE = INC) then
                   case (speed_out_r) is      
                        when "0000" => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"91"; UART_Tx_Gate_flag4 <= '1'; -- INC PLSR: x1
                        when "0001" => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"91"; UART_Tx_Gate_flag4 <= '1'; -- INC PLSR: x1
                        when "0010" => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"91"; UART_Tx_Gate_flag4 <= '1'; -- INC PLSR: x1
                        when "0100" => speed_out_r <= "0010"; UART_DATA_SPEED <=  x"92"; UART_Tx_Gate_flag4 <= '1'; -- INC PLSR: x10
                        when "1000" => speed_out_r <= "0100"; UART_DATA_SPEED <=  x"93"; UART_Tx_Gate_flag4 <= '1'; -- INC PLSR: x100   
                        when others => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"91"; UART_Tx_Gate_flag4 <= '1'; -- INC PLSR: x1
                    end case;
                 elsif (CURRENT_MODE = MANU) then
                     case (speed_out_r) is      
                        when "0000" => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"88"; UART_Tx_Gate_flag4 <= '1';  -- jog speed: 5
                        when "0001" => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"88"; UART_Tx_Gate_flag4 <= '1';  -- jog speed: 5
                        when "0010" => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"88"; UART_Tx_Gate_flag4 <= '1';  -- jog speed: 5
                        when "0100" => speed_out_r <= "0010"; UART_DATA_SPEED <=  x"89"; UART_Tx_Gate_flag4 <= '1';  -- jog speed: 20
                        when "1000" => speed_out_r <= "0100"; UART_DATA_SPEED <=  x"8A"; UART_Tx_Gate_flag4 <= '1';  -- jog speed: 50  
                        when others => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"88"; UART_Tx_Gate_flag4 <= '1';  -- jog speed: 5
                    end case;
                elsif (CURRENT_MODE = HPG) then
                     case (speed_out_r) is      
                        when "0000" => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"A1"; UART_Tx_Gate_flag4 <= '1'; -- INC RAPD: x1
                        when "0001" => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"A1"; UART_Tx_Gate_flag4 <= '1'; -- INC RAPD: x1
                        when "0010" => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"A1"; UART_Tx_Gate_flag4 <= '1'; -- INC RAPD: x1
                        when "0100" => speed_out_r <= "0010"; UART_DATA_SPEED <=  x"A2"; UART_Tx_Gate_flag4 <= '1'; -- INC RAPD: x10
                        when "1000" => speed_out_r <= "0100"; UART_DATA_SPEED <=  x"A3"; UART_Tx_Gate_flag4 <= '1'; -- INC RAPD: x100   
                        when others => speed_out_r <= "0001"; UART_DATA_SPEED <=  x"A1"; UART_Tx_Gate_flag4 <= '1'; -- INC RAPD: x1
                    end case;
                else 
                    speed_out_r <= "0001"; UART_DATA_SPEED <=  x"00"; UART_Tx_Gate_flag4 <= '0';
                end if;

            speed_reg_block <=  '1';        -- set block to change speed only 1 time

        elsif (UART_DATA1_IN = x"1D") then  -- J+ released
            speed_reg_block <=  '0';        -- clear block, speed change is allowed on next J+/J- press
            UART_Tx_Gate_flag4    <= '0';     -- clear flag.

        elsif (UART_DATA1_IN = x"1C") then  -- J- released
            speed_reg_block <=  '0';        -- clear block, speed change is allowed on next J+/J- press
            UART_Tx_Gate_flag4    <= '0';     -- clear flag.

        else
            UART_Tx_Gate_flag4    <= '0';     -- clear flag;
        end if;
 end if;
end process speed_reg_proc;

Led_control: process( RESET_N, SCLK_Khz_IN)    

	  -- Alias for parts of LED register
      alias LED1         is UART_DATA_LED(7 downto 0);
      alias LED2         is UART_DATA_LED(15 downto 8);
      alias LED3         is UART_DATA_LED(23 downto 16);

begin

 if ( RESET_N ='0')then
	UART_Tx_Gate_flag3   <= '0';     -- clear flag.
    UART_DATA_LED <= (OTHERS => '0'); 
	Previous_LED	<= (OTHERS => '0');

 elsif (rising_edge(SCLK_Khz_IN)) then -- intentionally use low frequency clock to make longer gate signal
      if (LED_feedback /= Previous_Led) then
              case (LED_feedback) is
                  when "000"  => LED3 <=  x"03"; LED2 <=  x"02"; LED1 <=  x"01";  -- L3:OFF, L2:OFF, L1:OFF        
                  when "001"  => LED3 <=  x"03"; LED2 <=  x"02"; LED1 <=  x"41";  
                  when "010"  => LED3 <=  x"03"; LED2 <=  x"42"; LED1 <=  x"01";  
                  when "011"  => LED3 <=  x"03"; LED2 <=  x"42"; LED1 <=  x"41";  
                  when "100"  => LED3 <=  x"43"; LED2 <=  x"02"; LED1 <=  x"01";  
                  when "101"  => LED3 <=  x"43"; LED2 <=  x"02"; LED1 <=  x"41";  
                  when "110"  => LED3 <=  x"43"; LED2 <=  x"42"; LED1 <=  x"01";  
                  when "111"  => LED3 <=  x"43"; LED2 <=  x"42"; LED1 <=  x"41";  -- L3:ON, L2:ON,  L1:ON           
              end case;    
          Previous_Led <=  LED_feedback;
          UART_Tx_Gate_flag3   <=  '1';    -- used to form short Gate impulse to latch Data into UART Tx registers  
      
      else                      -- LED status has NO change
          UART_Tx_Gate_flag3   <= '0';     -- clear flag3 
      end if;                 
 end if;
end process Led_control;


UART_DATA: process( RESET_N, SCLK_IN)  
begin
    if ( RESET_N ='0')then
        UART_DATA_OUT_R <= (OTHERS => '0');

    elsif (rising_edge(SCLK_IN)) then
        if (UART_Tx_Gate_R1 = '1') then     -- AXIS confirmation code need to be transmitted
            UART_DATA_OUT_R <=  UART_DATA_AXIS;
        elsif (UART_Tx_Gate_R2 = '1') then  -- MODE confirmation code need to be transmitted
            UART_DATA_OUT_R <=  UART_DATA_MODE; 
        else
            UART_DATA_OUT_R <= (OTHERS => '0'); 
        end if;
    end if;

end process UART_DATA;

UART_SPEED_DATA: process( RESET_N, SCLK_IN)  
begin
    if ( RESET_N ='0')then
        UART_DATA_OUT_SPEED_R <= (OTHERS => '0');

    elsif (rising_edge(SCLK_IN)) then
        if (UART_Tx_Gate_R4 = '1') then     -- Speed code need to be transmitted
            UART_DATA_OUT_SPEED_R <=  UART_DATA_SPEED;       
        else
            UART_DATA_OUT_SPEED_R <= (OTHERS => '0'); 
        end if;
    end if;

end process UART_SPEED_DATA;

UART_LED_DATA: process( RESET_N, SCLK_IN)  
begin
    if ( RESET_N ='0')then
        UART_DATA_OUT_LED_R <= (OTHERS => '0');

    elsif (rising_edge(SCLK_IN)) then
        if (UART_Tx_Gate_R3 = '1') then     -- LED control code need to be transmitted
            UART_DATA_OUT_LED_R <=  UART_DATA_LED;       
        else
            UART_DATA_OUT_LED_R <= (OTHERS => '0'); 
        end if;
    end if;

end process UART_LED_DATA;

timer:      -- generate impulse to initiate UART transmission
process(RESET_N,SCLK_Khz_IN)
	begin
        if (RESET_N = '0') then
            counter <= (others => '0');
            stop_counter  <= '0';
            UART_Write_mode_R  <= '0';

        elsif (rising_edge(SCLK_Khz_IN)) then

            if (start_counter = '1' and UART_Tx_Gate_R = '0') then -- UART data was latched (Tx gate->0), but one of Tx flags is still '1'; 
                if (counter <= 2**(COUNTER_WIDTH-1) and stop_counter = '0') then
                    counter <= counter + 1;
                    UART_Write_mode_R  <= '1';    -- enter UART transmit mode
                else
                    counter <= (others => '0');
                    stop_counter  <= '1';
                    UART_Write_mode_R  <= '0';     -- exit UART transmit mode
                end if;
            else
                counter <= (others => '0');
                stop_counter  <= '0';
                UART_Write_mode_R  <= '0';
            end if; 
        end if;
end process timer; 

end behavioral;
