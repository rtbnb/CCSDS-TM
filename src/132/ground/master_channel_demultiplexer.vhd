----------------------------------------------------------------
-- File : master_channel_demultiplexer.vhd
-- Created :04.06.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Master Channel Demultiplexing Function
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity master_channel_demultiplexer is
    generic (
        -- create this generic for every master channel
        master_channel_1_id_g: std_logic_vector(11 downto 0) := "000000000000"
    );
    port (
        -- inputs
        data_i: in std_logic_vector(7 downto 0);
        clk_i: in std_logic;
        data_valid_i: in std_logic;
        reset_i: in std_logic;
        rdy_vc1_i: in std_logic;

        master_channel_id_i: in std_logic_vector(11 downto 0);

        virtual_channel_id_i: in std_logic_vector(2 downto 0);
        new_frame_i: in std_logic;
        first_header_pointer_i: in std_logic_vector(10 downto 0);

        -- outputs
        -- create these outputs for every master channel
        data_mc1_o: out std_logic_vector(7 downto 0);
        data_valid_mc1_o: out std_logic;
        virtual_channel_id_mc1_o: out std_logic_vector(2 downto 0);
        new_frame_mc1_o: out std_logic;
        first_header_pointer_mc1_o: out std_logic_vector(10 downto 0);
        rdy_o: out std_logic
    );

end entity master_channel_demultiplexer;

architecture behavioral of master_channel_demultiplexer is

begin

    rdy_o <= rdy_vc1_i;
    first_header_pointer_mc1_o <= first_header_pointer_i;
    new_frame_mc1_o <= new_frame_i;
    virtual_channel_id_mc1_o <= virtual_channel_id_i;

    -- for every master channel
    data_valid_mc1_o <= 
        '0' when reset_i = '0' else
        data_valid_i when master_channel_1_id_g = master_channel_id_i else
        '0';
    data_mc1_o <= 
        x"00" when reset_i = '0' else  
        data_i when master_channel_1_id_g = master_channel_id_i else
        x"00";

end architecture behavioral;