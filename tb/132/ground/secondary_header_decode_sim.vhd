----------------------------------------------------------------
-- File : secondary_header_decoder_sim.vhd
-- Created : 03.12.2025
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Secondary Header Decoder Simulation File
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity secondary_header_decoder_sim is
--  Port ( );
end secondary_header_decoder_sim;

architecture behavioral of secondary_header_decoder_sim is
component secondary_header_decoder is
	generic(
        secondary_header_data_field_width_octets_g : integer := 63 -- maximum length of this parameter is 63 according to CCSDS-132.0-B-3
    );
    port(
        enable_input_i: in std_logic;
        enable_output_i: in std_logic;

        clk_i: in std_logic;

        data_i: in std_logic_vector(7 downto 0);
        secondary_header_data_o: out std_logic_vector(7 downto 0 ) := (others => '0');
        secondary_header_fully_read_o: out std_logic := '0';

        version_o: out std_logic_vector(1 downto 0);
        length_o: out std_logic_vector(5 downto 0)
    );
end component secondary_header_decoder;
    signal enable_input_s: std_logic;
    signal enable_output_s: std_logic;
    signal clk_s: std_logic := '0';
    signal data_s: std_logic_vector(7 downto 0);
    signal reset_s: std_logic;
    signal secondary_header_data_s: std_logic_vector(7 downto 0);
    signal secondary_header_fully_read_s: std_logic;
    signal version_s: std_logic_vector(1 downto 0);
    signal length_s: std_logic_vector(5 downto 0);
begin
    secondary_header_decoder_inst: secondary_header_decoder
    generic map(
        secondary_header_data_field_width_octets_g => 63
    )
    port map(
        enable_input_i => enable_input_s,
        enable_output_i => enable_output_s,
        clk_i => clk_s,
        data_i => data_s,
        secondary_header_data_o => secondary_header_data_s,
        secondary_header_fully_read_o => secondary_header_fully_read_s,
        version_o => version_s,
        length_o => length_s
    );
    
    clk: process is
    begin
        clk_s <= '0';
        wait for 5ns;
        clk_s <= '1';
        wait for 5ns;
   end process clk;

    input_data: process is
    begin
        -- Provide test data
        data_s <= "111111" & "01";
        enable_input_s <= '1';
        wait for 10 ns;
        for i in 0 to 62 loop
            data_s <= std_logic_vector(to_unsigned(i, 8));
            wait for 10 ns;
        end loop;
        enable_input_s <= '0';

        wait for 50ns;

        -- read data field
        enable_output_s <= '1';
        for i in 0 to 62 loop
            wait for 10 ns;
        end loop;
    end process input_data;


end architecture behavioral;