----------------------------------------------------------------
-- File : reed_solomon_decoder_fifo_tb.vhd
-- Created : 28.11.2025
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : Testbench R/S Decoder stub for MVP, just implements the FIFO for error correction
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_decoder_epibma_top_tb is
end entity reed_solomon_decoder_epibma_top_tb;

architecture behavioral of reed_solomon_decoder_epibma_top_tb is
    component reed_solomon_decoder_epibma_top is
    port (
        clk_i               : in  std_logic;
        reset_i             : in  std_logic;
        new_poly_i          : in  std_logic;
        epibma_done_o       : out std_logic;
        error_locator_poly_o : out finite_field_error_locator_t;
        error_mag_poly_o     : out finite_field_error_mag_t
    );
  end component;

    signal clk_r                : std_logic:='0';
    signal reset_r              : std_logic:='1';
    signal new_poly_r           : std_logic :='1';
    signal epibma_done_r        : std_logic;
    signal error_locator_poly_r : finite_field_error_locator_t;
    signal error_mag_poly_r     : finite_field_error_mag_t;
    
begin

    dut : reed_solomon_decoder_epibma_top
    port map (
      clk_i         => clk_r,
      reset_i       => reset_r,
      new_poly_i    => new_poly_r,
      epibma_done_o => epibma_done_r, 
      error_locator_poly_o => error_locator_poly_r,
      error_mag_poly_o => error_mag_poly_r
    );

    clk_r <= not clk_r after 5 ns;
    
    stimuli: process
    begin
        new_poly_r <= '1';
        wait for 15 ns;
        new_poly_r <= '0';
        wait for 360 ns;
        --new_poly_i <= '1';
    end process stimuli;

    

end architecture;