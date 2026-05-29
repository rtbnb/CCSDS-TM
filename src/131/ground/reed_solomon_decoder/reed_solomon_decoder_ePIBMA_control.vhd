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
        enable_i            : in std_logic;
        
        delta_o : out finite_field_t;
        gamma_o : out finite_field_t;
        mc1_o : out std_logic;
        mc2_o : out std_logic_vector(max_number_of_errors_g*2 downto 0);
        mc3_o : out std_logic;
        epibma_done_o: out std_logic;
        z_o             : out finite_field_t
        
    );
end entity reed_solomon_decoder_epibma_control;

architecture behavioral of reed_solomon_decoder_epibma_control is
    signal mc2_r : std_logic_vector(max_number_of_errors_g*2 downto 0);
    signal l_a_r : integer range 0 to max_number_of_errors_g;
    signal l_b_r : integer range 0 to max_number_of_errors_g;
    signal gamma_r: finite_field_t;
    signal z_r: finite_field_t;
    signal new_poly_r: std_logic;
    signal iter_count_r : integer range 0 to max_number_of_errors_g*2;
    signal first_value_r: std_logic;
begin
    synchronizer: process (clk_i)
    begin
        if reset_i = '0' then
            --new_poly_r <= '0';
            gamma_r <= x"01";
            epibma_done_o <= '0';
            first_value_r <= '0';
        elsif rising_edge(clk_i) then
            --new_poly_r <= new_poly_i;
            epibma_done_o <= '0';
            if (new_poly_i = '1') then
                gamma_r <= x"01";
                l_a_r <= 0;
                l_b_r <= 0;
                z_r <= x"01";
                first_value_r <= '1';
                
                -- Pre compute mc2_o to make sure it has the correct value for first iter
                mc2_r <= "000000000000000000000000000000100";
                iter_count_r <= 0;
            
            elsif (enable_i = '1' and first_value_r = '1') then
                    
                if (iter_count_r = max_number_of_errors_g*2-1) then
                    epibma_done_o <= '1';
                    iter_count_r <= iter_count_r + 1;
                elsif (iter_count_r > max_number_of_errors_g*2-1) then
                    epibma_done_o <= '0';
                    
                elsif ((gf_to_int(delta_i) > 0) and (l_a_r <= l_b_r)) then
                    l_a_r <= l_b_r + 1;
                    l_b_r <= l_a_r;
                    gamma_r <= delta_i;
                    
                    mc2_r <= mc2_r(max_number_of_errors_g*2-1 downto 0) & '0';
                    iter_count_r <= iter_count_r + 1;
                    z_r <= gf_mult(z_r, ERROR_LOCATOR_LOOK_UP(1));
                else
                    if (l_b_r = max_number_of_errors_g-1) then
                        l_b_r <= l_b_r;
                    else
                        l_b_r <= l_b_r+1;
                        z_r <= gf_mult(z_r, ERROR_LOCATOR_LOOK_UP(1));
                    end if;
                    gamma_r <= gamma_r;
                    l_a_r <= l_a_r;
                    
                    mc2_r <= mc2_r(max_number_of_errors_g*2-1 downto 0) & '0';
                    iter_count_r <= iter_count_r + 1;
                end if;
            end if;
        end if;
        
    end process synchronizer;
    
   gamma_o <= gamma_r;
   mc2_o <= mc2_r;
   
   delta_o <= x"00" when reset_i = '0' else 
              delta_i;
  
   mc1_o <= '0' when (reset_i = '0') else
             '1' when ((gf_to_int(delta_i) > 0) and (l_a_r <= l_b_r)) else
             '0';
             
   mc3_o <= '0' when (reset_i = '0') else
            '1' when (l_b_r = max_number_of_errors_g-1) else
            '0';
            
  z_o <= z_r;
          

       
    

end architecture behavioral;
