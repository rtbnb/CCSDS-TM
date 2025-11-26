----------------------------------------------------------------
-- File : header_encoder_sim.vhd
-- Created : 26.11.2025
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Primary Header Encoder Simulation File
----------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity header_encoder_sim is
--  Port ( );
end header_encoder_sim;

architecture Behavioral of header_encoder_sim is
component top_level is
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
end component top_level;
    signal transfer_frame_version_number_s: std_logic_vector(1 downto 0);
    signal spacecraft_id_s: std_logic_vector(9 downto 0);
    signal virtual_channel_id_s: std_logic_vector(2 downto 0);
    signal ocf_flag_s: std_logic;
    signal master_channel_frame_count_s: std_logic_vector(7 downto 0);
    signal virtual_channel_frame_count_s: std_logic_vector(7 downto 0);
    signal transfer_frame_secondary_header_flag_s: std_logic;
    signal snych_flag_s: std_logic;
    signal packet_order_flag_s: std_logic;
    signal segment_length_id_s: std_logic_vector(1 downto 0);
    signal first_header_pointer_s: std_logic_vector(10 downto 0);
    signal header_data_s: std_logic_vector(47 downto 0);
begin

EUT: top_level port map (
    transfer_frame_version_number_i => transfer_frame_version_number_s,
    spacecraft_id_i => spacecraft_id_s,
    virtual_channel_id_i => virtual_channel_id_s,
    ocf_flag_i => ocf_flag_s,
    master_channel_frame_count_i => master_channel_frame_count_s,
    virtual_channel_frame_count_i => virtual_channel_frame_count_s,
    transfer_frame_secondary_header_flag_i => transfer_frame_secondary_header_flag_s,
    snych_flag_i => snych_flag_s,
    packet_order_flag_i => packet_order_flag_s,
    segment_length_id_i => segment_length_id_s,
    first_header_pointer_i => first_header_pointer_s,
    header_data_o => header_data_s
);

process is
begin
    transfer_frame_version_number_s <= "00";
    spacecraft_id_s <= "0000000000";
    virtual_channel_id_s <= "000";
    ocf_flag_s <= '0';
    master_channel_frame_count_s <= "00000000";
    virtual_channel_frame_count_s <= "00000000";
    transfer_frame_secondary_header_flag_s <= '0';
    snych_flag_s <= '0';
    packet_order_flag_s <= '0';
    segment_length_id_s <= "00";
    first_header_pointer_s <= "00000000000";
    
    wait for 10ns;
    transfer_frame_version_number_s <= "01";
    wait for 10ns;
    transfer_frame_version_number_s <= "00";
    spacecraft_id_s <= "0000000001";
    wait for 10ns;
    spacecraft_id_s <= "0000000000";
    virtual_channel_id_s <= "001";
    wait for 10ns;
    virtual_channel_id_s <= "000";
    wait;
end process;


end Behavioral;
