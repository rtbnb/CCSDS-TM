----------------------------------------------------------------
-- File : data_encoder.vhd
-- Created : 03.04.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Data Decoder
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
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
        rdy_o: out std_logic := '1';

        packet_header_err_o: out std_logic := '0';

        -- inputs
        data_i: in std_logic_vector(7 downto 0);
        clk_i: in std_logic; -- "8 Bit" x4 clock
        data_valid_i: in std_logic := '0';
        tm_frame_first_header_pointer_i: in std_logic_vector(10 downto 0) := (others => '0');
        new_frame_i: in std_logic := '0';
        reset_i: in std_logic
    );
end entity data_decoder;

architecture behavioral of data_decoder is
    component space_packet_decoder is
        port (
            header_data_i: in std_logic_vector(47 downto 0);
            packet_version_number_o: out std_logic_vector(2 downto 0);
            packet_type_o: out std_logic;
            secondary_header_flag_o: out std_logic;
            application_process_identifier_o: out std_logic_vector(10 downto 0);
            sequence_flags_o: out std_logic_vector(1 downto 0);
            packet_sequence_count_o: out std_logic_vector(13 downto 0);
            packet_length_o: out std_logic_vector(15 downto 0)
        );
    end component space_packet_decoder;
    
    -- constants
    constant OUTPUT_DATA_SIZE_OCTET: integer := 4;
    constant PACKET_MAX_SIZE_OCTET: integer := 256;
    constant PACKET_HEADER_SIZE_OCTET: integer := 6;

    -- data
    type packet_state_t is (packet_header, packet_data, packet_idle, packet_output);
    signal packet_state_r: packet_state_t := packet_header;
    type packet_t is array (PACKET_MAX_SIZE_OCTET - 1 downto 0) of std_logic_vector(7 downto 0);
    signal packet_data_r: packet_t := (others => (others => '0'));

    -- data input
    signal input_octet_counter_r: integer range 0 to PACKET_MAX_SIZE_OCTET - 1 := 0;
    signal packet_data_size_octet_s: integer range 0 to PACKET_MAX_SIZE_OCTET := 0;
    signal packet_input_valid_s: boolean := false;
    signal packet_input_en_r: boolean := true;
    signal packet_length_s: integer range 0 to PACKET_MAX_SIZE_OCTET := 0;
    signal first_header_point_packet_size_s: integer range 0 to PACKET_MAX_SIZE_OCTET := 0;
    signal use_first_header_pointer_size_s: boolean := false;

    -- data output
    signal packet_output_en_r: boolean := false;
    signal output_octet_counter_r: integer range 0 to PACKET_MAX_SIZE_OCTET - 1 := 0;
    signal output_word_octet_counter_r: integer range 0 to OUTPUT_DATA_SIZE_OCTET - 1 := 0;
    signal data_buffer_r: std_logic_vector(OUTPUT_DATA_SIZE_OCTET * 8 - 1 downto 0) := (others => '0');
    signal outputing_packet_r: boolean := false;

    -- space packet decoder
    signal packet_version_number_s: std_logic_vector(2 downto 0);
    signal packet_type_s: std_logic;
    signal secondary_header_flag_s: std_logic;
    signal application_process_identifier_s: std_logic_vector(10 downto 0);
    signal sequence_flags_s: std_logic_vector(1 downto 0);
    signal packet_sequence_count_s: std_logic_vector(13 downto 0);
    signal header_packet_length_s: std_logic_vector(15 downto 0);
    signal header_data_s: std_logic_vector(47 downto 0);
    
