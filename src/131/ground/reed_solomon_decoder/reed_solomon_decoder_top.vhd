----------------------------------------------------------------
-- File : reed_solomon_decoder_top.vhd
-- Created : 20.05.2026
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : The top of the full R/S decoder
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_decoder_top is
    generic(
        max_number_of_errors_g : integer := 16
    );
    port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        input_byte_i : in std_logic_vector (7 downto 0);
        data_valid_i : in std_logic := '0';
        asm_done_i : in std_logic;

        data_valid_o : out std_logic;
        output_byte_o : out std_logic_vector (7 downto 0);
		reed_solomon_failure_o : out std_logic 
    );
end entity reed_solomon_decoder_top;

architecture behavioral of reed_solomon_decoder_top is
    signal synmdrome_valid_r : std_logic;
    signal syndrome_r       : finite_field_syndrome_t;
    signal epibma_done_r    : std_logic;
    signal error_locator_poly_r : finite_field_error_locator_t;
    signal error_mag_poly_r     : finite_field_error_mag_t;
    signal z_r                  : finite_field_t;
    signal gamma_r              : finite_field_t;
    
begin

    reed_solomon_decoder_fifo_inst: entity work.reed_solomon_decoder_fifo
        port map (
            clk_i   => clk_i,
            reset_i => reset_i,
            input_byte_i => input_byte_i,
            data_valid_i => data_valid_i,
    
            data_valid_o  => data_valid_o,
            output_byte_o => output_byte_o
        );
        
     reed_solomon_decoder_syndrome_inst: entity work.reed_solomon_decoder_syndrome
        port map (
             clk_i => clk_i,                   
             reset_i => reset_i,                
             asm_done_i => asm_done_i,           
             data_i  => input_byte_i,            
             data_valid_i => data_valid_i,
             syndrome_valid_o  => synmdrome_valid_r,      
             syndrome_o => syndrome_r   
        );
     
     reed_solomon_decoder_epibma_top_inst: entity  work.reed_solomon_decoder_epibma_top
        port map (
            clk_i => clk_i,
            reset_i => reset_i,
            new_poly_i => synmdrome_valid_r,
            enable_i   => data_valid_i,
            syndromes_i  => syndrome_r,
            
            z_o => z_r,
            gamma_o => gamma_r, 
            
            epibma_done_o => epibma_done_r,
            error_locator_poly_o => error_locator_poly_r,
            error_mag_poly_o => error_mag_poly_r
        );
     
     reed_solomon_decoder_ecsee_inst: entity work.reed_solomon_decoder_ecsee
         port map (
            clk_i => clk_i,
            reset_i => reset_i,
            epibma_done_i => epibma_done_r,
            error_locator_poly_i => error_locator_poly_r,
            error_mag_poly_i => error_mag_poly_r,
            z_i             => z_r,
            gamma_i         => gamma_r,
            enable_i        => asm_done_i,
            
            error_found_o   => open,
            error_mag_o     => open,
            decoder_fail_o  => reed_solomon_failure_o
        );
                    
end architecture behavioral;
