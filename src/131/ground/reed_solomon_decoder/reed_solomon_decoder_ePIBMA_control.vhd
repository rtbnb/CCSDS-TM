----------------------------------------------------------------
-- File : reed_solomon_decoder_epibma_control.vhd
-- Created : 05.05.2026
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : The control unit for the systolic Enhanced Parallel Inversionless B-M Algorithm (ePIBMA) archiecture of the R/R decoder
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_decoder_epibma_control is
    generic(
        max_number_of_errors_g : integer := 16
    );
    port (
        clk_i               : in  std_logic;
        reset_i             : in  std_logic;
        new_poly_i          : in std_logic;
        delta_i : in finite_field_t;
        
        delta_o : out finite_field_t;
        gamma_o : out finite_field_t;
        mc1_o : out std_logic;
        mc2_o : out std_logic_vector(max_number_of_errors_g*2 downto 0);
        mc3_o : out std_logic
        
    );
end entity reed_solomon_decoder_epibma_control;

architecture behavioral of reed_solomon_decoder_epibma_control is
    signal mc2_r : std_logic_vector(max_number_of_errors_g*2 downto 0);
    signal l_a_r : finite_field_t;
    signal l_b_r : finite_field_t;
    signal gamma_r: finite_field_t;
    signal z_r: finite_field_t;
begin

    control_unit : process (clk_i)
    begin
        if reset_i = '0' then
            delta_o <= x"00";
            gamma_o <= x"00";
            
            mc1_o <= '0';
            mc2_o <= (others => '0');
            mc3_o <= '0';
            mc2_r <= (others => '0');
            
            l_a_r <= x"00";
            l_b_r <= x"00";
            gamma_r <= x"01";
            z_r <= x"01";
        elsif rising_edge(clk_i) then
            if new_poly_i = '1' then
                mc2_r <= (others => '0');
                mc2_r(0) <= '1';
                
                l_a_r <= x"00";
                l_b_r <= x"00";
                gamma_r <= x"01";
                z_r <= x"01";
            else
                if (gf_to_int(delta_i) > 0) and (gf_to_int(l_a_r) <= gf_to_int(l_a_r)) then
                    mc1_o <= '1';
                    l_a_r <= gf_add(l_b_r,x"01");
                    l_b_r <= l_a_r;
                    gamma_r <= delta_i;
                else
                    mc1_o <= '0';
                    
                    if gf_to_int(l_b_r) = max_number_of_errors_g-1 then
                        mc3_o <= '1';
                        l_b_r <= l_b_r;
                    else
                        mc3_o <= '0';
                        l_b_r <= gf_add(l_b_r,x"01");    
                    end if;
                    
                    l_a_r <= l_a_r;
                    gamma_r <= gamma_r;
                
                end if; 
            end if;
        end if;
        
    end process control_unit;
    
    mc2_o <= mc2_r;
    gamma_o <= gamma_r;

end architecture behavioral;
