----------------------------------------------------------------
-- File : not_gate.vhd
-- Created : 05.05.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : Not Gate
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity not_gate is
    port (
        a_i: in std_logic;
        not_a_o: out std_logic
    );
end entity not_gate;

architecture behavioral of not_gate is
begin
    not_a_o <= not a_i;
end architecture behavioral;