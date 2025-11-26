----------------------------------------------------------------
-- File : dummy_payload_data_generator_sim.vhd
-- Created : 26.11.2025
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Primary Header Encoder Simulation File
----------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dummy_payload_data_generator_sim is
--  Port ( );
end dummy_payload_data_generator_sim;

architecture Behavioral of dummy_payload_data_generator_sim is
component top_level is
	Port(
        clk_i: in std_logic;
        data_freqency_divider_i: in std_logic_vector(3 downto 0);
        data_out_clk_o: out std_logic;
        data_out_o: out std_logic_vector(31 downto 0)
	);
end component top_level;
    signal clk_s: std_logic;
    signal data_freqency_divider_s: std_logic_vector(3 downto 0);
    signal data_out_clk_s: std_logic;
    signal data_out_s: std_logic_vector(31 downto 0);
begin

EUT: top_level port map (
    clk_i => clk_s,
    data_freqency_divider_i => data_freqency_divider_s,
    data_out_clk_o => data_out_clk_s,
    data_out_o => data_out_s
);

process is
begin
    clk_s <= '1';
    wait for 5ns;
    clk_s <= '0';
    wait for 5ns;
end process;

process is
begin
    data_freqency_divider_s <= "0001";
    wait;
end process;


end Behavioral;
