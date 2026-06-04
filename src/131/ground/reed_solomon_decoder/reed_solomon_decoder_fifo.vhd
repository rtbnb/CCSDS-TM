----------------------------------------------------------------
-- File : reed_solomon_decoder_fifo.vhd
-- Created : 27.11.2025
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : R/S Decoder stub for MVP, just implements the FIFO for error correction
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reed_solomon_decoder_fifo is
    port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        input_byte_i : in std_logic_vector (7 downto 0);
        data_valid_i : in std_logic := '0';

        data_valid_o : out std_logic;
        output_byte_o : out std_logic_vector (7 downto 0)
        
    );
end entity reed_solomon_decoder_fifo;

architecture behavioral of reed_solomon_decoder_fifo is
    CONSTANT ITERATIONS_FOR_SYNDROME : integer := 255;
    CONSTANT ITERATIONS_FOR_ERROR_POLY : integer := 32;
    CONSTANT ITERATIONS_FOR_CHIEN_SEARCH : integer := 255;
    CONSTANT FIFO_LENGHT : integer := ITERATIONS_FOR_SYNDROME+ITERATIONS_FOR_ERROR_POLY-1;
    
    CONSTANT MESSAGE_LENGHT : INTEGER := 255; -- Lenght of a R/S Code block where 223 data is user data and 2*16 is Parity check symbols
    CONSTANT MAX_ERROR_COUNT : INTEGER := 16; -- Number of Errors to be correcable
    
    
    type reed_solomon_fifo_t is array (0 to FIFO_LENGHT) of std_logic_vector(8 downto 0);

    signal reed_solomon_fifo_r : reed_solomon_fifo_t := (others => "000000000");
    signal fifo_out_r : std_logic_vector(8 downto 0);
    signal clock_divier_count_r : integer range 0 to 255;
    signal new_data_in_fifo_r : std_logic:='0';
    
begin

    clock_divier : process (clk_i)
    begin        
        if reset_i = '0' then
            clock_divier_count_r <= 0;
        elsif rising_edge(clk_i) then
            if fifo_out_r(8) = '1' and new_data_in_fifo_r = '1' then
                 if clock_divier_count_r = MESSAGE_LENGHT-1 then
                    clock_divier_count_r <= 0;
                 else
                    clock_divier_count_r <= clock_divier_count_r + 1;
                 end if;
            --else
                --clock_divier_count_r <= 0;
            end if;
        end if;
    end process clock_divier;

    -- Handels FIFO logic, to shift data by one to simulate dalay of real decoder
    fifo_shift : process (clk_i)
    begin
        if reset_i = '0' then
            reed_solomon_fifo_r <= (others => "000000000");
            new_data_in_fifo_r <= '0';
            fifo_out_r <= "000000000";
        elsif rising_edge(clk_i) then
            -- Add clock division
            if data_valid_i = '1' then
                
                new_data_in_fifo_r <= '1';
                -- Shift fifo by one element, and append new one
                l_fifo_shift : for k in 0 to FIFO_LENGHT+1 loop
                    if k = 0 then
                        reed_solomon_fifo_r(k) <= data_valid_i & input_byte_i;
                    elsif k = FIFO_LENGHT+1 then
                        fifo_out_r <= reed_solomon_fifo_r(k-1);
                    else 
                        reed_solomon_fifo_r(k) <= reed_solomon_fifo_r(k-1);
                    end if;
                end loop l_fifo_shift;
            else
                new_data_in_fifo_r <= '0';
            end if;
        end if;
    end process fifo_shift;

    decoder_output_generator : process (clk_i)
    begin
        -- output values from index 0 to 223, prepare to correct error
        -- data valid flag shall be zero if not between 0 223
        if reset_i = '0' then
            data_valid_o <= '0';
            output_byte_o <= "00000000";
        elsif rising_edge(clk_i) then
            if clock_divier_count_r <= (MESSAGE_LENGHT-2*MAX_ERROR_COUNT) -1 then
                if fifo_out_r(8) = '1' and new_data_in_fifo_r = '1' then
                --if fifo_out_r(8) = '1' then
                    -- Add corrected data here
                    output_byte_o <= fifo_out_r (7 downto 0);
                    data_valid_o <= '1';
                else
                    
                output_byte_o <= fifo_out_r (7 downto 0);
                data_valid_o <= '0';
                end if;
            else
                data_valid_o <= '0';
            end if;
        
        end if;
        
    end process decoder_output_generator;

end architecture behavioral;
