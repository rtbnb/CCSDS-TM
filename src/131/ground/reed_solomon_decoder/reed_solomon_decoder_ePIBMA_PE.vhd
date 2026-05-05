----------------------------------------------------------------
-- File : reed_solomon_decoder_ePIBMA_PE.vhd
-- Created : 05.05.2026
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : The Processing Element (PE) for the systolic Enhanced Parallel Inversionless B-M Algorithm (ePIBMA) archiecture of the R/R decoder
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_decoder_ePIBMA_PE is
    port (
        clk_i               : in  std_logic;
        reset_i             : in  std_logic;
        new_poly_i          : in std_logic;
        new_omega_i         : in std_logic_vector(7 downto 0);
        new_theta_i         : in std_logic_vector(7 downto 0);
        
        omega_i : in std_logic_vector(7 downto 0);
        gamma_i : in std_logic_vector(7 downto 0);
        delta_i : in std_logic_vector(7 downto 0);
        theta_i : in std_logic_vector(7 downto 0);
        mc1_i : in std_logic;
        mc2_i : in std_logic;
        mc3_i : in std_logic; 
        
        omega_o : out std_logic_vector(7 downto 0);
        theta_o : out std_logic_vector(7 downto 0);

    );
end entity reed_solomon_decoder_ePIBMA_PE;

architecture behavioral of reed_solomon_decoder_ePIBMA_PE is
    signal theta_r: finite_field_t :="00000000";
    signal omega_r: finite_field_t :="00000000";
begin
    processing_element : process (clk_i)
    begin
        if reset_i = '0' then
            omega_o <= x"00";
            omega_r <= x"00";
            
            theta_o <= x"00";
            theta_r <= x"00";
        elsif rising_edge(clk_i) then
            if new_poly_i = '1' then
                theta_r<=new_theta_i;
                omega_r<=new_omega_i;
            else
                -- Calculate new Omega value:
                -- OmegaI * gamma + thetaR * delta
                omega_r <= gf_add(gf_mult(omega_i, gamma_i),gf_mult(theta_r, delta_i));
                
                if 
                
            end if;
        end if;
    end process processing_element;
    
    
    omega_o <= omega_r;
    theta_o <= theta_r;


end architecture behavioral;