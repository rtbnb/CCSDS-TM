----------------------------------------------------------------
-- File : reed_solomon_decoder_syndrome.vhd
-- Created : 16.05.2026
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : This calculates the syndromes of a R/S code word using an inverse Horner's method
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_decoder_syndrome is
    generic(
        max_number_of_errors_g : integer := 16
    );
    port (
        clk_i                   : in  std_logic;
        reset_i                 : in  std_logic;
        asm_done_i              : in  std_logic;
        data_i                  : in  finite_field_t;
        data_valid_i            : in std_logic;
        syndrome_valid_o        : out std_logic;
        syndrome_o              : out finite_field_syndrome_t
        
        
    );
end entity reed_solomon_decoder_syndrome;

architecture behavioral of reed_solomon_decoder_syndrome is
    signal gen_poly_running_r : finite_field_syndrome_t;
    signal syndromes_r        : finite_field_syndrome_t;
    signal iteration_count_r  : integer range 0 to 255;
begin

    syndrome_process: process (clk_i)
    begin
        if reset_i = '0' then
            syndromes_r <= (others => x"00");
            iteration_count_r <= 0;
        elsif rising_edge(clk_i) then
            if asm_done_i = '1' then
                syndromes_r <= (others=> x"00");
                gen_poly_running_r <= GEN_POLY_LOOK_UP_PREPOWER;
                iteration_count_r <= 0;
                syndrome_valid_o <= '0';
            else
                syndrome_valid_o <= '0';
                if data_valid_i = '1' then
                    for i in 0 to 2*max_number_of_errors_g-1 loop
                        -- using inverse Horner's method hereto make poly evaluate fromn 255 to 0 and not vice visa
                        syndromes_r(i) <= gf_add(gf_mult(data_i, gen_poly_running_r(i)), syndromes_r(i));
                        gen_poly_running_r(i) <= gf_mult(gen_poly_running_r(i), GEN_POLY_LOOK_UP_INVERSE(i));
                    end loop;
                    
                    if iteration_count_r = 255 then
                        syndrome_o <= syndromes_r;
                        syndrome_valid_o <= '1';
                    else 
                        iteration_count_r <= iteration_count_r + 1;                    
                    end if;
                    
                                      
                end if;
            end if;
        end if;
        
    end process syndrome_process;


       
    

end architecture behavioral;
