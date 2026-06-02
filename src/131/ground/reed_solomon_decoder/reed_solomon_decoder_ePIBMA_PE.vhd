----------------------------------------------------------------
-- File : reed_solomon_decoder_epibma_pe.vhd
-- Created : 05.05.2026
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : The Processing Element (PE) for the systolic Enhanced Parallel Inversionless B-M Algorithm (ePIBMA) archiecture of the R/R decoder
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_decoder_epibma_pe is
    port (
        clk_i               : in  std_logic;
        reset_i             : in  std_logic;
        new_poly_i          : in std_logic;
        new_omega_i         : in finite_field_t;
        new_theta_i         : in finite_field_t;
        
        omega_i : in finite_field_t;
        gamma_i : in finite_field_t;
        delta_i : in finite_field_t;
        theta_i : in finite_field_t;
        mc1_i : in std_logic;
        mc2_i : in std_logic;
        mc3_i : in std_logic;
        enable_i : in std_logic; 
        
        omega_o : out finite_field_t;
        theta_o : out finite_field_t

    );
end entity reed_solomon_decoder_epibma_pe;

architecture behavioral of reed_solomon_decoder_epibma_pe is
    signal theta_r: finite_field_t :="00000000";
    signal omega_r: finite_field_t :="00000000";
begin
    processing_element : process (clk_i)
    begin
        if reset_i = '0' then
            omega_r <= x"00";
            theta_r <= x"00";
        elsif rising_edge(clk_i) then
            if new_poly_i = '1' then
                theta_r<=new_theta_i;
                omega_r<=new_omega_i;
            else
                if enable_i = '1' then
                    -- Calculate new Omega value:
                    -- OmegaI * gamma + thetaR * delta
                    omega_r <= gf_add(gf_mult(omega_i, gamma_i),gf_mult(theta_r, delta_i));
                    
                    if mc2_i = '1' then
                        theta_r <= x"00";
                    else
                        if mc1_i = '1' then 
                            theta_r <= omega_i;
                        else
                            if mc3_i = '1' then
                                theta_r <= theta_i;                            
                            else
                                theta_r <= theta_r;
                            end if;
                        end if;
                    end if;                
                end if;                
            end if;
        end if;
    end process processing_element;
    omega_o <= omega_r;
    theta_o <= theta_r;


end architecture behavioral;