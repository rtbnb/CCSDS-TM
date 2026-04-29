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
        tm_frame_data_size_octet_g: integer := 2040
    );

    port (
        -- outputs
        data_o: out std_logic_vector(31 downto 0); -- to axi stream entity
        data_valid_o: out std_logic := '0';
        data_fully_read_o: out std_logic := '0';

        -- inputs
        data_i: in std_logic_vector(7 downto 0);
        clk_i: in std_logic; -- "8 Bit" x4 clock
        data_valid_i: in std_logic := '0';
        tm_frame_first_header_pointer_i: in std_logic_vector(10 downto 0) := (others => '0')
    );
end entity data_decoder;

architecture behavioral of data_decoder is
    -- constants
    constant OUTPUT_DATA_SIZE_OCTET: integer := 4;
    constant INPUT_DATA_SIZE_OCTET: integer := 2;
    constant PACKET_MAX_SIZE_OCTET: integer := 256;
    constant PACKET_HEADER_SIZE_OCTET: integer := 6;

    -- data
    type packet_state_t is (packet_id_low, packet_id_high, packet_sequence_control_low, packet_sequence_control_high, packet_len_low, packet_len_high, data);
    signal packet_state_r: packet_state_t := packet_id_low;
    signal packet_header_r: std_logic_vector((PACKET_HEADER_SIZE_OCTET * 8) - 1 downto 0) := (others => '0');
    
    
    type deserialization_state_t is (data_first_octet, data_second_octet, data_third_octet, data_fourth_octet, data_first_octet_previous_add);
    signal state_r: deserialization_state_t := data_first_octet;
    signal data_buffer_r: std_logic_vector(31 downto 0);
    signal packet_data_len_r: std_logic_vector(15 downto 0);
    signal packet_last_cycle_valid_r: std_logic := '1';
    signal packet_valid_r: std_logic := '0';

    signal packet_apid_r: std_logic_vector(10 downto 0);
    signal packet_apid_valid_r: std_logic := '0';

    signal previous_octet_r: std_logic_vector(7 downto 0);
    signal previous_octet_from_fourth_r: std_logic_vector(7 downto 0);

    signal tm_data_field_octet_counter_r: integer range 0 to tm_frame_data_size_octet_g - 1 := 0;
    signal is_packet_extraction_r: std_logic := '0';

    function packet_length_int(packet_len: std_logic_vector(15 downto 0)) return integer is
        variable packet_len_int: integer range 1 to PACKET_MAX_SIZE_OCTET;
    begin
        packet_len_int := to_integer(unsigned(packet_len));
        return packet_len_int;
    end function;
    
