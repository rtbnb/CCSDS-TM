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
        new_poly_i          : in std_logic;
        enable_i            : in std_logic;
        syndromes_i         : in finite_field_syndrome_t;
        
        epibma_done_o: out std_logic;
        error_locator_poly_o : out finite_field_error_locator_t;
        error_mag_poly_o : out finite_field_error_mag_t;
        z_o             : out finite_field_t;
        gamma_o         : out finite_field_t
    );
end entity reed_solomon_decoder_epibma_top;

architecture behavioral of reed_solomon_decoder_epibma_top is
    type finite_field_epibma_t is array (0 to max_number_of_errors_g*2) of finite_field_t;
    type finite_field_epibma_2_t is array (0 to max_number_of_errors_g*2-1) of finite_field_t;
    
    signal omega_array_r: finite_field_epibma_2_t;
    signal theta_array_r : finite_field_epibma_2_t;
    
    signal omega_new_array_r: finite_field_epibma_t := (x"CC",
x"D2",
x"CF",
x"90",
x"05",
x"C6",
x"D9",
x"FA",
x"E3",
x"44",
x"4E",
x"45",
x"70",
x"03",
x"42",
x"CA",
x"56",
x"DC",
x"3C",
x"3A",
x"BE",
x"AD",
x"01",
x"3E",
x"46",
x"32",
x"C9",
x"14",
x"16",
x"6A",
x"E6",
x"82",
x"01");
                                                        
    signal theta_new_array_r: finite_field_epibma_t := (x"CC",
x"D2",
x"CF",
x"90",
x"05",
x"C6",
x"D9",
x"FA",
x"E3",
x"44",
x"4E",
x"45",
x"70",
x"03",
x"42",
x"CA",
x"56",
x"DC",
x"3C",
x"3A",
x"BE",
x"AD",
x"01",
x"3E",
x"46",
x"32",
x"C9",
x"14",
x"16",
x"6A",
x"E6",
x"00",
x"01");
    
    signal mc1_r : std_logic;
    signal mc2_r : std_logic_vector(max_number_of_errors_g*2 downto 0);
    signal mc3_r : std_logic;
    signal delta_i_r : finite_field_t;
    signal delta_o_r : finite_field_t;
    signal gamma_r : finite_field_t;
    signal theta_i_r : finite_field_t;
    
   
    
    
    
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
            enable_i => enable_i,
            
            delta_o => delta_o_r,
            gamma_o => gamma_r,
            mc1_o => mc1_r,
            mc2_o => mc2_r,
            mc3_o => mc3_r,
            
            epibma_done_o => epibma_done_o,
            z_o => z_o
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
                enable_i => enable_i,
                
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
                enable_i => enable_i,
                
                omega_o => delta_i_r,
                theta_o => theta_i_r
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
                enable_i => enable_i,
                
                omega_o => omega_array_r(31),
                theta_o => theta_array_r(31)
            );
    
    
    error_locator_poly_o <= (delta_i_r, omega_array_r(0),  omega_array_r(1),  omega_array_r(2),  omega_array_r(3),  omega_array_r(4),
                                        omega_array_r(5),  omega_array_r(6),  omega_array_r(7),  omega_array_r(8),  omega_array_r(9),
                                        omega_array_r(10), omega_array_r(11), omega_array_r(12), omega_array_r(13), omega_array_r(14),  
                                        omega_array_r(15));
                                        
    error_mag_poly_o    <= (theta_i_r,  theta_array_r(0), theta_array_r(1), theta_array_r(2), theta_array_r(3), theta_array_r(4),
                                        theta_array_r(5), theta_array_r(6), theta_array_r(7), theta_array_r(8), theta_array_r(9),
                                        theta_array_r(10), theta_array_r(11), theta_array_r(12), theta_array_r(13), theta_array_r(14));
                                        
  theta_new_array_r <= (syndromes_i(0), syndromes_i(1), syndromes_i(2), syndromes_i(3), 
                        syndromes_i(4), syndromes_i(5), syndromes_i(6), syndromes_i(7),
                        syndromes_i(8), syndromes_i(9), syndromes_i(10), syndromes_i(11),
                        syndromes_i(12), syndromes_i(13), syndromes_i(14), syndromes_i(15),
                        syndromes_i(16), syndromes_i(17), syndromes_i(18), syndromes_i(19),
                        syndromes_i(20), syndromes_i(21), syndromes_i(22), syndromes_i(23),
                        syndromes_i(24), syndromes_i(25), syndromes_i(26), syndromes_i(27),
                        syndromes_i(28), syndromes_i(29), syndromes_i(30), x"00", 
                        x"01") when new_poly_i = '1' else
                        (others => x"00");
                          
                                        
    gamma_o <= gamma_r;                   
end architecture behavioral;

