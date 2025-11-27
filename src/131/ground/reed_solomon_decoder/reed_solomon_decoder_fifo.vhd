----------------------------------------------------------------
-- File : reed_solomon_decoder_fifo.vhd
-- Created : 18.11.2025
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : R/S Decoder stub for MVP, just implements the FIFO for error correction
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reed_solomon_decoder_fifo is
    port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        input_byte_i : in std_logic_vector (7 downto 0);
        data_valid_i : out std_logic := '0';

        data_valid_o : out std_logic;
        output_byte_o : out std_logic_vector (7 downto 0)
    );
end entity;

architecture behavioral of reed_solomon_decoder_fifo is
    CONSTANT ITERATIONS_FOR_SYNDROME : integer := 255;
    CONSTANT ITERATIONS_FOR_ERROR_POLY : integer := 32;
    CONSTANT ITERATIONS_FOR_CHIEN_SEARCH : integer := 255;
    CONSTANT FIFO_LENGHT : integer := ITERATIONS_FOR_SYNDROME+ITERATIONS_FOR_ERROR_POLY+ITERATIONS_FOR_CHIEN_SEARCH - 1;
    type finite_field_array_t is array (0 to FIFO_LENGHT) of std_logic_vector(7 downto 0);
    
begin

end architecture behavioral;
