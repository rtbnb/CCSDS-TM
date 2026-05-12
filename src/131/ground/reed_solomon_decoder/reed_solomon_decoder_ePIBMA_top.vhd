----------------------------------------------------------------
-- File : reed_solomon_decoder_epibma_top.vhd
-- Created : 05.05.2026
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : The top for the systolic Enhanced Parallel Inversionless B-M Algorithm (ePIBMA) archiecture of the R/R decoder
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_decoder_epibma_top is
    generic(
        max_number_of_errors_g : integer := 16
    );
    port (
        clk_i               : in  std_logic;
        reset_i             : in  std_logic;
        new_poly_i          : in std_logic
    );
end entity reed_solomon_decoder_epibma_top;

architecture behavioral of reed_solomon_decoder_epibma_top is
    type finite_field_epibma_t is array (0 to max_number_of_errors_g*2) of finite_field_t;
    type finite_field_epibma_2_t is array (0 to max_number_of_errors_g*2-1) of finite_field_t;
    
    signal omega_array_r: finite_field_epibma_2_t;
    signal theta_array_r : finite_field_epibma_2_t;
    
    signal omega_new_array_r: finite_field_epibma_t := (x"2F",
x"F1",
x"33",
x"F1",
x"78",
x"2F",
x"2F",
x"01",
x"F9",
x"C0",
x"FA",
x"E1",
x"33",
x"C0",
x"33",
x"17",
x"C0",
x"F9",
x"F4",
x"FA",
x"FE",
x"E1",
x"F1",
x"E1",
x"01",
x"92",
x"A7",
x"8F",
x"F9",
x"FE",
x"FA",
x"A5",
x"01");
                                                        
    signal theta_new_array_r: finite_field_epibma_t := (x"2F",
x"F1",
x"33",
x"F1",
x"78",
x"2F",
x"2F",
x"01",
x"F9",
x"C0",
x"FA",
x"E1",
x"33",
x"C0",
x"33",
x"17",
x"C0",
x"F9",
x"F4",
x"FA",
x"FE",
x"E1",
x"F1",
x"E1",
x"01",
x"92",
x"A7",
x"8F",
x"F9",
x"FE",
x"FA",
x"00",
x"01");
    
    signal mc1_r : std_logic;
    signal mc2_r : std_logic_vector(max_number_of_errors_g*2 downto 0);
    signal mc3_r : std_logic;
    signal delta_i_r : finite_field_t;
    signal delta_o_r : finite_field_t;
    signal gamma_r : finite_field_t;
    
   
    
    
    
begin
    rs_decoder_epibma_control_inst: entity work.reed_solomon_decoder_epibma_control
        generic map(
            max_number_of_errors_g => max_number_of_errors_g
        )
        port map (
            clk_i  => clk_i,
            reset_i => reset_i,
            new_poly_i => new_poly_i,
            delta_i => delta_i_r,
            
            delta_o => delta_o_r,
            gamma_o => gamma_r,
            mc1_o => mc1_r,
            mc2_o => mc2_r,
            mc3_o => mc3_r
        );
    
  rs_decoder_epibma_pe_gen:for i in 1 to max_number_of_errors_g*2-1 generate
        rs_decoder_epibma_pe_inst_loop: entity work.reed_solomon_decoder_epibma_pe
            port map (
                clk_i =>   clk_i,          
                reset_i => reset_i,
                new_poly_i => new_poly_i,    
                new_omega_i =>  omega_new_array_r(i),      
                new_theta_i =>  theta_new_array_r(i),      
                
                omega_i => omega_array_r(i),
                gamma_i => gamma_r,
                delta_i => delta_o_r,
                theta_i => theta_array_r(i),
                mc1_i => mc1_r,
                mc2_i => mc2_r(max_number_of_errors_g*2-i),
                mc3_i => mc3_r,
                
                omega_o => omega_array_r(i-1),
                theta_o => theta_array_r(i-1)
            );
    end generate rs_decoder_epibma_pe_gen;
    
    rs_decoder_epibma_pe_inst_last_element: entity work.reed_solomon_decoder_epibma_pe
        port map (
                clk_i =>   clk_i,          
                reset_i => reset_i,
                new_poly_i => new_poly_i,    
                new_omega_i =>  omega_new_array_r(0),      
                new_theta_i =>  theta_new_array_r(0),      
                
                omega_i => omega_array_r(0),
                gamma_i => gamma_r,
                delta_i => delta_o_r,
                theta_i => theta_array_r(0),
                mc1_i => mc1_r,
                mc2_i => mc2_r(32),
                mc3_i => mc3_r,
                
                omega_o => delta_i_r,
                theta_o => open
            );
       
       rs_decoder_epibma_pe_inst_first_element: entity work.reed_solomon_decoder_epibma_pe
        port map (
                clk_i =>   clk_i,          
                reset_i => reset_i,
                new_poly_i => new_poly_i,    
                new_omega_i =>  omega_new_array_r(32),      
                new_theta_i =>  theta_new_array_r(32),      
                
                omega_i => x"00",
                gamma_i => gamma_r,
                delta_i => delta_o_r,
                theta_i => x"00",
                mc1_i => mc1_r,
                mc2_i => mc2_r(0),
                mc3_i => mc3_r,
                
                omega_o => omega_array_r(31),
                theta_o => theta_array_r(31)
            );
    
    
    
end architecture behavioral;
