----------------------------------------------------------------
-- File : reed_solomon_encoder_tb.vhd
-- Created : 18.11.2025
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : Testbench for R/S Encoder
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_encoder_tb is
end entity reed_solomon_encoder_tb;

architecture behavioral of reed_solomon_encoder_tb is

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

    signal clk_r : STD_LOGIC := '1';
    signal reset_r : STD_LOGIC := '1';

-- axi inputs 
signal s_axi_tvalid_r    : std_logic; 
signal s_axi_tready_r    : std_logic;
signal s_axi_tdata_r     : std_logic_vector(7 downto 0);
signal s_axi_tlast_r     : std_logic;

-- axi outputs
signal m_axi_tvalid_r    : std_logic; 
signal m_axi_tready_r    : std_logic:='0';
signal m_axi_tdata_r     : std_logic_vector(7 downto 0);
signal m_axi_tlast_r     : std_logic;

begin
    dut : reed_solomon_encoder
    port map (
      clk_i       => clk_r,
      reset_i     => reset_r,
      
  -- axi inputs 
    s_axi_tvalid    =>  s_axi_tvalid_r,
    s_axi_tready    =>  s_axi_tready_r,
    s_axi_tdata     =>  s_axi_tdata_r,
    s_axi_tlast     =>  s_axi_tlast_r,

    -- axi outputs
    m_axi_tvalid    =>  m_axi_tvalid_r,
    m_axi_tready    =>  m_axi_tready_r,
    m_axi_tdata     =>  m_axi_tdata_r,
    m_axi_tlast     =>  m_axi_tlast_r
    );
    
    tready_flag: process
    
    begin
        m_axi_tready_r <= '1';
        wait until m_axi_tvalid_r = '1';
        m_axi_tready_r <= '0';
        wait for 160 ns;
        
    end process tready_flag;

    
    clk_r <= not clk_r after 5 ns;
    
    stimuli: process
        variable data_write_r : integer range 0 to 255 := 0;
    begin
        wait until s_axi_tready_r = '1';
        s_axi_tdata_r <= std_logic_vector(to_unsigned(data_write_r, 8));
        s_axi_tvalid_r <= '1';
        data_write_r:= data_write_r + 1;
        
        if data_write_r >= 223 then
            data_write_r := 0;
        end if;
        
        wait for 10 ns;
        s_axi_tvalid_r <= '0';        
    end process stimuli;


end architecture;