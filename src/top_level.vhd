library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
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
        header_data_o: out std_logic_vector(47 downto 0)
	);
end entity top_level;

architecture behavioral of top_level is
    component header_encoder is
        port(
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
            header_data_o: out std_logic_vector(47 downto 0)
        );
    end component;
begin
    encoder1: header_encoder port map(
        transfer_frame_version_number_i => transfer_frame_version_number_i,
        spacecraft_id_i => spacecraft_id_i,
        virtual_channel_id_i => virtual_channel_id_i,
        ocf_flag_i => ocf_flag_i,
        master_channel_frame_count_i => master_channel_frame_count_i,
        virtual_channel_frame_count_i => virtual_channel_frame_count_i,
        transfer_frame_secondary_header_flag_i => transfer_frame_secondary_header_flag_i,
        snych_flag_i => snych_flag_i,
        packet_order_flag_i => packet_order_flag_i,
        segment_length_id_i => segment_length_id_i,
        first_header_pointer_i => first_header_pointer_i,
        header_data_o => header_data_o
    );
end architecture behavioral;