begin
    packet_header: process(clk_i)
    variable packet_data_field_octet_counter: integer range 0 to PACKET_MAX_SIZE_OCTET - 1 := 0;
    begin
        if rising_edge(clk_i) then
            if data_valid_i = '1' then
                tm_data_field_octet_counter_r <= tm_data_field_octet_counter_r + 1;
                case packet_state_r is
                    when packet_id_low =>
                        if tm_data_field_octet_counter_r >= to_integer(unsigned(tm_frame_first_header_pointer_i)) then
                            packet_apid_valid_r <= '0';
                            packet_apid_r(2 downto 0) <= data_i(7 downto 5);
                            previous_octet_r <= data_i;
                            packet_state_r <= packet_id_high;
                            packet_apid_valid_r <= '1';
                        end if;
                    when packet_id_high =>
                        packet_apid_r(10 downto 3) <= data_i;
                        packet_state_r <= packet_sequence_control_low;
                        -- packet_apid_valid_r <= '1';
                    when packet_sequence_control_low =>
                        packet_state_r <= packet_sequence_control_high;
                    when packet_sequence_control_high =>
                        packet_state_r <= packet_len_low;
                    when packet_len_low =>
                        packet_data_len_r(15 downto 8) <= data_i;
                        packet_state_r <= packet_len_high;
                    when packet_len_high =>
                        packet_data_len_r(7 downto 0) <= data_i;
                        packet_state_r <= data;
                    when data =>
                        if (packet_length_int(packet_len => packet_data_len_r) - packet_data_field_octet_counter) = INPUT_DATA_SIZE_OCTET then
                            packet_state_r <= packet_id_low;
                            packet_data_field_octet_counter := 0;
                        else
                            packet_data_field_octet_counter := packet_data_field_octet_counter + 1;
                            packet_state_r <= data;
                        end if;
                end case;
                if tm_data_field_octet_counter_r = tm_frame_data_size_octet_g - 1 then 
                    tm_data_field_octet_counter_r <= 0;
                end if;
            end if;
        end if;
    end process packet_header;

    packet_valid_r <= '0' when (packet_apid_valid_r = '1') and (packet_apid_r = "11111111111") else
                      '1' when (packet_apid_valid_r = '1') else
                      '0';

    data_output: process(clk_i, packet_valid_r, packet_last_cycle_valid_r)
    begin
        if rising_edge(clk_i) then
            if (data_valid_i = '1') then
                case state_r is
                    when data_first_octet =>
                        data_valid_o <= '0';
                        data_buffer_r(7 downto 0) <= data_i;
                        state_r <= data_second_octet;
                    when data_second_octet =>
                        data_buffer_r(15 downto 8) <= data_i;
                        state_r <= data_third_octet;
                    when data_third_octet =>
                        data_buffer_r(23 downto 16) <= data_i;
                        state_r <= data_fourth_octet;
                    when data_fourth_octet =>
                        data_valid_o <= '1';
                        data_buffer_r(31 downto 24) <= data_i;
                        state_r <= data_first_octet;
                    when data_first_octet_previous_add =>
                        data_valid_o <= '0';
                        data_buffer_r(7 downto 0) <= data_i;
                        state_r <= data_second_octet;
                end case;
            end if;
            --if packet_valid_r = '1' then
            --    if packet_last_cycle_valid_r = '0' then
            --        packet_last_cycle_valid_r <= '1';
            --        case state_r is
            --            when data_first_octet =>
            --                data_valid_o <= '0';
            --                data_buffer_r(7 downto 0) <= previous_octet_r;
            --                data_buffer_r(15 downto 8) <= data_i;
            --                state_r <= data_third_octet;
            --            when data_second_octet =>
            --                data_buffer_r(15 downto 8) <= previous_octet_r;
            --                data_buffer_r(23 downto 16) <= data_i;
            --                state_r <= data_fourth_octet;
            --            when data_third_octet =>
            --                data_buffer_r(23 downto 16) <= previous_octet_r;
            --                data_buffer_r(31 downto 24) <= data_i;
            --                state_r <= data_first_octet;
            --            when data_fourth_octet =>
            --                data_valid_o <= '1';
            --                data_buffer_r(31 downto 24) <= previous_octet_r;
            --                previous_octet_from_fourth_r <= data_i;
            --                state_r <= data_first_octet_previous_add;
            --                packet_last_cycle_valid_r <= '0'; --packet_last_cycle_valid_r <= '0';
            --            when data_first_octet_previous_add =>
            --                data_valid_o <= '0';
            --                data_buffer_r(7 downto 0) <= previous_octet_from_fourth_r;
            --                data_buffer_r(15 downto 8) <= data_i;
            --                state_r <= data_third_octet;
            --        end case;
            --    else
            --        case state_r is
            --            when data_first_octet =>
            --                data_valid_o <= '0';
            --                data_buffer_r(7 downto 0) <= data_i;
            --                state_r <= data_second_octet;
            --            when data_second_octet =>
            --                data_buffer_r(15 downto 8) <= data_i;
            --                state_r <= data_third_octet;
            --            when data_third_octet =>
            --                data_buffer_r(23 downto 16) <= data_i;
            --                state_r <= data_fourth_octet;
            --            when data_fourth_octet =>
            --                data_valid_o <= '1';
            --                data_buffer_r(31 downto 24) <= data_i;
            --                state_r <= data_first_octet;
            --            when data_first_octet_previous_add =>
            --                data_valid_o <= '0';
            --                data_buffer_r(7 downto 0) <= data_i;
            --                state_r <= data_second_octet;
            --        end case;
            --        packet_last_cycle_valid_r <= '1';
            --    end if;
            --else
            --    packet_last_cycle_valid_r <= '1';-- packet_last_cycle_valid_r <= '0';
            --    data_valid_o <= '0';
            --end if;
        end if;
    end process data_output;

    data_o <= data_buffer_r;

end architecture behavioral;