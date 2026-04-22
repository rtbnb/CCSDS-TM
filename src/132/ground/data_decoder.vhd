----------------------------------------------------------------
-- File : data_encoder.vhd
-- Created : 03.04.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Data Decoder
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_decoder is
    generic (
        tm_frame_data_size_octet_g: integer := 2040;
    );

    port (
        -- outputs
        data_o: out std_logic_vector(31 downto 0); -- to axi stream entity
        data_valid_o: out std_logic _= '0';
        date_fully_read_o: out std_logic := '0';

        -- inputs
        data_i: in std_logic_vector(15 downto 0);
        data_clk_i: in std_logic -- "16 Bit" clock
        data_valid_i: in std_logic := '0';
    );
end entity data_decoder;

architecture behavioral of data_decoder is
    -- constants
    constant OUTPUT_DATA_SIZE_OCTET: integer := 4;
    constant INPUT_DATA_SIZE_OCTET: integer := 2;
    constant PACKET_MAX_SIZE_OCTET: integer := 256;

    -- data
    -- signal data_one_r: std_logic_vector(PACKET_MAX_SIZE_OCTET - 1 downto 0); -- storage for one space packet
    -- signal data_two_r: std_logic_vector(PACKET_MAX_SIZE_OCTET - 1 downto 0);
    -- type data_select_enum_t is (data_one, data_two);
    -- signal data_buffer_select_r: data_select_enum_t := data_one;
    type packet_state_t is (packet_id, packet_sequence_control, packet_len, data, packet_id_odd, packet_sequence_control_odd, packet_len_odd);
    signal packet_state_r: packet_state_t := packet_id;
    signal packet_header_r: std_logic_vector((6 * 8) - 1 downto 0) := (others => '0');
    
    
    type deserialization_state_t is (data_low_word, data_high_word);
    signal state_s: deserialization_state_t := data_low_word;
    signal data_buffer_r: std_logic_vector(31 downto 0);
    signal packet_size_octet_r: integer range 1 to PACKET_MAX_SIZE_OCTET;
    signal packet_valid_r: std_logic := '1';
    signal packet_apid_r: std_logic_vector(10 downto 0);
    
begin 

    packet_header: process(data_clk_i)
    variable packet_data_field_octet_counter: integer range 0 to PACKET_MAX_SIZE_OCTET - 1 := 0;
    variable packet_odd_size_field: std_logic_vector(15 downto 0);
    begin
        if rising_edge(data_clk_i) then
            case packet_state_r is
                when packet_id =>
                    packet_apid_r <= data_i(15 downto 5);
                    packet_state_r <= packet_sequence_control;
                when packet_sequence_control =>
                    packet_state_r <= packet_len;
                when packet_len =>
                    packet_size_octet_r <= to_integer(unsigned(data_i)) + 1; -- value of 0 is a data field size of 1
                    packet_state_r <= data;
                when data =>
                    if (packet_size_octet_r - packet_data_field_octet_counter) = INPUT_DATA_SIZE_OCTET then
                        -- even number packet end
                        packet_state_r <= packet_id;
                        packet_data_field_octet_counter <= 0;
                    elsif (packet_size_octet_r - packet_data_field_octet_counter) = (INPUT_DATA_SIZE_OCTET - 1) then
                        -- odd number packet end
                        packet_apid_r(2 downto 0) <= data_i(15 downto 13);
                        packet_data_field_octet_counter <= 0;
                    else
                        packet_data_field_octet_counter <= packet_data_field_octet_counter + INPUT_DATA_SIZE_OCTET;
                    end if;
                when packet_id_odd =>
                    packet_apid_r(10 downto 3) <= data_i(7 downto 0);
                    packet_state_r <= packet_sequence_control_odd;
                when packet_sequence_control_odd =>
                    packet_odd_size_field(7 downto 0) <= data_i(15 downto 8);
                when packet_len_odd =>
                    packet_size_octet_r <= to_integer(unsigned(packet_odd_size_field(7 downto 0) & data_i(7 downto 0))) + 1;
                    packet_data_field_octet_counter <= 1;
                    packet_state_r <= data;
            end case;
        end if;
    end process packet_header;

    with packet_apid_r select packet_valid_r <=
        '0' when '11111111111',
        '1' when others;

    data_output: process(data_clk_i, packet_valid_r)
    begin
        if rising_edge(data_clk_i) then
            if packet_valid_r then
                case state_s is
                    when data_low_word =>
                        data_valid_o <= '0';
                        data_buffer_r(15 downto 0) <= data_i;
                    when data_high_word =>
                        data_valid_o <= '1';
                        data_buffer_r(31 downto 16) <= data_i;
                end case;
            end if;
        end if;

    end process data_output;

end architecture behavioral;