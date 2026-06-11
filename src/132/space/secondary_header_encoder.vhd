----------------------------------------------------------------
-- File : secondary_header_encoder.vhd
-- Created : 26.11.2025
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Secondary Header Encoder
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity secondary_header_encoder is
    generic (
        SECONDARY_HEADER_DATA_FIELD_WIDTH_OCTETS : integer := 63 -- maximum length of this parameter is 63 according to CCSDS-132.0-B-3 4.1.3.1.6
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
end entity secondary_header_encoder;

architecture behavioral of secondary_header_encoder is
    constant LAST_OCTET_COUNTER_VALUE : integer := SECONDARY_HEADER_DATA_FIELD_WIDTH_OCTETS; -- last octet is at position 63 which represents the 64th octet (0 to 63)
    signal octet_counter_r : integer range 0 to LAST_OCTET_COUNTER_VALUE + 1 := 0;
    signal id_s : std_logic_vector(7 downto 0) := (others => '0');
    signal secondary_header_fully_read_r : std_logic := '0';
    signal secondary_header_s : std_logic_vector(7 downto 0) := (others => '0');

    signal data_field_in_octet_counter_r : integer range 0 to SECONDARY_HEADER_DATA_FIELD_WIDTH_OCTETS := 0;
    signal data_field_r : std_logic_vector( (SECONDARY_HEADER_DATA_FIELD_WIDTH_OCTETS * 8) - 1 downto 0) := (others => '0');
    signal data_field_valid_flag_r : std_logic := '0';
   
begin
    -- generate secondary header ID
    id_s(1 downto 0) <= version_number_i;
    id_s(7 downto 2) <= length_i;
    
    -- output header fully read
    secondary_header_fully_read_o <= secondary_header_fully_read_r;
    secondary_header_valid_o <= data_field_valid_flag_r;
    with data_field_valid_flag_r select secondary_header_o <=
        secondary_header_s when '1',
        x"00" when others;

    -- encoder output control logic
    process (output_clk_i, octet_counter_r) begin
        if rising_edge(output_clk_i) then 
            -- last octet read logic
            if octet_counter_r = LAST_OCTET_COUNTER_VALUE then
                octet_counter_r <= 0;
                secondary_header_fully_read_r <= '0';
            elsif octet_counter_r = LAST_OCTET_COUNTER_VALUE - 1 then
                octet_counter_r <= octet_counter_r + 1;
                secondary_header_fully_read_r <= '1';
            -- normal operation logic
            elsif data_field_valid_flag_r = '1' then
                octet_counter_r <= octet_counter_r + 1;
                secondary_header_fully_read_r <= '0';
            end if;
        end if;
    end process;

    -- secondary header output process
    with octet_counter_r select secondary_header_s <=
        id_s when 0,
        data_field_r((((octet_counter_r) * 8) - 1) downto ((octet_counter_r - 1) * 8)) when others;

    -- data field input process
    process (input_clk_i, data_field_valid_flag_r, data_field_in_octet_counter_r) begin
        if rising_edge(input_clk_i) then
            if data_field_valid_flag_r = '0' then
                if data_field_in_octet_counter_r = SECONDARY_HEADER_DATA_FIELD_WIDTH_OCTETS then
                    data_field_in_octet_counter_r <= 0;
                elsif data_field_in_octet_counter_r = SECONDARY_HEADER_DATA_FIELD_WIDTH_OCTETS - 1 then
                    data_field_in_octet_counter_r <= data_field_in_octet_counter_r + 1;
                    data_field_valid_flag_r <= '1';
                    data_field_r( ((data_field_in_octet_counter_r * 8) + 7) downto (data_field_in_octet_counter_r * 8) ) <= data_field_i;
                else
                    data_field_in_octet_counter_r <= data_field_in_octet_counter_r + 1;
                    data_field_r( ((data_field_in_octet_counter_r * 8) + 7) downto (data_field_in_octet_counter_r * 8) ) <= data_field_i;
                end if;
            elsif secondary_header_fully_read_r = '1' then
                data_field_valid_flag_r <= '0';
                data_field_in_octet_counter_r <= 0;
            end if;
        end if;
    end process;
end architecture behavioral;