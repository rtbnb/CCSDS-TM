library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity header_encoder is
	Port(
		clk: in std_logic;
        In1: in std_logic;
        In2: in std_logic;
		result: out std_logic
	);
end entity header_encoder;

architecture behavioral of header_encoder is	
    signal a: std_logic;

begin

    result <= a;

    process(clk,In1,In2)
    begin
        if rising_edge(clk) then
            a <= In1 and In2; 
        end if;

        
    end process;
end architecture behavioral;
