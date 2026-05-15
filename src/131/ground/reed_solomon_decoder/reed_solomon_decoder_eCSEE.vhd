----------------------------------------------------------------
-- File : reed_solomon_decoder_eCSEE.vhd
-- Created : 15.05.2026
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : This entity runs the Enhanced Chien Search & Error Evaluation (eCSEE) to compute error mags and positions from ePIBMA results
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_decoder_ecsee is
    generic(
        max_number_of_errors_g : integer := 16
    );
    port (
        clk_i                   : in  std_logic;
        reset_i                 : in  std_logic;
        epibma_done_i           : in std_logic;
        error_locator_poly_i    : in finite_field_error_locator_t;
        error_mag_poly_i        : in finite_field_error_mag_t;
        
        error_found_o           : out std_logic
        
    );
end entity reed_solomon_decoder_ecsee;

architecture behavioral of reed_solomon_decoder_ecsee is
    signal error_locator_poly_r : finite_field_error_locator_t;
    signal error_mag_poly_r : finite_field_error_mag_t;
    signal first_cylce_r : std_logic;
    
begin
   chien_search: process (clk_i)
        variable a_odd : finite_field_t;
        variable a_even : finite_field_t;
   begin
   
        if reset_i = '0' then
            error_locator_poly_r <= (others => x"00");
            error_mag_poly_r <= (others => x"00");
            first_cylce_r <= '0';
            error_found_o <= '0';
            
        elsif rising_edge(clk_i) then
            if epibma_done_i = '1' then
                error_locator_poly_r <= error_locator_poly_i;
                error_mag_poly_r <= error_mag_poly_i;
                first_cylce_r <= '1';
                error_found_o <= '0';
            else 
                a_odd:=x"00";
                a_even:=x"00";
                
                -- calc a_odd and a_even
                a_odd := gf_add(a_odd, error_locator_poly_r(1));
                a_odd := gf_add(a_odd, error_locator_poly_r(3));
                a_odd := gf_add(a_odd, error_locator_poly_r(5));
                a_odd := gf_add(a_odd, error_locator_poly_r(7));
                a_odd := gf_add(a_odd, error_locator_poly_r(9));
                a_odd := gf_add(a_odd, error_locator_poly_r(11));
                a_odd := gf_add(a_odd, error_locator_poly_r(13));
                a_odd := gf_add(a_odd, error_locator_poly_r(15));
                
                a_even := gf_add(a_even, error_locator_poly_r(0));
                a_even := gf_add(a_even, error_locator_poly_r(2));
                a_even := gf_add(a_even, error_locator_poly_r(4));
                a_even := gf_add(a_even, error_locator_poly_r(6));
                a_even := gf_add(a_even, error_locator_poly_r(8));
                a_even := gf_add(a_even, error_locator_poly_r(10));
                a_even := gf_add(a_even, error_locator_poly_r(12));
                a_even := gf_add(a_even, error_locator_poly_r(14));
                a_even := gf_add(a_even, error_locator_poly_r(16));
                
                
                for i in 1 to max_number_of_errors_g loop
                    error_locator_poly_r(i) <= gf_mult(error_locator_poly_r(i), ERROR_LOCATOR_LOOK_UP(i));
                
                end loop;
                
                if a_odd = a_even then
                    error_found_o <= '1';
                else
                    error_found_o <= '0';
                end if;
                
                
                
            end if;
        end if;
   
   end process chien_search;

       
    

end architecture behavioral;
