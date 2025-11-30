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
        clk_i: in std_logic; -- data is read at falling edge of clk_i
        data_i: in std_logic_vector(7 downto 0);

        secondary_header_data_o: out std_logic_vector(7 downto 0 ) := (others => '0'); -- data can be read at falling edge of clk_i
        secondary_header_fully_read_o: out std_logic := '0';
        version_o: out std_logic_vector(1 downto 0);
        length_o: out std_logic_vector(5 downto 0)
    );
end entity secondary_header_decoder;

architecture behavioral of secondary_header_decoder is
begin

end architecture behavioral;