----------------------------------------------------------------
-- File : reed_solomon_decoder_top_tb.vhd
-- Created : 20.05.2026
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : Testbench full R/S Decoder
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.uniform;
use ieee.math_real.floor;

use work.finite_field.all;

entity reed_solomon_decoder_top_tb is
end entity reed_solomon_decoder_top_tb;

architecture behavioral of reed_solomon_decoder_top_tb is
    component reed_solomon_encoder is
    port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        
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
    end component;

    component reed_solomon_decoder_top is
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
    end component;
    
    type random_index_t is array (0 to 17) of Integer range 0 to 257;

    signal        clk_r                   : std_logic := '0';
    signal        reset_r                 : std_logic := '1';
    
    
    signal        input_value_r           : Integer range 0 to 300 := 1;
    signal        sync_fifo_val_r         : std_logic_vector (7 downto 0);
    signal        reed_solomon_failure_r  : std_logic;
    signal        random_index_r          : random_index_t;
    signal        random_error_mag_r      : random_index_t;
    
    
    
    
    -- axi inputs to encoder
    signal encoder_s_axi_tvalid_r    :  std_logic; 
    signal encoder_s_axi_tready_r    :  std_logic;
    signal encoder_s_axi_tdata_r     :  std_logic_vector(7 downto 0);
    signal encoder_s_axi_tlast_r     :  std_logic;
    
    -- axi outputs from encoder
    signal encoder_m_axi_tvalid_r    : std_logic; 
    signal encoder_m_axi_tready_r    : std_logic;
    signal encoder_m_axi_tdata_r     : std_logic_vector(7 downto 0);
    signal encoder_m_axi_tlast_r     : std_logic;
    
    -- axi inputs to decoder 
    signal decoder_s_axi_tvalid_r    : std_logic; 
    signal decoder_s_axi_tready_r    : std_logic;
    signal decoder_s_axi_tdata_r     : std_logic_vector(7 downto 0);
    signal decoder_s_axi_tlast_r     : std_logic;
    
    -- axi outputs from decoder
    signal decoder_m_axi_tvalid_r    : std_logic; 
    signal decoder_m_axi_tready_r    : std_logic;
    signal decoder_m_axi_tdata_r     : std_logic_vector(7 downto 0);
    signal decoder_m_axi_tlast_r     : std_logic;
    
begin

    dut_enccoder : reed_solomon_encoder
    port map (
        clk_i   => clk_r,
        reset_i => reset_r,
        
        -- axi inputs 
        s_axi_tvalid    => encoder_s_axi_tvalid_r,
        s_axi_tready    => encoder_s_axi_tready_r,
        s_axi_tdata     => encoder_s_axi_tdata_r,
        s_axi_tlast     => encoder_s_axi_tlast_r,

        -- axi outputs
        m_axi_tvalid    => encoder_m_axi_tvalid_r,
        m_axi_tready    => encoder_m_axi_tready_r,
        m_axi_tdata     => encoder_m_axi_tdata_r,
        m_axi_tlast     => encoder_m_axi_tlast_r
    );

    dut_decoder : reed_solomon_decoder_top
    port map (
        clk_i   => clk_r,
        reset_i => reset_r,
        reed_solomon_failure_o => reed_solomon_failure_r,

        -- axi inputs 
        s_axi_tvalid    => decoder_s_axi_tvalid_r,
        s_axi_tready    => decoder_s_axi_tready_r,
        s_axi_tdata     => decoder_s_axi_tdata_r,
        s_axi_tlast     => decoder_s_axi_tlast_r,

        -- axi outputs
        m_axi_tvalid    => decoder_m_axi_tvalid_r,
        m_axi_tready    => decoder_m_axi_tready_r,
        m_axi_tdata     => decoder_m_axi_tdata_r,
        m_axi_tlast     => decoder_m_axi_tlast_r
    );
           
    clk_r <= not clk_r after 5 ns;
    
    decoder_m_axi_tready_r <= '1';
    decoder_s_axi_tvalid_r <= encoder_m_axi_tvalid_r;
    encoder_m_axi_tready_r <= decoder_s_axi_tready_r;
    decoder_s_axi_tlast_r <= encoder_m_axi_tlast_r;
    

    
    data_valid_stimuli: process
    begin
        for i in 0 to 255 loop
            wait until encoder_s_axi_tready_r = '1';
            encoder_s_axi_tdata_r   <= std_logic_vector(to_unsigned(i, 8));
            input_value_r <= i;
            encoder_s_axi_tvalid_r  <= '1';
            wait until encoder_s_axi_tready_r = '0';
            encoder_s_axi_tvalid_r <= '0';
        end loop;

    end process data_valid_stimuli;
    
    -- only for test
    new_random_data: process
        variable seed1 : positive;
        variable seed2 : positive;
        variable x : real;
        variable y : integer;
    begin
        if encoder_m_axi_tlast_r = '1' then
            -- between 0 and 17 erros
            uniform(seed1, seed2, x);
            y := integer(floor(x * 17));
            for n in 0 to y loop
              uniform(seed1, seed2, x);
              random_index_r(n) <= integer(floor(x * 255));
              --random_index_r(n) <= n+10;
            end loop;
            
            for n in y to 17 loop 
                random_index_r(n) <= 257;
            end loop;
            
            for n in 0 to 17 loop
              uniform(seed1, seed2, x);
              random_error_mag_r(n) <= integer(floor(x * 255));
            end loop;
        end if;
        wait for 10 ns;
    
    end process new_random_data;
    
    
    decoder_s_axi_tdata_r <= std_logic_vector(TO_UNSIGNED(random_error_mag_r(0),8)) when input_value_r = random_index_r(0) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(1),8)) when input_value_r = random_index_r(1) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(2),8)) when input_value_r = random_index_r(2) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(3),8)) when input_value_r = random_index_r(3) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(4),8)) when input_value_r = random_index_r(4) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(5),8)) when input_value_r = random_index_r(5) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(6),8)) when input_value_r = random_index_r(6) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(7),8)) when input_value_r = random_index_r(7) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(8),8)) when input_value_r = random_index_r(8) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(9),8)) when input_value_r = random_index_r(9) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(10),8)) when input_value_r = random_index_r(10) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(11),8)) when input_value_r = random_index_r(11) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(12),8)) when input_value_r = random_index_r(12) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(13),8)) when input_value_r = random_index_r(13) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(14),8)) when input_value_r = random_index_r(14) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(15),8)) when input_value_r = random_index_r(15) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(16),8)) when input_value_r = random_index_r(16) else
                           std_logic_vector(TO_UNSIGNED(random_error_mag_r(17),8)) when input_value_r = random_index_r(17) else
                           encoder_m_axi_tdata_r;

    --sync_fifo_val_r <= output_byte_r  when  data_valid_decoder_r = '1' else
    --                    sync_fifo_val_r;          
    

end architecture;