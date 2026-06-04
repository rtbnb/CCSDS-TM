----------------------------------------------------------------
-- File : virtual_channel_demultiplexer.vhd
-- Created :04.06.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Virtual Channel Demultiplexing Function
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity virtual_channel_demultiplexer is
    generic (
        -- create this generic for every master channel
        virtual_channel_1_id_g: std_logic_vector(2 downto 0) := "000"
    );
    port (
        -- inputs
        data_i: in std_logic_vector(7 downto 0);
        clk_i: in std_logic;
        data_valid_i: in std_logic;
        reset_i: in std_logic;

        virtual_channel_id_i: in std_logic_vector(2 downto 0);
        new_frame_i: in std_logic;
        first_header_pointer_i: in std_logic_vector(10 downto 0);

        -- data decoder ready input
        rdy_vc1_i: in std_logic;

        -- outputs
        -- create these outputs for every virtual channel
        data_vc_1_o: out std_logic_vector(7 downto 0);
        data_valid_vc_1_o: out std_logic;
        new_frame_vc1_o: out std_logic;
        first_header_pointer_vc1_o: out std_logic_vector(10 downto 0);

        rdy_o: out std_logic := '0'
    );

end entity virtual_channel_demultiplexer;

architecture behavioral of virtual_channel_demultiplexer is

begin

    rdy_o <= rdy_vc1_i;

    new_frame_vc1_o <= new_frame_i;
    first_header_pointer_vc1_o <= first_header_pointer_i;

    data_valid_vc_1_o <=
        '0' when reset_i = '0' else
        data_valid_i when virtual_channel_id_i = virtual_channel_1_id_g else
        '0';
    data_vc_1_o <= 
        x"00" when reset_i = '0' else    
        data_i when virtual_channel_id_i = virtual_channel_1_id_g else
        x"00";


end architecture behavioral;