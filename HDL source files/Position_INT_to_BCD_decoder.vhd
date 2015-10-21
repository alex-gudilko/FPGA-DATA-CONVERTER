--------------------------------------------------------------------------------
-- Company: <Mehatronika>
-- Author: 	<Aleksandr Gudilko>
-- Email: 	gudilkoalex@gmail.com
--
-- File: Position_INT_to_BCD_decoder.vhd
-- File history:
--      <2.0>: <02/04/2015>: <Updates integer and fractional position automatically. Send codes to pendant>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- <receive data in integer form and form BCD code for UART transmitter>
-- BCD data format is commonly used to show data on LCD or 7-segment disolays
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


entity Position_INT_to_BCD_decoder is
GENERIC(
    d_width   : INTEGER := 24; -- data width 
    counter_width   : INTEGER := 11 -- position update frequency
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
-- 16bit counter -> 1,67 s  period clock 0,6  Hz

port (
        RESET_N         :	in std_logic; -- RESET. Active low. 
		SCLK_IN         :	in std_logic; -- External SCLK 50 Mhz
		SCLK_LF_IN      :	in std_logic; -- External SCLK 10 Mhz
		SCLK_KHz_IN      :	in std_logic; -- External SCLK xx hz

        Latch_data_IN   :	in std_logic; -- latch new position data input
        Data_ready_IN   :	in std_logic; -- from PMAC_block. if '1' - data is ready
        Pos_update_request    :	in std_logic; -- from PMAC_block. if '1' - send new position
        Update_freq           :	in std_logic; -- from PMAC_block. 

		X_Pos_Int_in :  	in std_logic_vector(d_width-1 downto 0); 	-- X position (int)
		X_pos_Fract_in :  	in std_logic_vector(d_width-1 downto 0); 	-- X position (fract)
		Y_Pos_Int_in :  	in std_logic_vector(d_width-1 downto 0); 	-- Y position (int)
		Y_pos_Fract_in :  	in std_logic_vector(d_width-1 downto 0); 	-- Y position (fract)
		Z_Pos_Int_in :  	in std_logic_vector(d_width-1 downto 0); 	-- Z position (int)
		Z_pos_Fract_in :  	in std_logic_vector(d_width-1 downto 0); 	-- Z position (fract)
		A4_Pos_Int_in :  	in std_logic_vector(d_width-1 downto 0); 	-- 4 position (int)
		A4_pos_Fract_in :  in std_logic_vector(d_width-1 downto 0);    -- 4 position (fract)


        active_axis   :  	in std_logic_vector(3 downto 0); 	-- shows active axis

        UART_Send_Data   :	out std_logic; -- if '1' - send position via UART
        Data_ready_out   :	out std_logic; -- decoding finished
        Position_Tx_gate   :	out std_logic; -- gate for UART Tx registers
 		Position_to_decode :  	out std_logic_vector(13 downto 0); 	-- position to be decoded

 		Pos_Int_dig12_out :  	out std_logic_vector(7 downto 0); 	-- position int digits 1 & 2
 		Pos_Int_dig34_out :  	out std_logic_vector(7 downto 0); 	-- position int digits 3 & 4
 		Pos_Int_dig56_out :  	out std_logic_vector(7 downto 0); 	-- position int digits 5 & 6
 		Pos_Fract_dig12_out :  	out std_logic_vector(7 downto 0); 	-- position fract digits 1 & 2
 		Pos_Fract_dig34_out :  	out std_logic_vector(7 downto 0) 	-- position fract digits 3 & 4
          
        
);
end Position_INT_to_BCD_decoder;

architecture a_Position of Position_INT_to_BCD_decoder is

   -- signal, component etc. declarations
signal Latch_data:  	        std_logic; 	-- combined inputs to decide when to latch new position data
signal New_data_available :  	std_logic; 	-- if '1' - current data /= previous data

signal update_count:    std_logic;  								-- time-based position update (long signal)
signal Latch_data_timer_imp:    std_logic;  						-- time-based position update (impulse)
signal 	clk_divider :  	std_logic_vector(counter_width-1 downto 0); -- clock divider 

signal Data_ready_out_R:  	std_logic; 	-- data is ready
signal Position_Tx_gate_R:  std_logic; 	-- latch BCD position data in UART Tx registers
signal UART_Send_Data_R:  	std_logic; 	-- will be used to generate UART write impulse

-- current position
signal  Pos_Sign_code_R:  	    std_logic_vector(3 downto 0); 	-- int position sign
signal 	Pos_Int_dig12_R :  	    std_logic_vector(7 downto 0); 	-- int position digits 1&2 (sign)
signal 	Pos_Int_dig34_R :  	    std_logic_vector(7 downto 0); 	-- int position digits 3&4 
signal 	Pos_Int_dig5_R :  	    std_logic_vector(3 downto 0); 	-- int position digits 5 
signal 	Pos_Int_dig6_R :  	    std_logic_vector(3 downto 0); 	-- int position digits 6 
signal 	Pos_Fract_dig12_R :  	std_logic_vector(7 downto 0); 	-- fract position digits 1&2 
signal 	Pos_Fract_dig34_R :  	std_logic_vector(7 downto 0); 	-- fract position digits 3&4 

--previous position
signal 	Prev_Pos_Int_dig12_R :  	std_logic_vector(7 downto 0); 	-- int position digits 1&2
signal 	Prev_Pos_Int_dig34_R :  	std_logic_vector(7 downto 0); 	-- int position digits 3&4 
signal 	Prev_Pos_Int_dig5_R :  	    std_logic_vector(3 downto 0); 	-- int position digits 5 
signal 	Prev_Pos_Fract_dig12_R :  	std_logic_vector(7 downto 0); 	-- fract position digits 1&2 
signal 	Prev_Pos_Fract_dig34_R :  	std_logic_vector(7 downto 0); 	-- fract position digits 3&4 

-- comparison results
signal 	Comp_Pos_Int_dig12 :  	    std_logic; 	-- int position digits 1
signal 	Comp_Pos_Int_dig34 :  	    std_logic; 	-- int position digits 3&4 
signal 	Comp_Pos_Int_dig5  :  	    std_logic; 	    -- int position digits 5 
signal 	Comp_Pos_Fract_dig12 :  	std_logic; 	-- fract position digits 1&2 
signal 	Comp_Pos_Fract_dig34 :  	std_logic; 	-- fract position digits 3&4 

signal	X_Pos_Int_R :  	std_logic_vector(d_width-1 downto 0); 	-- X position (int)
signal	X_pos_Fract_R : std_logic_vector(d_width-1 downto 0); 	-- X position (fract)
signal	Y_Pos_Int_R :  	std_logic_vector(d_width-1 downto 0); 	-- Y position (int)
signal	Y_pos_Fract_R : std_logic_vector(d_width-1 downto 0); 	-- Y position (fract)
signal	Z_Pos_Int_R :  	std_logic_vector(d_width-1 downto 0); 	-- Z position (int)
signal	Z_pos_Fract_R : std_logic_vector(d_width-1 downto 0); 	-- Z position (fract)
signal	A4_Pos_Int_R :  std_logic_vector(d_width-1 downto 0); 	-- 4 position (int)
signal	A4_pos_Fract_R :std_logic_vector(d_width-1 downto 0);   -- 4 position (fract)

signal 	Position_sign_R :  	    std_logic; 	-- sign of position ( 0 => "+", 1 => "-")
signal	Position_int_R :  std_logic_vector(13 downto 0); -- input code for 5 digit BCD decoder (int part of position)
signal	Position_fract_R :  std_logic_vector(13 downto 0); -- input code for 4 digit BCD decoder (fract part of position)

--signal	pos_tenthousands_R :  std_logic_vector(3 downto 0); -- BCD code for "thousands" digit (int part)
signal	pos_thousands_R :  std_logic_vector(3 downto 0); -- BCD code for "thousands" digit (int part)
signal	pos_hundreds_R :  std_logic_vector(3 downto 0); -- BCD code for "hundreds" digit (int part)
signal	pos_tens_R :  std_logic_vector(3 downto 0); 	-- BCD code for "tens" digit (int part)
signal	pos_ones_R :  std_logic_vector(3 downto 0); 	-- BCD code for "ones" digit (int part)

signal	pos_fr_thousands_R :  std_logic_vector(3 downto 0); -- BCD code for "thousands" digit (fract part)
signal	pos_fr_hundreds_R :  std_logic_vector(3 downto 0); -- BCD code for "hundreds" digit (fract part)
signal	pos_fr_tens_R :  std_logic_vector(3 downto 0); 	-- BCD code for "tens" digit (fract part)
signal	pos_fr_ones_R :  std_logic_vector(3 downto 0); 	-- BCD code for "ones" digit (fract part)

  component impulse_gen_N_2cycle
port (
        RESET_N          :in std_logic; -- reset
        IN_SIGNAL        :in std_logic; -- input signal
        IN_CLK           :in std_logic; -- input clock signal

		OUT_SIGNAL_P       :out std_logic; -- output impluse Active High
		OUT_SIGNAL_N       :out std_logic -- output impluse Active Low
);
  end component;

component bcd_4dig
   Port ( 
      number   : in  std_logic_vector (13 downto 0);
      thousands : out std_logic_vector (3 downto 0);
      hundreds : out std_logic_vector (3 downto 0);
      tens     : out std_logic_vector (3 downto 0);
      ones     : out std_logic_vector (3 downto 0)
   );
  end component;

component InEquality_comparator_8bit is
    port( DataA : in    std_logic_vector(7 downto 0);
          DataB : in    std_logic_vector(7 downto 0);
          ANEB  : out   std_logic
        );
  end component;

component InEquality_comparator_4bit is
    port( DataA : in    std_logic_vector(3 downto 0);
          DataB : in    std_logic_vector(3 downto 0);
          ANEB  : out   std_logic
        );
  end component;

begin

-- wiring outputs;
    Data_ready_out    <= Data_ready_out_R;
    Position_Tx_gate  <= Position_Tx_gate_R;
    UART_Send_Data    <= UART_Send_Data_R;

    Pos_Int_dig12_out   <= Pos_Int_dig12_R;  
    Pos_Int_dig34_out   <= Pos_Int_dig34_R;  
    Pos_Int_dig56_out(7 downto 4)   <= Pos_Int_dig5_R; 
    Pos_Int_dig56_out(3 downto 0)   <= Pos_Int_dig6_R; 
    Pos_Fract_dig12_out <= Pos_Fract_dig12_R;
    Pos_Fract_dig34_out <= Pos_Fract_dig34_R;

    Position_to_decode  <= Position_int_R;

-- assigning signals
    Latch_data  <= Latch_data_IN or Latch_data_timer_imp;   -- may insert additional signals to start position decoding and transmission
    New_data_available <= Comp_Pos_Int_dig12 or Comp_Pos_Int_dig34 or Comp_Pos_Int_dig5 or Comp_Pos_Fract_dig12 or Comp_Pos_Fract_dig34;


\UART_Tx_Gate_impulse_gen1\ : impulse_gen_N_2cycle -- generate signal to latch data in UART Tx registers (2 clk width) 
    port map(IN_SIGNAL => Data_ready_out_R, IN_CLK => SCLK_LF_IN, RESET_N => RESET_N , OUT_SIGNAL_N => open, OUT_SIGNAL_P => Position_Tx_gate_R);

\Timer_pos_update_impulse_gen\ : impulse_gen_N_2cycle -- generate signal to update position (2 clk width) 
    port map(IN_SIGNAL => update_count, IN_CLK => SCLK_Khz_IN, RESET_N => RESET_N , OUT_SIGNAL_N => open, OUT_SIGNAL_P => Latch_data_timer_imp);


\bcd_decoder_4digit_int\ : bcd_4dig -- 4-digit BCD decoder (integer part of position)
    port map(number => Position_int_R(13 downto 0), thousands => pos_thousands_R, hundreds => pos_hundreds_R, tens => pos_tens_R , ones => pos_ones_R);

\bcd_decoder_4digit_fract\ : bcd_4dig -- 4-digit BCD decoder (fractional part of position)
    port map(number => Position_fract_R, thousands => pos_fr_thousands_R, hundreds => pos_fr_hundreds_R, tens => pos_fr_tens_R , ones => pos_fr_ones_R);


\comparator1\ : InEquality_comparator_8bit -- compare previous and current position data (int_digits 1&2)
    port map(DataA => Pos_Int_dig12_R, DataB => prev_Pos_Int_dig12_R, ANEB => Comp_Pos_Int_dig12);

\comparator2\ : InEquality_comparator_8bit -- compare previous and current position data (int_digits 3&4)
    port map(DataA => Pos_Int_dig34_R, DataB => prev_Pos_Int_dig34_R, ANEB => Comp_Pos_Int_dig34);

\comparator3\ : InEquality_comparator_4bit -- compare previous and current position data (int_digits 5&6)
    port map(DataA => Pos_Int_dig5_R, DataB => prev_Pos_Int_dig5_R, ANEB => Comp_Pos_Int_dig5);

\comparator4\ : InEquality_comparator_8bit -- compare previous and current position data (fract_digits 1&2)
    port map(DataA => Pos_Fract_dig12_R, DataB => prev_Pos_Fract_dig12_R, ANEB => Comp_Pos_Fract_dig12);

\comparator5\ : InEquality_comparator_8bit -- compare previous and current position data (fract_digits 1&2)
    port map(DataA => Pos_Fract_dig34_R, DataB => prev_Pos_Fract_dig34_R, ANEB => Comp_Pos_Fract_dig34);


Data_latch: process( RESET_N, SCLK_LF_IN)  
begin
    if ( RESET_N ='0')then
            X_Pos_Int_R       <= (OTHERS => '0');
            X_pos_Fract_R     <= (OTHERS => '0');
            Y_Pos_Int_R       <= (OTHERS => '0');
            Y_pos_Fract_R     <= (OTHERS => '0');
            Z_Pos_Int_R       <= (OTHERS => '0');
            Z_pos_Fract_R     <= (OTHERS => '0');
            A4_Pos_Int_R      <= (OTHERS => '0');
            A4_pos_Fract_R    <= (OTHERS => '0');

            Data_ready_out_R   <= '1';              -- set flag to prevent false trigger after reset

    elsif (falling_edge(SCLK_LF_IN)) then
            if (Data_ready_IN = '1' and Latch_data = '1') then     -- new axis is selected or update timer expired
                X_Pos_Int_R      <=  X_Pos_Int_in;
                X_pos_Fract_R    <=  X_Pos_fract_in;
                Y_Pos_Int_R      <=  Y_Pos_Int_in;
                Y_pos_Fract_R    <=  Y_Pos_fract_in;
                Z_Pos_Int_R      <=  Z_Pos_Int_in;
                Z_pos_Fract_R    <=  Z_Pos_fract_in;
                A4_Pos_Int_R     <=  A4_Pos_Int_in;
                A4_pos_Fract_R   <=  A4_Pos_fract_in;
                
                Data_ready_out_R   <= '0'; -- clear flag       
            else                                        -- if Latch_data_IN = '0'
                Data_ready_out_R   <= '1';              --DELAYED FOR 1/2 CLK LF CYCLE        
            end if;
      end if;

end process Data_latch;

DATA_MUX: process( RESET_N, SCLK_IN)  
begin
    if ( RESET_N ='0')then
        Position_sign_R     <= '0';
        Position_int_R      <= (OTHERS => '0');
        Position_fract_R    <= (OTHERS => '0');

        Pos_Int_dig12_R    <= x"C0"; -- display: +0
        Pos_Int_dig34_R    <= (OTHERS => '0');
        Pos_Int_dig5_R     <= (OTHERS => '0');
        Pos_Int_dig6_R     <= x"A";
        Pos_Fract_dig12_R  <= (OTHERS => '0');
        Pos_Fract_dig34_R  <= (OTHERS => '0');

    elsif (rising_edge(SCLK_IN)) then    
            if (Latch_data = '0' and Data_ready_out_R = '0') then -- duration only 1/2 CLK LF cycle

                case (active_axis) is
                    when "1000" =>  -- Active axis: X
                                    Position_int_R   <= X_Pos_Int_R  (13 downto 0);
                                    Position_fract_R <= X_Pos_Fract_R (13 downto 0); 
                                    Position_sign_R  <= X_Pos_Int_R (16);

                    when "0100" =>  -- Active axis: Y
                                    Position_int_R   <= Y_Pos_Int_R  (13 downto 0); 
                                    Position_fract_R <= Y_Pos_Fract_R (13 downto 0);
                                    Position_sign_R  <= Y_Pos_Int_R (16);

                    when "0010" =>  -- Active axis: Z
                                    Position_int_R   <= Z_Pos_Int_R  (13 downto 0); 
                                    Position_fract_R <= Z_Pos_Fract_R (13 downto 0);
                                    Position_sign_R  <= Z_Pos_Int_R (16);

                    when "0001" =>  -- Active axis: 4
                                    Position_int_R   <= A4_Pos_Int_R (13 downto 0); 
                                    Position_fract_R <= A4_Pos_Fract_R (13 downto 0);
                                    Position_sign_R  <= A4_Pos_Int_R (16);

                    when others =>  Position_int_R   <= (OTHERS => '0'); 
                                    Position_fract_R <= (OTHERS => '0');
                                    Position_sign_R  <= '0';
                end case;

-- push integer part of position to outputs
                Pos_Int_dig12_R   <=  Pos_Sign_code_R & pos_thousands_R;
                Pos_Int_dig34_R   <=  pos_hundreds_R & pos_tens_R;
                Pos_Int_dig5_R    <=  pos_ones_R;
                Pos_Int_dig6_R    <=  x"A";

 -- push fractional part of position to outputs
                Pos_Fract_dig12_R   <=  pos_fr_thousands_R & pos_fr_hundreds_R;
                Pos_Fract_dig34_R   <=  pos_fr_tens_R & pos_fr_ones_R;


           else -- latching new data when Latch_data_IN = '1'; transmitting new UART data when Data_ready_out_R = '1'
                null;
           end if;
    end if;

end process DATA_MUX;

Sign_decoder: process( RESET_N, Position_sign_R)  
begin
    if ( RESET_N ='0')then
        Pos_Sign_code_R <= x"C"; --  -> "+"

    elsif (Position_sign_R = '0') then  -- if '0' -> "+"
        Pos_Sign_code_R <= x"C";
    else                                -- if '1' -> "-"
        Pos_Sign_code_R <= x"B";
    end if;
end process Sign_decoder;

clock_divider: process( RESET_N, SCLK_LF_IN)  
begin
    if ( RESET_N ='0')then
        clk_divider <= (OTHERS => '0');

    elsif (rising_edge(SCLK_KHz_IN)) then
        clk_divider <= clk_divider + 1;
    end if;
end process clock_divider;

    update_count    <=  clk_divider(counter_width-1);


update_timer: process( RESET_N, update_count)  
begin
    if ( RESET_N ='0')then
            UART_Send_Data_R    <= '0';             -- active HIGH. "Sent new position data" is inactive

    elsif (falling_edge(update_count)) then         -- delay between rising and falling edge is used to process new data
            if (New_data_available = '1') then  	-- new data is available 
                UART_Send_Data_R <= '1';    		-- set flag to send data via UART
                prev_Pos_Int_dig12_R    <=  Pos_Int_dig12_R;
                prev_Pos_Int_dig34_R    <=  Pos_Int_dig34_R;
                prev_Pos_Int_dig5_R     <=  Pos_Int_dig5_R;
                prev_Pos_Fract_dig12_R  <=  Pos_Fract_dig12_R;
                prev_Pos_Fract_dig34_R  <=  Pos_Fract_dig34_R;

            else                                       
                UART_Send_Data_R <= '0';    -- clear flag
            end if;
    end if;
end process update_timer;

end a_Position;