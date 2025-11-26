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
    component top_level is
        port (
            clk_i : in std_logic;
            version_number_i : in std_logic_vector(1 downto 0);
            length_i : in std_logic_vector(5 downto 0);
            data_field_i : in std_logic_vector( (SECONDARY_HEADER_DATA_FIELD_WIDTH_OCTETS * 8) - 1 downto 0);
            secondary_header_o : std_logic_vector(7 downto 0) := (others => '0');
            secondary_header_fully_read_o : out std_logic := '0' -- high in the clk cycle when the last byte is read
        );
    end component top_level;

    signal clk_s : std_logic := '0';
    signal version_number_s : std_logic_vector(1 downto 0) := (others => '0');
    signal length_s : std_logic_vector(5 downto 0) := (others => '0');
    signal data_field_s : std_logic_vector( (SECONDARY_HEADER_DATA_FIELD_WIDTH_OCTETS * 8) - 1 downto 0) := (others => '0');
    signal secondary_header_s : std_logic_vector(7 downto 0) := (others => '0');
    signal secondary_header_fully_read_s : std_logic := '0';

    constant CLK_PERIOD : time := 10 ns;

begin
    top_level_inst : top_level port map(
        clk_i => clk_s,
        version_number_i => version_number_s,
        length_i => length_s,
        data_field_i => data_field_s,
        secondary_header_o => secondary_header_s,
        secondary_header_fully_read_o => secondary_header_fully_read_s
    )
    generic map(
        SECONDARY_HEADER_DATA_FIELD_WIDTH_OCTETS => 63
    );

end architecture behavioral;
