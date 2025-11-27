----------------------------------------------------------------
-- File : oid_data_generator.vhd
-- Created : 27.11.2025
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : Data Generator for OID TM Transfer Frames
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity oid_data_generator is
	port(
        clk_i: in std_logic;
        data_frequency_divider_i: in std_logic_vector(3 downto 0);
        data_out_clk_o: out std_logic;
        data_out_o: out std_logic_vector(31 downto 0)
	);
end entity oid_data_generator;

architecture behavioral of oid_data_generator is
begin

end architecture behavioral;
