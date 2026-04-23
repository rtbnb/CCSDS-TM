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
        tm_data_field_valid_o: out std_logic;
    );
end entity decoder_buffer_and_structure;

architecture behavioral of decoder_buffer_and_structure is
    component header_decoder is
        port (
            data_i: in std_logic_vector(47 downto 0);
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
            first_header_pointer_o: out std_logic_vector(10 downto 0);
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
            data_valid_i: in std_logic := '0'
            tm_frame_first_header_pointer_i: in std_logic_vector(10 downto 0) := (others => '0');
        );
    end component data_decoder;

    -- TM Frame field sizes
    constant TM_FRAME_HEADER_SIZE_OCTET: integer := 6;
    constant TM_FRAME_SECONDARY_HEADER_SIZE_OCTET: integer := 0;
    constant TM_FRAME_DATA_FIELD_SIZE_OCTET: integer := 2040;

    -- state machine
    type state_t is (header, secondary_header, data, data_wait);
    signal state_r: state_t := header;

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
    signal dd_data_valid_i_s: std_logic := '0'
    signal dd_tm_frame_first_header_pointer_s: std_logic_vector(10 downto 0) := (others => '0');
begin
    HD: header_decoder port map (
        data_i => header_data_r,
        is_oid_flag_o => is_oid_flag_s,
        transfer_frame_version_number_o => transfer_frame_version_number_s,
        spacecraft_id_o => spacecraft_id_s,
        virtual_channel_id_o => virtual_channel_id_s,
        ocf_flag_o => ocf_flag_s,
        master_channel_frame_count_0 => master_channel_frame_count_s,
        virtual_channel_frame_count_0 => virtual_channel_frame_count_s,
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

    state_machine: process(clk_i) is
    begin
        if rising_edge(clk_i) then
            dd_data_valid_i_s <= '0';
            if data_valid_i = '1' then
                tm_frame_octet_counter_r <= tm_frame_octet_counter_r + 1;
                case state_r is
                    when header =>
                        header_data_i((tm_frame_octet_counter_r + 1) * 8 - 1 downto tm_frame_octet_counter_r * 8) <= data_i;
                        if tm_frame_octet_counter_r = TM_FRAME_HEADER_SIZE_OCTET - 1 then
                            -- TODO implement secondary header logic after MVP
                            if first_header_pointer_s = "11111111110" then
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
            end if;
        end if;
    end process state_machine;

    dd_tm_frame_first_header_pointer_s <= first_header_pointer_s;
    tm_data_field_valid_o <= dd_data_valid_o_s;

end architecture behavioral;