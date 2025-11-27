----------------------------------------------------------------
-- File : secondary_header_sim.vhd
-- Created : 26.11.2025
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : Testbench for secondary_header_encoder implementation
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity secondary_header_sim is

end entity secondary_header_sim;

architecture behavioral of secondary_header_sim is
    component secondary_header_encoder is
        generic (
            secondary_header_data_field_width_octets_g : integer := 63 -- maximum length of this parameter is 63 according to CCSDS-132.0-B-3
        );
        port (
            output_clk_i : in std_logic;
            input_clk_i : in std_logic;
            version_number_i : in std_logic_vector(1 downto 0);
            length_i : in std_logic_vector(5 downto 0);
            data_field_i : in std_logic_vector(7 downto 0);
            secondary_header_o : out std_logic_vector(7 downto 0) := (others => '0');
            secondary_header_fully_read_o : out std_logic := '0'; -- high in the clk cycle when the last byte is read
            secondary_header_valid_o : out std_logic := '0'
        );
    end component secondary_header_encoder;

    signal output_clk_s : std_logic := '0';
    signal input_clk_s : std_logic := '0';
    signal version_number_s : std_logic_vector(1 downto 0) := (others => '0');
    signal length_s : std_logic_vector(5 downto 0) := (others => '0');
    signal data_field_s : std_logic_vector(7 downto 0) := (others => '0');
    signal secondary_header_s : std_logic_vector(7 downto 0) := (others => '0');
    signal secondary_header_fully_read_s : std_logic := '0';
    signal secondary_header_valid_s : std_logic := '0';

    constant CLK_PERIOD : time := 10 ns;

begin
    secondary_header_encoder_inst : secondary_header_encoder
    generic map(
        secondary_header_data_field_width_octets_g => 63
    )
    port map(
        output_clk_i => output_clk_s,
        input_clk_i => input_clk_s,
        version_number_i => version_number_s,
        length_i => length_s,
        data_field_i => data_field_s,
        secondary_header_o => secondary_header_s,
        secondary_header_fully_read_o => secondary_header_fully_read_s,
        secondary_header_valid_o => secondary_header_valid_s
    );
    
    clock: process begin
        output_clk_s <= '0';
        input_clk_s <= '0';
        wait for 10ns;
        output_clk_s <= '1';
        input_clk_s <= '1';
        wait for 10ns;
    end process clock;
    
    data_test: process begin
        version_number_s <= "01";
        length_s <= "111111";
        data_field_s <= x"AF";
        wait;
    end process data_test;

end architecture behavioral;
