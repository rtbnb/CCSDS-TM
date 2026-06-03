----------------------------------------------------------------
-- File : header_encoder.vhd
-- Created : 26.11.2025
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Primary Header Encoder
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity header_encoder is
	Port(
        transfer_frame_version_number_i: in std_logic_vector(1 downto 0);
        spacecraft_id_i: in std_logic_vector(9 downto 0);
        virtual_channel_id_i: in std_logic_vector(2 downto 0);
        ocf_flag_i: in std_logic;
        master_channel_frame_count_i: in std_logic_vector(7 downto 0);
        virtual_channel_frame_count_i: in std_logic_vector(7 downto 0);
        transfer_frame_secondary_header_flag_i: in std_logic;
        snych_flag_i: in std_logic;
        packet_order_flag_i: in std_logic;
        segment_length_id_i: in std_logic_vector(1 downto 0);
        first_header_pointer_i: in std_logic_vector(10 downto 0);
        is_oid_flag_i: in std_logic;
        header_data_o: out std_logic_vector(47 downto 0)
	);
end entity header_encoder;

architecture behavioral of header_encoder is
begin
    header_data_o(1 downto 0) <= transfer_frame_version_number_i;
    header_data_o(11 downto 2) <= spacecraft_id_i;
    header_data_o(14 downto 12) <= virtual_channel_id_i;
    header_data_o(15) <= ocf_flag_i;
    header_data_o(23 downto 16) <= master_channel_frame_count_i;
    header_data_o(31 downto 24) <= virtual_channel_frame_count_i;
    header_data_o(32) <= transfer_frame_secondary_header_flag_i;
    header_data_o(33) <= snych_flag_i;
    header_data_o(34) <= packet_order_flag_i;
    header_data_o(36 downto 35) <= segment_length_id_i;
    header_data_o(47 downto 37) <= first_header_pointer_i when is_oid_flag_i = '0' else "11111111110";
end architecture behavioral;
