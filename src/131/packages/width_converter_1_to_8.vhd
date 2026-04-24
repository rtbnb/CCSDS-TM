----------------------------------------------------------------
-- File : width_converter_1_to_8.vhd
-- Created : 24.04.2026
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : 1-Bit to 8-Bit converter
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity width_converter_1_to_8 is
    port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        input_bit_i : in std_logic;
        data_valid_i : in std_logic;

        output_byte_o : out std_logic_vector (7 downto 0);
        data_valid_o : out std_logic
    
    );
end entity;


architecture behavioral of width_converter_1_to_8 is
    constant CLOCK_DIVISION : INTEGER := 8; -- Number of cycles per byte

    signal clock_devider_count_r : integer range 0 to 8 := 0;
    signal byte_working_r : std_logic_vector (7 downto 0) := "00000000";
    signal data_valid_r : std_logic;
    

begin

    width_converter_process: process(clk_i, reset_i)
    begin
        if reset_i = '0' then
            data_valid_o <= '0';
            output_byte_o <= "00000000";
            clock_devider_count_r <= 0;

        elsif rising_edge(clk_i) then
            if clock_devider_count_r = CLOCK_DIVISION then
               clock_devider_count_r <= 0; 
               
               if data_valid_r <= '1' then
                    output_byte_o <=  byte_working_r;
                    data_valid_r <= '0';
               end if;
               
            end if;
            
            if data_valid_i = '1' then
                byte_working_r(CLOCK_DIVISION-clock_devider_count_r-1) <= input_bit_i;
                clock_devider_count_r <= clock_devider_count_r + 1; 
                data_valid_r <= '1';
            end if;
            
            
        end if;
        
        
    end process width_converter_process;

end architecture behavioral;