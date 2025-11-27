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
    type reed_solomon_fifo_t is array (0 to FIFO_LENGHT) of std_logic_vector(7 downto 0);

    signal reed_solomon_fifo : reed_solomon_fifo_t := (others => "00000000");
    signal fifo_out : std_logic_vector(7 downto 0);

begin
    fifo_shift : process (clk_i)
    begin
        if reset_i = '0' then

        elsif rising_edge(clk_i) then
            -- Add clock division

            -- Shift fifo by one element, and append new one
            l_fifo_shift : for k in 0 to reed_solomon_fifo'length-1 loop
                if k = 0 then
                    reed_solomon_fifo(k) <= input_byte_i;
                elsif k = FIFO_LENGHT-1 then
                    fifo_out <= reed_solomon_fifo(k);
                else 
                    reed_solomon_fifo(k) <= reed_solomon_fifo(k-1);
                end if;
            end loop l_fifo_shift;
        end if;
            
    end process fifo_shift;

end architecture behavioral;
