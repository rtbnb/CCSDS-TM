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
        master_channel_1_id_g: std_logic_vector(11 downto 0);
    );
    port (
        -- inputs
        data_i: in std_logic_vector(7 downto 0);
        clk_i: in std_logic;
        data_valid_i: in std_logic;
        reset_i: in std_logic;

        master_channel_id_i: in std_logic_vector(11 downto 0);

        -- outputs
        -- create these outputs for every master channel
        data_mc_1_o: out std_logic_vector(7 downto 0);
        data_valid_mc_1_o: out std_logic
    );

end entity master_channel_demultiplexer;

architecture behavioral of master_channel_demultiplexer is

begin

    demultiplexer: process is
    begin
        if reset_i = '0' then
            data_valid_o <= 0;
            data_mc_1_o <= x"00";
        else
            case master_channel_id_i
                -- create this case for every master channel
                when master_channel_1_id_g =>
                    data_mc_1_o <= data_i;
                    data_valid_mc_1_o <= data_valid_i;
                when others =>
                    data_valid_o <= 0;
                    data_mc_1_o <= x"00";
            end case;
        end if;
    end process demultiplexer;

end architecture behavioral;