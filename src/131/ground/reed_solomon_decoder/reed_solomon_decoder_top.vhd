----------------------------------------------------------------
-- File : reed_solomon_decoder_top.vhd
-- Created : 20.05.2026
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : The top of the full R/S decoder
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_decoder_top is
    generic(
        max_number_of_errors_g : integer := 16
    );
    port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        input_byte_i : in std_logic_vector (7 downto 0);
        data_valid_i : in std_logic := '0';

        data_valid_o : out std_logic;
        output_byte_o : out std_logic_vector (7 downto 0);
		reed_solomon_failure_o : out std_logic 
    );
end entity reed_solomon_decoder_top;

architecture behavioral of reed_solomon_decoder_top is
    
begin

    reed_solomon_decoder_fifo_inst: entity work.reed_solomon_decoder_fifo
        port map (
            clk_i   => clk_i,
            reset_i => reset_i,
            input_byte_i => input_byte_i,
            data_valid_i => data_valid_i,
    
            data_valid_o  => data_valid_o,
            output_byte_o => output_byte_o
        );
                    
end architecture behavioral;
