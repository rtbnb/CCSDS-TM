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
        reed_solomon_failure_o : out std_logic; 

        -- axi inputs 
        s_axi_tvalid    : in std_logic; 
        s_axi_tready    : out std_logic;
        s_axi_tdata     : in std_logic_vector(7 downto 0);
        s_axi_tlast     : in std_logic;

        -- axi outputs
        m_axi_tvalid    : out std_logic; 
        m_axi_tready    : in std_logic;
        m_axi_tdata     : out std_logic_vector(7 downto 0);
        m_axi_tlast     : out std_logic 
    );
end entity reed_solomon_decoder_top;

architecture behavioral of reed_solomon_decoder_top is
    signal rs_input_byte_r          : std_logic_vector(7 downto 0);
    signal rs_data_valid_in_r       : std_logic;
    signal rs_asm_done_r            : std_logic;
    
    signal rs_data_valid_out_r      : std_logic;
    signal rs_output_byte_r         : std_logic_vector(7 downto 0);
    

    signal synmdrome_valid_r        : std_logic;
    signal syndrome_r               : finite_field_syndrome_t;
    signal epibma_done_r            : std_logic;
    signal error_locator_poly_r     : finite_field_error_locator_t;
    signal error_mag_poly_r         : finite_field_error_mag_t;
    signal z_r                      : finite_field_t;
    signal gamma_r                  : finite_field_t;
    signal error_found_r            : std_logic;
    signal error_mag_r              : finite_field_t;
    signal fifo_output_r            : finite_field_t;
    signal fifo_data_valid_r        : std_logic;
    signal error_locator_poly_len_r : integer range 0 to max_number_of_errors_g;
    
begin
    
    reed_solomon_decoder_axi_stream_inst: entity work.reed_solomon_decoder_axi_stream
        port map(
            clk_i               => clk_i,
            reset_i             => reset_i,
            
            rs_input_byte_o     => rs_input_byte_r,
            rs_data_valid_in_o  => rs_data_valid_in_r,
            rs_asm_done_o       => rs_asm_done_r,
            
            rs_data_valid_out_i => rs_data_valid_out_r,
            rs_output_byte_i    => rs_output_byte_r,
            
            -- axi inputs 
            s_axi_tvalid    => s_axi_tvalid,
            s_axi_tready    => s_axi_tready,
            s_axi_tdata     => s_axi_tdata,
            s_axi_tlast     => s_axi_tlast,
    
            -- axi outputs
            m_axi_tvalid    => m_axi_tvalid,
            m_axi_tready    => m_axi_tready,
            m_axi_tdata     => m_axi_tdata,
            m_axi_tlast     => m_axi_tlast
        );
    
    reed_solomon_decoder_fifo_inst: entity work.reed_solomon_decoder_fifo
        port map (
            clk_i   => clk_i,
            reset_i => reset_i,
            input_byte_i => rs_input_byte_r,
            data_valid_i => rs_data_valid_in_r,
    
            data_valid_o  => fifo_data_valid_r,
            output_byte_o => fifo_output_r
        );
        
     reed_solomon_decoder_syndrome_inst: entity work.reed_solomon_decoder_syndrome
        port map (
             clk_i => clk_i,                   
             reset_i => reset_i,                
             asm_done_i => rs_asm_done_r,           
             data_i  => rs_input_byte_r,            
             data_valid_i => rs_data_valid_in_r,
             syndrome_valid_o  => synmdrome_valid_r,      
             syndrome_o => syndrome_r   
        );
     
     reed_solomon_decoder_epibma_top_inst: entity  work.reed_solomon_decoder_epibma_top
        port map (
            clk_i => clk_i,
            reset_i => reset_i,
            new_poly_i => synmdrome_valid_r,
            enable_i   => rs_data_valid_in_r,
            syndromes_i  => syndrome_r,
            
            z_o => z_r,
            gamma_o => gamma_r, 
            
            epibma_done_o => epibma_done_r,
            error_locator_poly_o => error_locator_poly_r,
            error_mag_poly_o => error_mag_poly_r,
            error_locator_poly_len_o => error_locator_poly_len_r
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
            enable_i        => rs_data_valid_in_r,
            
            error_found_o   => error_found_r,
            error_mag_o     => error_mag_r,
            decoder_fail_o  => reed_solomon_failure_o,
            err_locator_poly_len_i => error_locator_poly_len_r
        );
        
     rs_output_byte_r <= gf_add(fifo_output_r, error_mag_r) when error_found_r = '1' else
                     fifo_output_r;
                     
     rs_data_valid_out_r <= fifo_data_valid_r;
                     
                    
end architecture behavioral;
