library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
	Port(
		clk: in std_logic;
		In1: in std_logic;
        In2: in std_logic;
        In3: in std_logic;
		Out1: out std_logic;
        Out2: out std_logic;
        Out3: out std_logic
	);
end entity top_level;

architecture behavioral of top_level is
    component header_encoder is
        port(
            clk: in std_logic;
            In1: in std_logic;
            In2: in std_logic;
            result: out std_logic
        );
    end component;

    signal test: std_logic;
begin
    encoder1: header_encoder port map(
        clk=>clk,
        In1=>In1,
        In2=>In2,
        result=>test
    );

    process(clk)
    begin
        if rising_edge(clk) then
            Out3 <= In1 and In3;
        end if;
    end process;

    Out2 <= test;
	Out1 <= In1 and In2;
end architecture behavioral;