begin

    space_packet_decoder_inst: space_packet_decoder port map (
        header_data_i => header_data_s,
        packet_version_number_o => packet_version_number_s,
        packet_type_o => packet_type_s,
        secondary_header_flag_o => secondary_header_flag_s,
        application_process_identifier_o => application_process_identifier_s,
        sequence_flags_o => sequence_flags_s,
        packet_sequence_count_o => packet_sequence_count_s,
        packet_length_o => header_packet_length_s
    );

    packet_input_valid_s <= 
        true when (data_valid_i = '1') and (packet_input_en_r = true) else
        false;

    header_data_s(7 downto 0) <= packet_data_r(0);
    header_data_s(15 downto 8) <= packet_data_r(1);
    header_data_s(23 downto 16) <= packet_data_r(2);
    header_data_s(31 downto 24) <= packet_data_r(3);
    header_data_s(39 downto 32) <= packet_data_r(4);
    header_data_s(47 downto 40) <= packet_data_r(5);

    input_data: process(clk_i) is
    begin
        if (reset_i = '0') then
            input_octet_counter_r <= 0;
            packet_state_r <= packet_header;
            packet_output_en_r <= false;
        else
            if rising_edge(clk_i) then
                data_valid_o <= '0';
                case packet_state_r is
                    when packet_header =>
                        rdy_o <= '1';
                        if data_valid_i = '1' then
                            use_first_header_pointer_size_s <= false;
                            if new_frame_i = '1' then
                                if to_integer(unsigned(tm_frame_first_header_pointer_i)) = 0 then
                                    packet_state_r <= packet_header;
                                else
                                    -- if new frame present, compare first header pointer with remaining length -> mismatch -> discard data until next packet header
                                    first_header_point_packet_size_s <= to_integer(unsigned(tm_frame_first_header_pointer_i)) + input_octet_counter_r;
                                    use_first_header_pointer_size_s <= true;
                                    packet_state_r <= packet_data;
                                end if;
                            end if;
                            input_octet_counter_r <= input_octet_counter_r + 1;
                            packet_output_en_r <= false;
                            packet_data_r(input_octet_counter_r) <= data_i;
                            if input_octet_counter_r = PACKET_HEADER_SIZE_OCTET - 1 then
                                if application_process_identifier_s = "11111111111" then
                                    -- idle packet, do not extract data, wait for next packet header
                                    packet_state_r <= packet_idle;
                                else
                                    packet_state_r <= packet_data;
                                end if;
                            end if;
                        end if;
                    when packet_data =>
                        rdy_o <= '1';
                        if data_valid_i = '1' then
                            if new_frame_i = '1' then
                                -- if new frame present, compare first header pointer with remaining length -> mismatch -> discard data until next packet header
                                if to_integer(unsigned(tm_frame_first_header_pointer_i)) = ((PACKET_HEADER_SIZE_OCTET + packet_data_size_octet_s) - input_octet_counter_r) then
                                    packet_state_r <= packet_data;
                                else
                                    first_header_point_packet_size_s <= to_integer(unsigned(tm_frame_first_header_pointer_i)) + input_octet_counter_r;
                                    use_first_header_pointer_size_s <= true;
                                    packet_state_r <= packet_idle;
                                end if;
                            end if;
                            input_octet_counter_r <= input_octet_counter_r + 1;
                            packet_data_r(input_octet_counter_r) <= data_i;
                            if input_octet_counter_r = (PACKET_HEADER_SIZE_OCTET + packet_data_size_octet_s) - 2 then
                                rdy_o <= '0';
                            end if;
                            if input_octet_counter_r = (PACKET_HEADER_SIZE_OCTET + packet_data_size_octet_s) - 1 then
                                rdy_o <= '0';
                                packet_state_r <= packet_output;
                                input_octet_counter_r <= 0;
                                packet_output_en_r <= true;
                            end if;
                        end if;
                    when packet_idle =>
                        rdy_o <= '1';
                        if data_valid_i = '1' then
                            input_octet_counter_r <= input_octet_counter_r + 1;
                            if input_octet_counter_r = (PACKET_HEADER_SIZE_OCTET + packet_data_size_octet_s) - 2 then
                                rdy_o <= '0';
                            end if;
                            if input_octet_counter_r = (PACKET_HEADER_SIZE_OCTET + packet_data_size_octet_s) - 1 then
                                rdy_o <= '0';
                                packet_state_r <= packet_header;
                                input_octet_counter_r <= 0;
                                packet_output_en_r <= false;
                            end if;
                        end if;
                    when packet_output =>
                        rdy_o <= '0';
                        data_buffer_r((output_word_octet_counter_r * 8) + 7 downto (output_word_octet_counter_r * 8)) <= packet_data_r(output_octet_counter_r);
                        -- count packet buffer octets
                        if output_octet_counter_r = (PACKET_HEADER_SIZE_OCTET + packet_data_size_octet_s) - 1 then
                            -- finished outputting packet, wait for next packet
                            packet_state_r <= packet_header;
                            output_octet_counter_r <= 0;
                        else
                            output_octet_counter_r <= output_octet_counter_r + 1;
                        end if;
                        -- count output buffer octets
                        if output_word_octet_counter_r = OUTPUT_DATA_SIZE_OCTET - 1 then
                            output_word_octet_counter_r <= 0;
                            data_valid_o <= '1';
                        else
                            output_word_octet_counter_r <= output_word_octet_counter_r + 1;
                            data_valid_o <= '0';
                        end if;
                end case;
            end if;
        end if;
    end process input_data;

    packet_length_s <= 
        to_integer(unsigned(header_packet_length_s)) + 1 when use_first_header_pointer_size_s = false else -- packet length in header is packet data size - 1, so add 1 to get actual packet data size
        first_header_point_packet_size_s;
    packet_size_calculation: process(packet_length_s)
    begin
        if packet_length_s < PACKET_MAX_SIZE_OCTET - PACKET_HEADER_SIZE_OCTET then
            packet_data_size_octet_s <= packet_length_s;
            packet_header_err_o <= '0';
        else
            packet_data_size_octet_s <= PACKET_MAX_SIZE_OCTET - PACKET_HEADER_SIZE_OCTET;
            packet_header_err_o <= '1';
        end if;
    end process packet_size_calculation;

    data_o <= 
        x"00000000" when reset_i = '0' 
        else data_buffer_r;

end architecture behavioral;