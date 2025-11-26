----------------------------------------------------------------
-- File : secondary_header_encoder.vhd
-- Created : 26.11.2025
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Secondary Header Encoder
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity secondary_header_encoder is
    generic (
        SECONDARY_HEADER_DATA_FIELD_WIDTH_OCTETS : integer := 63 -- maximum length of this parameter is 63 according to CCSDS-132.0-B-3 4.1.3.1.6
    );

    port (
        clk_i : in std_logic;
        version_number_i : in std_logic_vector(1 downto 0);
        length_i : in std_logic_vector(5 downto 0);
        data_field_i : in std_logic_vector( (SECONDARY_HEADER_DATA_FIELD_WIDTH_OCTETS * 8) - 1 downto 0);
        secondary_header_o : out std_logic_vector(7 downto 0) := (others => '0');
        secondary_header_fully_read_o : out std_logic := '0' -- high in the clk cycle when the last byte is read
    );
end entity secondary_header_encoder;

architecture behavioral of secondary_header_encoder is
    signal octet_counter_s : integer range 0 to SECONDARY_HEADER_DATA_FIELD_WIDTH_OCTETS + 1 := 0;
    signal id_s : std_logic_vector(7 downto 0) := (others => '0');
    constant LAST_OCTET_COUNTER_VALUE : integer := SECONDARY_HEADER_DATA_FIELD_WIDTH_OCTETS; -- last octet is at position 63 which represents the 64th octet (0 to 63)

begin
    -- generate secondary header ID
    id_s(1 downto 0) <= version_number_i;
    id_s(7 downto 2) <= length_i;

    -- encoder output control logic
    process (clk_i, octet_counter_s) begin
        if rising_edge(clk_i) then
            -- reset logic
            if octet_counter_s = LAST_OCTET_COUNTER_VALUE + 1 then
                octet_counter_s <= 0;
                secondary_header_fully_read_o <= '0';
            -- last octet read logic
            elsif octet_counter_s = LAST_OCTET_COUNTER_VALUE then
                octet_counter_s <= octet_counter_s + 1;
                secondary_header_fully_read_o <= '1';
            -- normal operation logic
            else
                octet_counter_s <= octet_counter_s + 1;
            end if;
        end if;
    end process;

    -- secondary header output process
    with octet_counter_s select secondary_header_o <=
        id_s when 0,
        data_field_i((((octet_counter_s) * 8) - 1) downto ((octet_counter_s - 1) * 8)) when others;

end architecture behavioral;