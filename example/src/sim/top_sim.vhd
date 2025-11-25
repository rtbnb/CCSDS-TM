----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.11.2025 13:51:20
-- Design Name: 
-- Module Name: top_sim - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_sim is
--  Port ( );
end top_sim;

architecture Behavioral of top_sim is
component top_level is
	Port(
		In1: in std_logic;
		In2: in std_logic;
		Out1: out std_logic
	);
end component top_level;

signal In1_s: std_logic;
signal In2_s: std_logic;
signal Out1_s: std_logic;

begin

EUT: top_level port map (
    In1 => In1_s,
    In2 => In2_s,
    Out1 => Out1_s
);

process is
begin
    In1_s <= '1';
    In2_s <= '0';
    wait for 10ns;
    In2_s <= '1';
    wait;
    
end process;


end Behavioral;
