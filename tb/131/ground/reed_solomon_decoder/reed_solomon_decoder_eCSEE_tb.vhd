----------------------------------------------------------------
-- File : reed_solomon_decoder_ecsee_tb.vhd
-- Created : 15.05.2026
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : Testbench R/S Decoder ecsee error serach
----------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_decoder_ecsee_tb is
end entity reed_solomon_decoder_ecsee_tb;

architecture behavioral of reed_solomon_decoder_ecsee_tb is
    component reed_solomon_decoder_ecsee is
    port (
        clk_i                   : in  std_logic;
        reset_i                 : in  std_logic;
        epibma_done_i           : in std_logic;
        error_locator_poly_i    : in finite_field_error_locator_t;
        error_mag_poly_i        : in finite_field_error_mag_t;
        z_i                     : in finite_field_t;
        gamma_i                 : in finite_field_t;
        
        
        error_found_o           : out std_logic;
        error_mag_o             : out finite_field_t 
    );
  end component;

    signal clk_r                : std_logic:='0';
    signal reset_r              : std_logic:='1';
    signal epibma_done_r        : std_logic;
    signal error_locator_poly_r : finite_field_error_locator_t:= (others => x"00");
    signal error_mag_poly_r     : finite_field_error_mag_t:= (others => x"00");
    signal z_r                  : finite_field_t;
    signal gamma_r              : finite_field_t;
    
    signal error_found_r        : std_logic;
    signal error_mag_r          : finite_field_t;
    
begin

    dut : reed_solomon_decoder_ecsee
    port map (
      clk_i         => clk_r,
      reset_i       => reset_r,
      epibma_done_i => epibma_done_r, 
      error_locator_poly_i => error_locator_poly_r,
      error_mag_poly_i => error_mag_poly_r,
      z_i => z_r,
      gamma_i => gamma_r,
      
      error_found_o => error_found_r,
      error_mag_o => error_mag_r
    );
    
    error_locator_poly_r <= (x"78",
x"28",
x"3A",
x"EA",
x"38",
x"A5",
x"E4",
x"8D",
x"11",
x"5C",
x"A1",
x"EA",
x"7C",
x"00",
x"00",
x"00",
x"00");
                                                        
    error_mag_poly_r <=   (x"00",
x"00",
x"00",
x"00",
x"F5",
x"2E",
x"7D",
x"DB",
x"16",
x"31",
x"25",
x"F5",
x"DB",
x"97",
x"4B",
x"F5");         
         
    z_r <=  x"0F";
    gamma_r <= x"83";
    clk_r <= not clk_r after 5 ns;
    
    process
    begin
        epibma_done_r <= '1';
        wait for 15 ns;
        epibma_done_r <= '0';
        wait for 2550 ns;
        
        
    end process;

    

end architecture;