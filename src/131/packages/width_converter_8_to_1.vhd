----------------------------------------------------------------
-- File : width_converter.vhd
-- Created : 24.04.2026
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : 8-Bit to 1-Bit converter
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity width_converter_8_to_1 is
    port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        input_byte_i : in std_logic_vector (7 downto 0);
        data_valid_i : in std_logic;
        encoder_done_i : in std_logic;

        output_bit_o : out std_logic;
        data_valid_o : out std_logic;
        encoder_done_o : out std_logic
    
    );
end entity;


architecture behavioral of width_converter_8_to_1 is
    constant CLOCK_DIVISION : INTEGER := 15; -- Number of cycles per byte

    signal input_byte_r : std_logic_vector (7 downto 0):="00000000";
    
    signal working_byte_r : std_logic_vector (7 downto 0):="00000000";
    signal data_valid_r : std_logic :='0';
    signal encoder_done_working_r :std_logic :='0';
    signal encoder_done_r: std_logic :='0';
    signal data_valid_working_r : std_logic :='0';
    
    signal clock_devider_count_r : integer range 0 to 15 := 0;
begin

    clock_devider_process: process (clk_i, reset_i)
    begin
        if reset_i = '0' then
            clock_devider_count_r <= 0;
            data_valid_r <= '0';
            data_valid_o <= '0';
            encoder_done_o <= '0';
            working_byte_r <= "00000000";
            input_byte_r <= "00000000";
            output_bit_o <= '0';
            data_valid_working_r <= '0';
            

        elsif rising_edge(clk_i) then
            
            if encoder_done_i = '1' then
                encoder_done_working_r <= encoder_done_i;
            --else
                --encoder_done_working_r <= encoder_done_i;
            end if; 
            
            
                
        
            if data_valid_i = '1' then
                if clock_devider_count_r = CLOCK_DIVISION then
                    working_byte_r <= input_byte_i;
                    data_valid_working_r <= '1';
                else
                   data_valid_r <= '1';
                    input_byte_r <= input_byte_i;
                end if;
                 
            end if;
            if clock_devider_count_r = CLOCK_DIVISION then
                clock_devider_count_r <= 0;
                

                -- Check if data was valid while sending out data and sample new data if true
                if data_valid_r = '1' then
                    working_byte_r <= input_byte_r;
                    data_valid_working_r <= '1'; 
                end if;
                
                if encoder_done_working_r = '1' then
                        encoder_done_o <= '1';
                    else
                        encoder_done_o <= '0';
                    end if;
                    
                encoder_done_working_r <= '0';
                
                data_valid_r <= '0';
                data_valid_o <= '0';

            else
                if (clock_devider_count_r mod 2 = 0) then
                    if data_valid_working_r = '1' then
                        output_bit_o <= working_byte_r(7-clock_devider_count_r/2);
                        data_valid_o <= '1';
                    else
                        data_valid_o <= '0';
                    end if;
                    
                                    
                else
                    if data_valid_working_r = '1' then
                    
                        data_valid_o <= '1';
                    else
                        data_valid_o <= '0';
                    
                    end if;
                 end if;

                clock_devider_count_r <= clock_devider_count_r + 1;
            end if;
        end if;
    end process clock_devider_process;

    

end architecture behavioral;