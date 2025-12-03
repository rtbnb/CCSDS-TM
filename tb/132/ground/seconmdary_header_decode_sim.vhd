----------------------------------------------------------------
-- File : secondary_header_decoder_sim.vhd
-- Created : 03.12.2025
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Secondary Header Decoder Simulation File
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
        enable_i: in std_logic;
        clk_i: in std_logic; -- data is read on falling edge of clk_i
        data_i: in std_logic_vector(7 downto 0);

        reset_i: in std_logic; -- active low

        secondary_header_data_o: out std_logic_vector(7 downto 0 ) := (others => '0'); -- data can be read on falling edge of get_next_data_octet_i
        get_next_data_octet_i: in std_logic; -- data is valid on falling edge of get_next_data_octet_i
        secondary_header_fully_read_o: out std_logic := '0';
        version_o: out std_logic_vector(1 downto 0);
        length_o: out std_logic_vector(5 downto 0)
    );
end component secondary_header_decoder;
    signal enable_s: std_logic;
    signal clk_s: std_logic := '0';
    signal data_s: std_logic_vector(7 downto 0);
    signal reset_s: std_logic;
    signal secondary_header_data_s: std_logic_vector(7 downto 0);
    signal get_next_data_octet_s: std_logic;
    signal secondary_header_fully_read_s: std_logic;
    signal version_s: std_logic_vector(1 downto 0);
    signal length_s: std_logic_vector(5 downto 0);
begin
    secondary_header_decoder_inst: secondary_header_decoder
    generic map(
        secondary_header_data_field_width_octets_g => 63
    )
    port map(
        enable_i => enable_s,
        clk_i => clk_s,
        data_i => data_s,
        reset_i => reset_s,
        secondary_header_data_o => secondary_header_data_s,
        get_next_data_octet_i => get_next_data_octet_s,
        secondary_header_fully_read_o => secondary_header_fully_read_s,
        version_o => version_s,
        length_o => length_s
    );

    input_data: process is
    begin
        wait for 1000ns;
        -- Initialize signals
        enable_s <= '1';
        reset_s <= '0';
        clk_s <= '0';
        get_next_data_octet_s <= '0';
        wait for 10 ns;
        reset_s <= '1';
        wait for 10 ns;

        -- Provide test data
        data_s <= "111111" & "01";
        clk_s <= '1';
        wait for 5 ns;
        clk_s <= '0';
        wait for 5 ns;
        for i in 0 to 62 loop
            data_s <= std_logic_vector(to_unsigned(i, 8));
            clk_s <= '1';
            wait for 5 ns;
            clk_s <= '0';
            wait for 5 ns;
        end loop;

        wait for 50ns;

        -- read data field
        for i in 0 to 62 loop
            get_next_data_octet_s <= '1';
            wait for 5 ns;
            get_next_data_octet_s <= '0';
            wait for 5 ns;
        end loop;
    end process input_data;


end architecture behavioral;