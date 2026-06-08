----------------------------------------------------------------
-- File         : oid_generator_tb.vhd
-- Created      : 18.05.2026
-- Author       : Hannah Lindner 
-- Project Name : CCSDS 132 
-- Description  : testbench for oid generator
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity oid_generator_tb is
--  Port ( );
end oid_generator_tb;

architecture Behavioral of oid_generator_tb is

signal        clk_i           :std_logic := '0'; 
signal        reset_i         :std_logic := '0';
signal        enable_i        :std_logic := '0';  
        -- output ports  
signal        data_o          :std_logic_vector(7 downto 0);
signal        data_valid_o    : std_logic;


component oid_generator is 
    port(
        -- input ports 
        clk_i           : in std_logic; 
        reset_i         : in std_logic;
        enable_i        : in std_logic;  
        -- output ports  
        data_o          : out std_logic_vector(7 downto 0);
        data_valid_o    : out std_logic
    );
end component oid_generator; 

begin

clk_i <= not clk_i after 20 ns; 
reset_i <= '1' after 100 ns;

dut: entity work.OID_generator
port map (
        clk_i       => clk_i,     
        reset_i     => reset_i, 
        enable_i    => enable_i,      
        -- output ports  
        data_o      => data_o,
        data_valid_o => data_valid_o     
);

P1: process
begin
wait for 110 ns; 
enable_i <= '1'; 
wait for 30 ns; 
enable_i <= '0'; 
wait for 350 ns;
end process;


end Behavioral;
