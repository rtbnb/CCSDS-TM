----------------------------------------------------------------
-- File : space_packet_decoder.vhd
-- Created : 06.05.2026
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : CCSDS 133.0-B-2 Space Packet Primary Header Decoder
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity space_packet_decoder is
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
end entity space_packet_decoder;

architecture behavioral of space_packet_decoder is
begin
    packet_version_number_o <= header_data_i(2 downto 0); -- bits 2 - 0
    packet_type_o <= header_data_i(3); -- bit 4
    secondary_header_flag_o <= header_data_i(4); -- bit 5
    application_process_identifier_o <= header_data_i(15 downto 5);
    sequence_flags_o <= header_data_i(17 downto 16);
    packet_sequence_count_o <= header_data_i(31 downto 18);
    packet_length_o <= header_data_i(47 downto 32);

end architecture behavioral;