library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
	Port(
		In1: in std_logic;
		In2: in std_logic;
		Out1: out std_logic
	);
end entity top_level;
architecture behavioral of top_level is
	
begin
	Out1 <= In1 and In2;
end architecture behavioral;
