----------------------------------------------------------------
-- File : reed_solomon_decoder_fifo_tb.vhd
-- Created : 28.11.2025
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : Testbench R/S Decoder stub for MVP, just implements the FIFO for error correction
----------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reed_solomon_decoder_epibma_top_tb is
end entity reed_solomon_decoder_epibma_top_tb;

architecture behavioral of reed_solomon_decoder_epibma_top_tb is
    component reed_solomon_decoder_epibma_top is
    port (
        clk_i               : in  std_logic;
        clk_2_i               : in  std_logic;
        reset_i             : in  std_logic;
        new_poly_i          : in std_logic
    );
  end component;

    signal clk_r               :std_logic:='0';
    signal clk_2_r               :std_logic:='0';
    signal         reset_r            : std_logic:='1';
    signal         new_poly_i        :std_logic :='1';
    
begin

    dut : reed_solomon_decoder_epibma_top
    port map (
      clk_i       => clk_r,
      clk_2_i     => clk_2_r,
      reset_i     => reset_r,
      new_poly_i=> new_poly_i
    );

    clk_r <= not clk_r after 5 ns;
    clk_2_r <= not clk_2_r after 5 ns;
    
    process
    begin
        new_poly_i <= '1';
        wait for 15 ns;
        new_poly_i <= '0';
        wait for 320 ns;
        new_poly_i <= '1';
        wait;
    end process;

    

end architecture;