----------------------------------------------------------------
-- File : space_packet_encoder.vhd
-- Created : 28.06.2026
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : CCSDS 133.0-B-2 Space Packet Primary Header Encoder
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity space_packet_encoder is
    port (
        packet_version_number_i: in std_logic_vector(2 downto 0);
        packet_type_i: in std_logic;
        secondary_header_flag_i: in std_logic;
        application_process_identifier_i: in std_logic_vector(10 downto 0);
        sequence_flags_i: in std_logic_vector(1 downto 0);
        packet_sequence_count_i: in std_logic_vector(13 downto 0);
        packet_length_i: in std_logic_vector(15 downto 0);
        
        header_data_o: out std_logic_vector(47 downto 0)        
    );
end entity space_packet_encoder;

architecture behavioral of space_packet_encoder is
begin
    header_data_o(2 downto 0) <= packet_version_number_i; -- bits 2 - 0
    header_data_o(3) <= packet_type_i; -- bit 4
    header_data_o(4) <= secondary_header_flag_i; -- bit 5
    header_data_o(15 downto 5) <= application_process_identifier_i;
    header_data_o(17 downto 16) <= sequence_flags_i;
    header_data_o(31 downto 18) <= packet_sequence_count_i;
    header_data_o(47 downto 32) <= packet_length_i;

end architecture behavioral;