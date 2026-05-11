----------------------------------------------------------------
-- File         : oid_generator.vhd
-- Created      : 28.11.2025
-- Author       : Hannah Lindner 
-- Project Name : HW/SW Project TM
-- Description  : only idle data noise 
----------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity oid_generator is 
    port(
        -- input ports 
        clk_i           : in std_logic; 
        reset_i         : in std_logic;
        enable_i        : in std_logic;  
        -- output ports  
        data_o          : out std_logic_vector(7 downto 0);
        data_valid_o    : out std_logic
    );
end entity oid_generator; 


architecture behavioral of oid_generator is 

    constant    INIT_SEQUENCE           : std_logic_vector(31 downto 0) := "11111111001111111111111111111101"; --"00000000001111111111111111111101"; 
    signal      shift_register_r        : std_logic_vector(31 downto 0) := INIT_SEQUENCE;
    signal      counter_r               : integer range 0 to 8 := 0;
    signal      generate_output_byte_r  : std_logic := '0';
    signal      first_data_requested_r  : std_logic := '0';

begin 

    -- process to generate the random sequence and XOR it with input data 
    generate_randomization : process (clk_i, reset_i)
        variable new_element_s      : std_logic;
        variable new_shift_register : std_logic_vector(31 downto 0);
    begin 
        if reset_i = '0'  then 
            -- reset signals 
            data_o                      <= "11111111";
            shift_register_r            <= INIT_SEQUENCE;
            -- reset variables 
            new_element_s               := '0'; 
            new_shift_register          := (others => '0');
            data_valid_o                <= '0';
            first_data_requested_r      <= '0';

        elsif rising_edge(clk_i) then 
            data_valid_o <= '0';
            if (enable_i = '1') and (first_data_requested_r = '0') then 
                data_valid_o <= '1'; 
                first_data_requested_r <= '1';
            end if;
            if (enable_i = '1') or (generate_output_byte_r = '1') then
                -- output data 
                data_o(7 - counter_r)   <= shift_register_r(0);
                -- shift register 
                new_shift_register      := shift_register_r(0) & shift_register_r(31 downto 1);
                -- XOR logic 
                new_shift_register(0)   := shift_register_r(1) XOR shift_register_r(0);
                new_shift_register(1)   := shift_register_r(2) XOR shift_register_r(0);
                new_shift_register(21)  := shift_register_r(22) XOR shift_register_r(0);

                shift_register_r        <= new_shift_register;
                
                if counter_r = 7 then 
                    counter_r <= 0;
                    data_valid_o <= '1';
                    generate_output_byte_r <= '0';
                else
                    counter_r <= counter_r + 1;
                    generate_output_byte_r <= '1';
                end if; 
                
            end if;
        end if; -- rising edge logic 
    end process generate_randomization;

end architecture behavioral;