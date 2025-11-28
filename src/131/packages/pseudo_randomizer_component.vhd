----------------------------------------------------------------
-- File : pseudo_randomizer_component.vhd
-- Created : 28.11.2025
-- Author : Hannah Lindner 
-- Project Name : HW/SW Project TM
-- Description : generic component for pseudorandomizer, polynomial h(x) = x^17 + x^14 + 1
----------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity pseudo_randomizer_component is 
    generic(
        clock_divider_g : integer := 1
        );
    port(
        -- input ports 
        clk_i   : in std_logic; 
        reset_i : in std_logic; 
        data_i  : in std_logic;
        -- output ports  
        data_o  : out std_logic; 
        done_o  : out std_logic
    );
end entity pseudo_randomizer_component; 


architecture behavioral of pseudo_randomizer_component is 
    constant INIT_SEQUENCE          : std_logic_vector(16 downto 0) := "11000111000111000"; 
    signal randomization_sequence_r : std_logic_vector(16 downto 0) := INIT_SEQUENCE;
begin 

    -- process to generate the random sequence and XOR it with input data 
    generate_randomization : process (clk_i, reset_i)
        variable clock_counter_r    : integer := 0; -- variable for clock division
        variable new_element_s      : std_logic;
        variable new_vector_long_s  : std_logic_vector(17 downto 0);
    begin 
        if reset_i = '0' then 
            -- reset signals and variable  
            done_o                      <= '0'; 
            data_o                      <= '0';
            randomization_sequence_r    <= INIT_SEQUENCE;
            clock_counter_r             := 0; 
            new_element_s               := '0'; 
            new_vector_long_s           := (others => '0');

        elsif rising_edge(clk_i) then 
            -- clock division
            clock_counter_r := clock_counter_r + 1; 
            if clock_counter_r = clock_divider_g then 
                -- XOR data 
                data_o <= data_i XOR randomization_sequence_r(0);
                -- generate new element + shift vector 
                new_element_s := randomization_sequence_r(0) XOR randomization_sequence_r(14);
                new_vector_long_s := new_element_s & randomization_sequence_r;
                randomization_sequence_r <= new_vector_long_s(17 downto 1); 
                -- reset clock counter 
                clock_counter_r := 0;
            end if; -- clock divider 
        end if; -- rising edge logic 
    end process generate_randomization;

end architecture behavioral;