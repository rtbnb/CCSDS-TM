----------------------------------------------------------------
-- File : integration_sim.vhd
-- Created : 07.05.2026
-- Author : Robin Eilers, Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : Testbench for the integration of 132 encoder > 131 encoder > 131 decoder > 132 decoder
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity integration_sim is

end entity integration_sim;

architecture behavioral of integration_sim is
    component system_integration_wrapper is
        port (
            clk_i_0 : in STD_LOGIC;
            data_i_0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
            data_valid_i_0 : in STD_LOGIC;
            out_full_i_0 : in STD_LOGIC;
            ready_o_0 : out STD_LOGIC;
            reset_i_0 : in STD_LOGIC;
            spacecraft_id_i_0 : in STD_LOGIC_VECTOR ( 9 downto 0 );
            tm_data_field_o_0 : out STD_LOGIC_VECTOR ( 31 downto 0 );
            tm_data_field_valid_o_0 : out STD_LOGIC;
            transfer_frame_version_number_i_0 : in STD_LOGIC_VECTOR ( 1 downto 0 )   
        );
    end component system_integration_wrapper;

    signal tm_data_field_s: std_logic_vector(31 downto 0);
    signal tm_data_field_valid_s: std_logic;
    


    constant CLK_PERIOD : time := 10 ns;

    signal clk_s: std_logic := '0';
    signal reset_s: std_logic := '0';

    signal transfer_frame_version_number_s: std_logic_vector(1 downto 0);
    signal spacecraft_id_s: std_logic_vector(9 downto 0);
    signal out_full_i_s: std_logic := '0';

    -- test signals
    signal test_input_data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal test_input_valid_s: std_logic := '0';
    signal test_input_ready_s: std_logic;

begin
    DBF: system_integration_wrapper port map (
        data_i_0 => test_input_data_s,
        data_valid_i_0 => test_input_valid_s,
        clk_i_0 => clk_s,
        ready_o_0 => test_input_ready_s,
        reset_i_0 => reset_s,
        tm_data_field_o_0 => tm_data_field_s,
        tm_data_field_valid_o_0 => tm_data_field_valid_s,
        out_full_i_0 => out_full_i_s,
        transfer_frame_version_number_i_0 => transfer_frame_version_number_s,
        spacecraft_id_i_0 => spacecraft_id_s
    );
    
    general_settings: process begin
        reset_s <= '1';
        transfer_frame_version_number_s <= "11";
        spacecraft_id_s <= "0000000001";
        test_input_valid_s <= '1';
        wait;
    end process general_settings;

    clock: process begin
        clk_s <= not clk_s;
        wait for CLK_PERIOD;
    end process clock;
    
    data_test: process begin
        wait for CLK_PERIOD;
        if (test_input_ready_s = '1') then
            test_input_data_s <= std_logic_vector((unsigned(test_input_data_s) +1));  
        end if;
        wait for CLK_PERIOD;
    end process data_test;

end architecture behavioral;
