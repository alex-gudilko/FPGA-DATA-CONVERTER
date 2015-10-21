# FPGA-DATA-CONVERTER
Convert misc data to BCD format for LCD display

Author: Aleksandr Gudilko
Email: gudilkoalex@gmail.com

Includes major functional blocks allowing to convert data from 3rd party remote pendant to BCD format widely used to show data
on LCD display.

Project structure:
 - VHDL source files:
 	** Input filter (1-channel and 4-channel) - removes line jittering from FPGA input line **
 	** BCD decoder - convert input integer data to BCD format (set of primitives to draw a digit on LCD) **
 	** Decoder - 1hot-3-to-8 - implement logic element "Decoder" - select single active output for given input **
 	** Pendant decoder - control block to initialize data decoding and transmission to UART buffer (hardware-specific) **
 	** Position_Int-to-bcd_decode - sub-programm for data conversion (hardware-specific)
 	
 - VHDL testbench:
   source stimulus files for functional simulation in ModelSim
