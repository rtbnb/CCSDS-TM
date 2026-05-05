----------------------------------------------------------------
-- File : decoder_buffer_and_structure.vhd
-- Created : 23.04.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Top Level Decoder Entity
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder_buffer_and_structure is
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
        tm_data_field_valid_o: out std_logic
    );
end entity decoder_buffer_and_structure;

architecture behavioral of decoder_buffer_and_structure is
    component header_decoder is
        port (
            header_data_i: in std_logic_vector(47 downto 0);
            is_oid_flag_o: out std_logic;
            transfer_frame_version_number_o: out std_logic_vector(1 downto 0);
            spacecraft_id_o: out std_logic_vector(9 downto 0);
            virtual_channel_id_o: out std_logic_vector(2 downto 0);
            ocf_flag_o: out std_logic;
            master_channel_frame_count_o: out std_logic_vector(7 downto 0);
            virtual_channel_frame_count_o: out std_logic_vector(7 downto 0);
            transfer_frame_secondary_header_flag_o: out std_logic;
            synch_flag_o: out std_logic;
            packet_order_flag_o: out std_logic;
            segment_length_id_o: out std_logic_vector(1 downto 0);
            first_header_pointer_o: out std_logic_vector(10 downto 0)
        );
    end component header_decoder;

    component secondary_header_decoder is
        generic(
            secondary_header_data_field_width_octets_g : integer := 63
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

    component data_decoder is
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
    end component data_decoder;

    -- TM Frame field sizes
    constant TM_FRAME_HEADER_SIZE_OCTET: integer := 6;
    constant TM_FRAME_SECONDARY_HEADER_SIZE_OCTET: integer := 0;
    constant TM_FRAME_DATA_FIELD_SIZE_OCTET: integer := tm_frame_data_size_octet_g;
    constant TM_FRAME_BUFFER_SIZE_OCTET: integer := 2047;

    -- TM Frame buffer
    signal tm_frame_buffer_r: std_logic_vector((TM_FRAME_BUFFER_SIZE_OCTET) * 8 - 1 downto 0);
    --type buffer_selector_t is (buffer_one, buffer_two);
    --signal buffer_selector_r: buffer_selector_t := buffer_one;
    signal tm_frame_buffer_counter_r: integer range 0 to TM_FRAME_BUFFER_SIZE_OCTET - 1 := 0;
    signal tm_frame_buffer_start_index_r: integer range 0 to TM_FRAME_BUFFER_SIZE_OCTET - 1 := 0;
    signal next_tm_frame_buffer_start_index_r: integer range 0 to TM_FRAME_BUFFER_SIZE_OCTET - 1 := 0;
    signal tm_frame_data_field_start_index_s: integer range 0 to TM_FRAME_BUFFER_SIZE_OCTET - 1;
    signal tm_frame_data_field_index_r: integer range 0 to TM_FRAME_DATA_FIELD_SIZE_OCTET - 1 := 0;
    signal tm_frame_data_enable_output_s: boolean := false;
    signal tm_frame_data_finished_output_r: boolean := false;
    signal tm_frame_data_valid_r: boolean := false;
    signal tm_frame_octet_counter_r: integer range 0 to tm_frame_data_size_octet_g + TM_FRAME_HEADER_SIZE_OCTET + TM_FRAME_SECONDARY_HEADER_SIZE_OCTET - 1;

    -- header decoder
    signal header_data_r: std_logic_vector(47 downto 0);
    signal is_oid_flag_s: std_logic;
    signal transfer_frame_version_number_s: std_logic_vector(1 downto 0);
    signal spacecraft_id_s: std_logic_vector(9 downto 0);
    signal virtual_channel_id_s: std_logic_vector(2 downto 0);
    signal ocf_flag_s: std_logic;
    signal master_channel_frame_count_s: std_logic_vector(7 downto 0);
    signal virtual_channel_frame_count_s: std_logic_vector(7 downto 0);
    signal transfer_frame_secondary_header_flag_s: std_logic;
    signal synch_flag_s: std_logic;
    signal packet_order_flag_s: std_logic;
    signal segment_length_id_s: std_logic_vector(1 downto 0);
    signal first_header_pointer_s: std_logic_vector(10 downto 0);

    -- data decoder
    signal dd_data_o_s: std_logic_vector(31 downto 0);
    signal dd_data_valid_o_s: std_logic := '0';
    signal dd_data_fully_read_s: std_logic := '0';
    signal dd_data_i_s: std_logic_vector(7 downto 0);
    signal dd_clk_s: std_logic;
    signal dd_data_valid_i_s: std_logic := '0';
    signal dd_tm_frame_first_header_pointer_s: std_logic_vector(10 downto 0) := (others => '0');
begin
    HD: header_decoder port map (
        header_data_i => header_data_r,
        is_oid_flag_o => is_oid_flag_s,
        transfer_frame_version_number_o => transfer_frame_version_number_s,
        spacecraft_id_o => spacecraft_id_s,
        virtual_channel_id_o => virtual_channel_id_s,
        ocf_flag_o => ocf_flag_s,
        master_channel_frame_count_o => master_channel_frame_count_s,
        virtual_channel_frame_count_o => virtual_channel_frame_count_s,
        transfer_frame_secondary_header_flag_o => transfer_frame_secondary_header_flag_s,
        synch_flag_o => synch_flag_s,
        packet_order_flag_o => packet_order_flag_s,
        segment_length_id_o => segment_length_id_s,
        first_header_pointer_o => first_header_pointer_s
    );

    DD: data_decoder generic map (
        tm_frame_data_size_octet_g => tm_frame_data_size_octet_g
    )
    port map (
        data_o => dd_data_o_s,
        data_valid_o => dd_data_valid_o_s,
        data_fully_read_o => dd_data_fully_read_s,
        data_i => dd_data_i_s,
        clk_i => dd_clk_s,
        data_valid_i => dd_data_valid_i_s,
        tm_frame_first_header_pointer_i => dd_tm_frame_first_header_pointer_s
    );

    tm_frame_data_field_start_index_s <= (tm_frame_buffer_start_index_r + TM_FRAME_HEADER_SIZE_OCTET + TM_FRAME_SECONDARY_HEADER_SIZE_OCTET) mod TM_FRAME_BUFFER_SIZE_OCTET;

    -- input TM Frame to Buffer
    input_tm_frame: process(clk_i) is
    begin
        if rising_edge(clk_i) then
            if data_valid_i = '1' then
                tm_frame_octet_counter_r <= tm_frame_octet_counter_r + 1;
                case state_r is
                    when header =>
                        header_data_r((tm_frame_octet_counter_r + 1) * 8 - 1 downto tm_frame_octet_counter_r * 8) <= data_i;
                        if tm_frame_octet_counter_r = TM_FRAME_HEADER_SIZE_OCTET - 1 then
                            -- TODO implement secondary header logic after MVP
                            if data_i & first_header_pointer_s(2 downto 0)  = "11111111110" then
                                state_r <= data_wait;
                            else
                                state_r <= data;
                            end if;
                        end if;
                    when secondary_header =>
                    when data =>
                        dd_data_i_s <= data_i;
                        dd_data_valid_i_s <= '1';
                        if tm_frame_octet_counter_r = TM_FRAME_HEADER_SIZE_OCTET + TM_FRAME_DATA_FIELD_SIZE_OCTET - 1 then
                            state_r <= header;
                            tm_frame_octet_counter_r <= 0;
                        end if;
                    when data_wait =>
                        dd_data_valid_i_s <= '0';
                        if tm_frame_octet_counter_r = TM_FRAME_HEADER_SIZE_OCTET + TM_FRAME_DATA_FIELD_SIZE_OCTET - 1 then
                            state_r <= header;
                            tm_frame_octet_counter_r <= 0;
                        end if;
                end case;
                tm_frame_octet_counter_r <= tm_frame_octet_counter_r + 1;
            end if;
        end if;
    end process input_tm_frame;

    tm_frame_input_count: process(clk_i) is
    begin
        if rising_edge(clk_i) then
            -- reset data valid after data field transmitted
            if tm_frame_data_finished_output_r then
                tm_frame_data_valid_r <= false;
            end if;
            if data_valid_i = '1' then
                tm_frame_octet_counter_r <= tm_frame_octet_counter_r + 1;
                if tm_frame_octet_counter_r = TM_FRAME_DATA_FIELD_SIZE_OCTET + TM_FRAME_HEADER_SIZE_OCTET + TM_FRAME_SECONDARY_HEADER_SIZE_OCTET - 1 then
                    -- finished buffering full frame
                    -- using next_tm_frame_buffer_start_index because it stores the beginning of the now completely buffered tm frame
                    header_data_r(7 downto 0) <= tm_frame_buffer_r(((next_tm_frame_buffer_start_index_r + 0) mod TM_FRAME_BUFFER_SIZE_OCTET) * 8 + 7 downto ((next_tm_frame_buffer_start_index_r + 0) mod TM_FRAME_BUFFER_SIZE_OCTET) * 8);
                    header_data_r(15 downto 8) <= tm_frame_buffer_r(((next_tm_frame_buffer_start_index_r + 1) mod TM_FRAME_BUFFER_SIZE_OCTET) * 8 + 7 downto ((next_tm_frame_buffer_start_index_r + 1) mod TM_FRAME_BUFFER_SIZE_OCTET) * 8);
                    header_data_r(23 downto 16) <= tm_frame_buffer_r(((next_tm_frame_buffer_start_index_r + 2) mod TM_FRAME_BUFFER_SIZE_OCTET) * 8 + 7 downto ((next_tm_frame_buffer_start_index_r + 2) mod TM_FRAME_BUFFER_SIZE_OCTET) * 8);
                    header_data_r(31 downto 24) <= tm_frame_buffer_r(((next_tm_frame_buffer_start_index_r + 3) mod TM_FRAME_BUFFER_SIZE_OCTET) * 8 + 7 downto ((next_tm_frame_buffer_start_index_r + 3) mod TM_FRAME_BUFFER_SIZE_OCTET) * 8);
                    header_data_r(39 downto 32) <= tm_frame_buffer_r(((next_tm_frame_buffer_start_index_r + 4) mod TM_FRAME_BUFFER_SIZE_OCTET) * 8 + 7 downto ((next_tm_frame_buffer_start_index_r + 4) mod TM_FRAME_BUFFER_SIZE_OCTET) * 8);
                    header_data_r(47 downto 40) <= tm_frame_buffer_r(((next_tm_frame_buffer_start_index_r + 5) mod TM_FRAME_BUFFER_SIZE_OCTET) * 8 + 7 downto ((next_tm_frame_buffer_start_index_r + 5) mod TM_FRAME_BUFFER_SIZE_OCTET) * 8);
                    -- set control signals
                    next_tm_frame_buffer_start_index_r <= (tm_frame_buffer_counter_r + 1) mod TM_FRAME_BUFFER_SIZE_OCTET;
                    tm_frame_buffer_start_index_r <= next_tm_frame_buffer_start_index_r;
                    tm_frame_octet_counter_r <= 0;
                    tm_frame_data_valid_r <= true;
                end if;
            end if;
        end if;
    end process tm_frame_input_count;


    tm_frame_data_enable_output_s <= 
        true when (not tm_frame_data_finished_output_r) and tm_frame_data_valid_r and is_oid_flag_s = '0' else
        false when is_oid_flag_s = '1' else
        false;

    -- to not send half space packets to output you can compare the needed octets (Packet header size) against the remaining length of the tm transfer frame
    -- 1 Tick Reset time required
    output_tm_frame: process(clk_i) is
    begin
        if rising_edge(clk_i) then
            if tm_frame_data_enable_output_s then
                dd_data_i_s <= tm_frame_buffer_r(((tm_frame_data_field_start_index_s + tm_frame_data_field_index_r) mod (TM_FRAME_BUFFER_SIZE_OCTET - 1)) * 8 + 7 downto ((tm_frame_data_field_start_index_s + tm_frame_data_field_index_r) mod (TM_FRAME_BUFFER_SIZE_OCTET - 1)) * 8);
                dd_data_valid_i_s <= '1';
                tm_frame_data_field_index_r <= tm_frame_data_field_index_r + 1;
                if tm_frame_data_field_index_r = TM_FRAME_DATA_FIELD_SIZE_OCTET - 1 then
                    tm_frame_data_field_index_r <= 0;
                    tm_frame_data_finished_output_r <= true;
                end if;
            else
                dd_data_valid_i_s <= '0';
                tm_frame_data_finished_output_r <= false;
            end if;
        end if;
    end process output_tm_frame;
     
    dd_clk_s <= clk_i;

    dd_tm_frame_first_header_pointer_s <= first_header_pointer_s;
    tm_data_field_valid_o <= dd_data_valid_o_s;
    tm_data_field_o <= dd_data_o_s;

end architecture behavioral;