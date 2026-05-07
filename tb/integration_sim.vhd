----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.05.2026 08:22:36
-- Design Name: 
-- Module Name: integration_sim - Behavioral
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

entity integration_sim is
--  Port ( );
end integration_sim;

architecture Behavioral of integration_sim is
component INTEGRATION is
port(
    clk_i_0 : in STD_LOGIC;
    data_i_0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    data_valid_i_0 : in STD_LOGIC;
    fifo_rd_en_0 : in STD_LOGIC;
    ground_clk_0 : in STD_LOGIC;
    out_full_i_0 : in STD_LOGIC;
    ready_o_0 : out STD_LOGIC;
    reset_i_0 : in STD_LOGIC;
    spacecraft_id_i_0 : in STD_LOGIC_VECTOR ( 9 downto 0 );
    tm_data_field_o_0 : out STD_LOGIC_VECTOR ( 31 downto 0 );
    tm_data_field_valid_o_0 : out STD_LOGIC;
    transfer_frame_version_number_i_0 : in STD_LOGIC_VECTOR ( 1 downto 0 )
 );
 end component INTEGRATION;
 
 signal clk_ground_s: std_logic := '0';
 signal clk_space_s: std_logic := '0';
 signal space_data_i_s: std_logic_vector(7 downto 0);
 signal space_data_valid_i_s: std_logic := '0';
 signal fifo_rd_en_s: std_logic := '1';
 signal out_full_i_s: std_logic;
 signal ready_o_s: std_logic;
 signal nreset_i_s: std_logic := '1';
 signal spacecraft_id_i_s: std_logic_vector(9 downto 0) := "0000000000";
 signal tm_data_field_o_s: std_logic_vector(31 downto 0);
 signal tm_data_field_valid_o_s: std_logic;
 signal transfer_frame_version_number_i_s: std_logic_vector(1 downto 0);
 
 constant CLK_PERIOD : time := 10 ns;

begin
in_inst: INTEGRATION port map (
    clk_i_0 => clk_space_s,
    ground_clk_0 => clk_ground_s,
    data_i_0 => space_data_i_s,
    data_valid_i_0 => space_data_valid_i_s,
    fifo_rd_en_0 => fifo_rd_en_s,
    out_full_i_0 => out_full_i_s,
    ready_o_0 => ready_o_s,
    reset_i_0 => nreset_i_s,
    spacecraft_id_i_0 => spacecraft_id_i_s,
    tm_data_field_o_0 => tm_data_field_o_s,
    tm_data_field_valid_o_0 => tm_data_field_valid_o_s,
    transfer_frame_version_number_i_0 => transfer_frame_version_number_i_s
);

space_clock: process is
begin
    clk_space_s <= not clk_space_s;
    wait for CLK_PERIOD;
end process space_clock;

ground_clock: process is
begin
    clk_ground_s <= not clk_ground_s;
    wait for CLK_PERIOD;
end process ground_clock;



end Behavioral;
