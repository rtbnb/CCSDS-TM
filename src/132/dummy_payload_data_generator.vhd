----------------------------------------------------------------
-- File : dummy_payload_data_generator.vhd
-- Created : 26.11.2025
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : Dummy Payload Data Generator
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dummy_payload_data_generator is
	Port(
        clk_i: in std_logic;
        data_freqency_divider_i: in std_logic_vector(3 downto 0);
        data_output_o: out std_logic_vector(31 downto 0)
	);
end entity dummy_payload_data_generator;

architecture behavioral of dummy_payload_data_generator is
    signal counter: std_logic_vector(3 downto 0);
begin


    dummy_payload_generator : process(clk) is
    begin
        
        if rising_edge(clk) then

        end if;





    end process dummy_payload_generator;



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
    header_data_o(47 downto 37) <= first_header_pointer_i;
end architecture behavioral;
