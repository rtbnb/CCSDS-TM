----------------------------------------------------------------
-- File : decoder_buffer_and_structure.vhd
-- Created : 23.04.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 TM Frame Buffer
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder_buffer_and_structure is
    generic (
        TM_FRAME_SIZE_OCTET: integer := 2046;
        FECF_ENB: boolean := false
    );
    port (
        -- inputs
        data_i: std_logic_vector(7 downto 0);
        clk_i: std_logic;
        reset_i: std_logic;
        fifo_empty_i: std_logic;
        master_channel_demux_rdy_i: std_logic;

        -- outputs
        tm_frame_first_header_pointer_o: out std_logic_vector(10 downto 0);
        new_frame_o: out std_logic;
        master_channel_id_o: out std_logic_vector(11 downto 0);
        virtual_channel_id_o: out std_logic_vector(2 downto 0);
        
        space_packet_data_o: out std_logic_vector(7 downto 0);
        space_packet_data_valid_o: out std_logic;
        rdy_o: out std_logic := '0'
    );
end entity decoder_buffer_and_structure;

architecture behavioral of decoder_buffer_and_structure is
    component header_decoder is
        port (
            reset_i: in std_logic;
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

    -- TM Frame field sizes
    constant TM_FRAME_HEADER_SIZE_OCTET: integer := 6;
    constant TM_FRAME_SECONDARY_HEADER_SIZE_OCTET: integer := 0;
    constant TM_FRAME_DATA_FIELD_SIZE_OCTET: integer := TM_FRAME_SIZE_OCTET - TM_FRAME_HEADER_SIZE_OCTET - TM_FRAME_SECONDARY_HEADER_SIZE_OCTET;
    constant TM_FRAME_BUFFER_SIZE_OCTET: integer := TM_FRAME_SIZE_OCTET;

    -- TM Frame buffer
    type buffer_mem_t is array (0 to TM_FRAME_BUFFER_SIZE_OCTET - 1) of std_logic_vector(7 downto 0);
    signal tm_frame_buffer_r: buffer_mem_t := (others => (others => '0'));
    signal tm_frame_buffer_start_index_r: integer range 0 to TM_FRAME_BUFFER_SIZE_OCTET - 1 := 0;
    signal next_tm_frame_buffer_start_index_r: integer range 0 to TM_FRAME_BUFFER_SIZE_OCTET - 1 := 0;
    signal tm_frame_data_field_start_index_s: integer range 0 to TM_FRAME_BUFFER_SIZE_OCTET - 1;
    signal tm_frame_data_field_index_r: integer range 0 to TM_FRAME_DATA_FIELD_SIZE_OCTET - 1 := 0;
    signal tm_frame_data_enable_output_s: boolean := false;
    signal tm_frame_data_finished_output_r: boolean := false;
    signal tm_frame_data_valid_r: boolean := false;
    signal tm_frame_octet_counter_r: integer range 0 to TM_FRAME_SIZE_OCTET - 1 := 0;
    type output_state_t is (output_idle, output_packet_data);
    signal output_state_r: output_state_t := output_packet_data;
    signal input_data_valid_r: std_logic := '0';
    signal rdy_en_s: std_logic := '0';

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

    -- space packet processing
    signal space_packet_data_r: std_logic_vector(7 downto 0);
    signal space_packet_data_valid_r: std_logic;

    -- trailer handling
    signal trailer_size_s: integer := 0;

    -- operational control field (ocf) handling
    constant OCF_SIZE_OCTETS: integer := 4 * 8;

    -- frame error control field (fecf) handling
    constant FECF_SIZE_OCTETS: integer := 2 * 8;

begin
    HD: header_decoder port map (
        reset_i => reset_i,
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

    master_channel_id_o(1 downto 0) <= transfer_frame_version_number_s;
    master_channel_id_o(11 downto 2) <= spacecraft_id_s;
    virtual_channel_id_o <= virtual_channel_id_s;

    input_valid: process(clk_i) is
    begin
        if (reset_i = '0') then
            input_data_valid_r <= '0';
        else
            if rising_edge(clk_i) then
                input_data_valid_r <= (not fifo_empty_i) and rdy_en_s;
            end if;
        end if;
    end process input_valid;

    tm_frame_data_field_start_index_s <= (tm_frame_buffer_start_index_r + TM_FRAME_HEADER_SIZE_OCTET + TM_FRAME_SECONDARY_HEADER_SIZE_OCTET) mod TM_FRAME_BUFFER_SIZE_OCTET;

    tm_frame_header_decode: process(clk_i) is
    begin
        if (reset_i = '0') then
            tm_frame_data_valid_r <= false;
            tm_frame_octet_counter_r <= 0;
            next_tm_frame_buffer_start_index_r <= 0;
        else
            if rising_edge(clk_i) then
                -- reset data valid after data field transmitted
                if tm_frame_data_finished_output_r then
                    tm_frame_data_valid_r <= false;
                end if;
                if input_data_valid_r = '1' then
                    tm_frame_buffer_r(tm_frame_octet_counter_r) <= data_i;
                    tm_frame_octet_counter_r <= tm_frame_octet_counter_r + 1;
                    if tm_frame_octet_counter_r = TM_FRAME_DATA_FIELD_SIZE_OCTET + TM_FRAME_HEADER_SIZE_OCTET + TM_FRAME_SECONDARY_HEADER_SIZE_OCTET - 1 then
                        -- finished buffering full frame
                        -- using next_tm_frame_buffer_start_index because it stores the beginning of the now completely buffered tm frame
                        header_data_r(7 downto 0) <= tm_frame_buffer_r(((next_tm_frame_buffer_start_index_r + 0) mod TM_FRAME_BUFFER_SIZE_OCTET));
                        header_data_r(15 downto 8) <= tm_frame_buffer_r(((next_tm_frame_buffer_start_index_r + 1) mod TM_FRAME_BUFFER_SIZE_OCTET));
                        header_data_r(23 downto 16) <= tm_frame_buffer_r(((next_tm_frame_buffer_start_index_r + 2) mod TM_FRAME_BUFFER_SIZE_OCTET));
                        header_data_r(31 downto 24) <= tm_frame_buffer_r(((next_tm_frame_buffer_start_index_r + 3) mod TM_FRAME_BUFFER_SIZE_OCTET));
                        header_data_r(39 downto 32) <= tm_frame_buffer_r(((next_tm_frame_buffer_start_index_r + 4) mod TM_FRAME_BUFFER_SIZE_OCTET));
                        header_data_r(47 downto 40) <= tm_frame_buffer_r(((next_tm_frame_buffer_start_index_r + 5) mod TM_FRAME_BUFFER_SIZE_OCTET));
                        -- set control signals
                        next_tm_frame_buffer_start_index_r <= (tm_frame_octet_counter_r + 1) mod TM_FRAME_BUFFER_SIZE_OCTET;
                        tm_frame_buffer_start_index_r <= next_tm_frame_buffer_start_index_r;
                        tm_frame_octet_counter_r <= 0;
                        tm_frame_data_valid_r <= true;
                    end if;
                end if;
            end if;
        end if;
    end process tm_frame_header_decode;

    rdy_o <= rdy_en_s;
    rdy_en_s <=
        '0' when reset_i = '0' else
        '1' when master_channel_demux_rdy_i = '1' else
        '0';


    tm_frame_data_enable_output_s <= 
        false when reset_i = '0' else
        true when (not tm_frame_data_finished_output_r) and tm_frame_data_valid_r and is_oid_flag_s = '0' and master_channel_demux_rdy_i = '1' else
        false when is_oid_flag_s = '1' else
        false;

    trailer_size_s <=
        OCF_SIZE_OCTETS + FECF_SIZE_OCTETS when ocf_flag_s = '1' and FECF_ENB else
        FECF_SIZE_OCTETS when FECF_ENB else
        OCF_SIZE_OCTETS when ocf_flag_s = '1' else
        0;

    -- to not send half space packets to output you can compare the needed octets (Packet header size) against the remaining length of the tm transfer frame
    -- 1 Tick Reset time required
    output_tm_frame: process(clk_i) is
    begin
        if (reset_i = '0') then
            space_packet_data_valid_r <= '0';
            tm_frame_data_finished_output_r <= false;
            tm_frame_data_field_index_r <= 0;
            output_state_r <= output_idle;
            tm_frame_first_header_pointer_o <= (others => '0');
            new_frame_o <= '0';
        else
            if rising_edge(clk_i) then
                new_frame_o <= '0';
                case output_state_r is
                    when output_idle =>
                        space_packet_data_valid_r <= '0';
                        tm_frame_data_finished_output_r <= false;
                        if tm_frame_data_enable_output_s then
                            if synch_flag_s = '0' then
                                    tm_frame_first_header_pointer_o <= first_header_pointer_s;
                                    new_frame_o <= '1';
                                else
                                    tm_frame_first_header_pointer_o <= (others => '0');
                                    new_frame_o <= '0';
                                end if;
                            output_state_r <= output_packet_data;
                        end if;
                    when output_packet_data =>
                        if tm_frame_data_enable_output_s then                                
                            space_packet_data_r <= tm_frame_buffer_r(((tm_frame_data_field_start_index_s + tm_frame_data_field_index_r) mod (TM_FRAME_BUFFER_SIZE_OCTET)));
                            space_packet_data_valid_r <= '1';
                            tm_frame_data_field_index_r <= tm_frame_data_field_index_r + 1;
                            if tm_frame_data_field_index_r = (TM_FRAME_DATA_FIELD_SIZE_OCTET - trailer_size_s) - 1 then
                                tm_frame_data_field_index_r <= 0;
                                tm_frame_data_finished_output_r <= true;
                                output_state_r <= output_idle;
                            end if;
                        else
                            space_packet_data_valid_r <= '0';
                            tm_frame_data_finished_output_r <= false;
                        end if;
                end case;
            end if;
        end if;
    end process output_tm_frame;

    space_packet_data_valid_o <= 
        '0' when reset_i = '0' else
        space_packet_data_valid_r;
    space_packet_data_o <= 
        x"00" when reset_i = '0' else
        space_packet_data_r;

end architecture behavioral;