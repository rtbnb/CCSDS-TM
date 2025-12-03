----------------------------------------------------------------
-- File : secondary_header_decoder.vhd
-- Created : 30.11.2025
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Primary Header Decoder
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity secondary_header_decoder is
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
end entity secondary_header_decoder;

architecture behavioral of secondary_header_decoder is
    signal secondary_header_r : std_logic_vector(((secondary_header_data_field_width_octets_g + 1) * 8) - 1 downto 0) := (others => '0');
begin

    -- output secondary header id
    version_o <= secondary_header_r(1 downto 0);
    length_o <= secondary_header_r(7 downto 2);

    read_data: process(clk_i) is
        variable data_octet_counter: integer := 0;
    begin
        if falling_edge(clk_i) and enable_i = '1' then
            if data_octet_counter = (secondary_header_data_field_width_octets_g + 1) then
                secondary_header_r(((data_octet_counter + 1)  * 8) - 1 downto data_octet_counter  * 8) <= data_i;
                data_octet_counter := 0;
            else 
                secondary_header_r(((data_octet_counter + 1)  * 8) - 1 downto data_octet_counter  * 8) <= data_i;
                data_octet_counter := data_octet_counter + 1;
            end if;
        end if;
    end process read_data;

    -- output data field logic
    output_data_field: process(get_next_data_octet_i) is
        variable data_octet_counter_out: integer := 1;
    begin
        if rising_edge(get_next_data_octet_i) then
            if data_octet_counter_out = secondary_header_data_field_width_octets_g then
                secondary_header_fully_read_o <= '1';
                secondary_header_data_o <= secondary_header_r( ((data_octet_counter_out + 1) * 8) - 1 downto (data_octet_counter_out) * 8);
                data_octet_counter_out := 1;
            else
                secondary_header_data_o <= secondary_header_r( ((data_octet_counter_out + 1) * 8) - 1 downto (data_octet_counter_out) * 8);
                data_octet_counter_out := data_octet_counter_out + 1;
                secondary_header_fully_read_o <= '0';
            end if;
        end if;
    end process output_data_field;

end architecture behavioral;