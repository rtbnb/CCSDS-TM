----------------------------------------------------------------
-- File : decoder_sim.vhd
-- Created : 24.04.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Top Ground Decoder Testbench
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder_sim is
end entity decoder_sim;

architecture behavioral of decoder_sim is
    component decoder_buffer_and_structure is
        generic (
            tm_frame_data_size_octet_g: integer := 2040
        );
        port (
            -- inputs
            data_i: std_logic_vector(7 downto 0);
            data_valid_i: std_logic;
            clk_i: std_logic;

            -- outputs
            tm_data_field_o: out std_logic_vector(31 downto 0);
            tm_data_field_valid_o: out std_logic;
        );
    end component decoder_buffer_and_structure;

    signal data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal data_valid_s: std_logic := '0';
    signal clk_s: std_logic := '0';

    signal tm_data_field_s: std_logic_vector(31 downto 0);
    signal tm_data_field_valid_s: std_logic;
begin
    DBF: decoder_buffer_and_structure port map (
        data_i => data_s,
        data_valid_i => data_valid_s,
        clk_i => clk_s,
        tm_data_field_o => tm_data_field_s,
        tm_data_field_valid_o => tm_data_field_valid_s
    );

    clk: process
    begin
        clk_s <= '0';
        wait for 5 ns;
        clk_s <= '1';
        wait for 5 ns;
    end process clk;

    data_input: process
    begin
        -- tf frame version number + spacraft id
        data_s <= "00000000";
        data_valid_s <= '1';
        wait for 10ns;
        -- spacecraft id + vc id + ocf flag
        data_s <= "00000000";
        wait for 10ns;
        -- master channel frame count
        data_s <= "00000000";
        wait for 10ns;
        -- virtual channel frame count
        data_s <= "00000000";
        wait for 10ns;
        -- tm data field
        data_s <= "00011000";
        wait for 10ns;
        -- first header pointer
        data_s <= "00000000";
        wait for 10ns;
        -- data field 2040 octets
        for i in 0 to 2039 loop
            data_s <= std_logic_vector(to_unsigned(i, 8));
            wait for 10ns;
        end loop;
        wait;
    end process data_input;

end architecture behavioral;