----------------------------------------------------------------
-- File : empty_to_valid.vhd
-- Created : 05.05.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : Empty to Valid Flag Converter
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity empty_to_valid is
    port (
        empty_i: in std_logic;
        data_valid_o: out std_logic;
        rd_enb_o: out std_logic;
        clk_i: in std_logic
    );
end entity empty_to_valid;

architecture behavioral of empty_to_valid is
begin
    rd_enb_o <= '1';

    delay: process(clk_i) is
    begin
        if rising_edge(clk_i) then
            data_valid_o <= not empty_i;
        end if;
    end process delay;

end architecture behavioral;