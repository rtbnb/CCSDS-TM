----------------------------------------------------------------
-- File : integration_sim.vhd
-- Created : 07.05.2026
-- Author : Robin Eilers, Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : Testbench for the integration of 132 encoder > 131 encoder > 131 decoder > 132 decoder
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity integration_sim is

end entity integration_sim;

architecture behavioral of integration_sim is
    component system_integration_wrapper is
        port (
            ground_clk_i_1 : in std_logic;
            clk_i_0 : in std_logic;
            data_i_0 : in std_logic_vector ( 7 downto 0 );
            data_valid_i_0 : in std_logic;
            ready_o_0 : out std_logic;
            reset_i_0 : in std_logic;
            spacecraft_id_i_0 : in std_logic_vector ( 9 downto 0 );
            tm_data_field_o_0 : out std_logic_vector ( 31 downto 0 );
            tm_data_field_valid_o_0 : out std_logic;
            transfer_frame_version_number_i_0 : in std_logic_vector ( 1 downto 0 )   
        );
    end component system_integration_wrapper;

    signal tm_data_field_s: std_logic_vector(31 downto 0);
    signal tm_data_field_valid_s: std_logic;
    


    constant GND_CLK_PERIOD : time := 10 ns;
    constant CLK_PERIOD : time := 500 ns;

    signal clk_s: std_logic := '0';
    signal reset_s: std_logic := '0';

    signal transfer_frame_version_number_s: std_logic_vector(1 downto 0);
    signal spacecraft_id_s: std_logic_vector(9 downto 0);

    -- test signals
    signal test_input_data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal test_input_valid_s: std_logic := '0';
    signal test_input_ready_s: std_logic;
    
    -- ground
    signal ground_clk_s: std_logic := '0';

    -- automatic testbench
    constant WORDS_PER_FRAME: integer := 510;
    
    signal output_word_counter_r: integer := 0;
    signal test_output_data_s: std_logic_vector(7 downto 0) := (others => '0');

begin
    DBF: system_integration_wrapper port map (
        ground_clk_i_1 => ground_clk_s,
        data_i_0 => test_input_data_s,
        data_valid_i_0 => test_input_valid_s,
        clk_i_0 => clk_s,
        ready_o_0 => test_input_ready_s,
        reset_i_0 => reset_s,
        tm_data_field_o_0 => tm_data_field_s,
        tm_data_field_valid_o_0 => tm_data_field_valid_s,
        transfer_frame_version_number_i_0 => transfer_frame_version_number_s,
        spacecraft_id_i_0 => spacecraft_id_s
    );
    
    general_settings: process begin
        reset_s <= '1';
        test_input_valid_s <= '1';
        transfer_frame_version_number_s <= "11";
        spacecraft_id_s <= "0000000001";
        wait;
    end process general_settings;

    ground_clk: process begin
        ground_clk_s <= not ground_clk_s;
        wait for GND_CLK_PERIOD;
    end process ground_clk;

    clock: process begin
        clk_s <= not clk_s;
        wait for CLK_PERIOD;
    end process clock;

    data_test: process begin
        if (test_input_ready_s = '1') then
            test_input_data_s <= std_logic_vector((unsigned(test_input_data_s) +1));  
        end if;
        wait for 2 * CLK_PERIOD;
    end process data_test;

    test: process begin
        wait for GND_CLK_PERIOD;
        if tm_data_field_valid_s = '1' then
            output_word_counter_r <= output_word_counter_r + 1;
            if output_word_counter_r = WORDS_PER_FRAME then
                output_word_counter_r <= 0;
            end if;
            assert (tm_data_field_s(7 downto 0) = test_output_data_s) 
            report "mismatching output data first octet" severity error;
            
            assert (tm_data_field_s(15 downto 8) = std_logic_vector((unsigned(test_output_data_s) + 1))) 
            report "mismatching output data second octet" severity error;
            
            assert (tm_data_field_s(23 downto 16) = std_logic_vector((unsigned(test_output_data_s) + 2))) 
            report "mismatching output data third octet" severity error;
            
            assert (tm_data_field_s(31 downto 24) = std_logic_vector((unsigned(test_output_data_s) + 3))) 
            report "mismatching output data fourth octet" severity error;
            
            test_output_data_s <= std_logic_vector((unsigned(test_output_data_s) + 4));
            
        end if;
        wait for GND_CLK_PERIOD;
    end process test;
end architecture behavioral;
