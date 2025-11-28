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
    
    CONSTANT MESSAGE_LENGHT : INTEGER := 255; -- Lenght of a R/S Code block where 223 data is user data and 2*16 is Parity check symbols
    CONSTANT MAX_ERROR_COUNT : INTEGER := 16; -- Number of Errors to be correcable
    
    
    type reed_solomon_fifo_t is array (0 to FIFO_LENGHT) of std_logic_vector(7 downto 0);

    signal reed_solomon_fifo_r : reed_solomon_fifo_t := (others => "00000000");
    signal fifo_out_r : std_logic_vector(7 downto 0);
    signal clock_divier_count_r : integer range 0 to 255;
    
begin

    clock_divier : process (clk_i)
    begin
        if data_valid_i = '1' then
             if clock_divier_count_r = MESSAGE_LENGHT then
                clock_divier_count_r <= 0;
             else
                clock_divier_count_r <= clock_divier_count_r + 1;
             end if;
        end if;
        
    end process clock_divier;

    -- Handels FIFO logic, to shift data by one to simulate dalay of real decoder
    fifo_shift : process (clk_i)
    begin
        if reset_i = '0' then

        elsif rising_edge(clk_i) then
            -- Add clock division

            -- Shift fifo by one element, and append new one
            l_fifo_shift : for k in 0 to reed_solomon_fifo_r'length-1 loop
                if k = 0 then
                    reed_solomon_fifo_r(k) <= input_byte_i;
                elsif k = FIFO_LENGHT-1 then
                    fifo_out_r <= reed_solomon_fifo_r(k);
                else 
                    reed_solomon_fifo_r(k) <= reed_solomon_fifo_r(k-1);
                end if;
            end loop l_fifo_shift;
        end if;
    end process fifo_shift;

    decoder_output_generator : process (clk_i)
    begin
        -- output values from index 0 to 223, prepare to correct error
        -- data valid flag shall be zero if not between 0 223

        if clock_divier_count_r < MESSAGE_LENGHT-2*MAX_ERROR_COUNT then
            -- Add corrected data here
            output_byte_o <= fifo_out_r;
            data_valid_o <= '1';
        else
            output_byte_o <= "00000000";
            data_valid_o <= '0';
        end if;

        
    end process decoder_output_generator;

end architecture behavioral;
