----------------------------------------------------------------
-- File : header_encoder.vhd
-- Created : 26.11.2025
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Primary Header Decoder
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity header_decoder is
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
end entity header_decoder;

architecture behavioral of header_decoder is
begin
    is_oid_flag_o <= '1' when header_data_i(47 downto 37) = "11111111110" else '0';
    transfer_frame_version_number_o <= header_data_i(1 downto 0);
    spacecraft_id_o <= header_data_i(11 downto 2);
    virtual_channel_id_o <= header_data_i(14 downto 12);
    ocf_flag_o <= header_data_i(15);
    master_channel_frame_count_o <= header_data_i(23 downto 16);
    virtual_channel_frame_count_o <= header_data_i(31 downto 24);
    transfer_frame_secondary_header_flag_o <= header_data_i(32);
    synch_flag_o <= header_data_i(33);
    packet_order_flag_o <= header_data_i(34);
    segment_length_id_o <= header_data_i(36 downto 35);
    first_header_pointer_o <= header_data_i(47 downto 37);

end architecture behavioral;