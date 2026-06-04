----------------------------------------------------------------
-- File         : axi_width_converter_8_to_1.vhd
-- Created      : 02.06.2026
-- Author       : Hannah Lindner 
-- Project Name : HW/SW Project TM
-- Description  : axi stream width converter 8 bit to 1 bits 
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi_width_converter_8_to_1 is 
port(
    -- control signals
    clk_i   : in std_logic; 
    reset_i : in std_logic; 
    -- s axi intputs 
    s_axi_tvalid : in std_logic; 
    s_axi_tready : out std_logic; 
    s_axi_tdata  : in std_logic_vector(7 downto 0); 
    s_axi_tlast  : in std_logic; 
    -- m axi outputs
    m_axi_tvalid    : out std_logic; 
    m_axi_tready    : in std_logic; 
    m_axi_tdata     : out std_logic; 
    m_axi_tlast     : out std_logic
); 
end entity axi_width_converter_8_to_1;

architecture behavioral of axi_width_converter_8_to_1 is

signal data_register_r  : std_logic_vector(7 downto 0);
-- counter 
signal counter_r        : integer range 0 to 8 := 0;
-- flags for datavalid state 
signal s_axi_datavalid_r  : std_logic := '0';
signal m_axi_datavalid_r  : std_logic := '0';
-- additional signals 
signal m_tvalid_r         : std_logic := '0';
signal s_tready_r         : std_logic := '0';
signal m_tlast            : std_logic := '0';
signal output_data_r      : std_logic := '0';

begin 

-- asynchronous assignments 
s_axi_datavalid_r     <= s_tready_r and s_axi_tvalid;
m_axi_datavalid_r     <= m_axi_tready and m_tvalid_r;

m_axi_tvalid          <= m_tvalid_r;
s_axi_tready          <= s_tready_r;

width_conversion: process (clk_i, reset_i)
begin 

if reset_i = '0' then
    -- reset necessary signals and counters  
    data_register_r <= (others => 'U');
    m_tvalid_r      <= '0';
    counter_r       <= 0;
    m_tlast         <= '0';
    
elsif rising_edge(clk_i) then 
    s_tready_r      <= m_axi_tready;
    
    if m_axi_datavalid_r = '1' then
    -- written valid data  
        m_tvalid_r <= '0';
        m_axi_tlast <= '0';
        if output_data_r = '1' then 
           s_tready_r <= '0';
           counter_r <= counter_r + 1; 
        end if; 
        
        
    elsif output_data_r = '1' then 
    -- output bits
        m_axi_tdata <= data_register_r (8-counter_r-1);
        m_tvalid_r <= '1';
        s_tready_r <= '0';
        
        if counter_r = 7 then 
           output_data_r <= '0';
           counter_r <= 0;
           m_axi_tlast <= m_tlast;
           s_tready_r      <= m_axi_tready;
        end if; 
        
    elsif s_axi_datavalid_r = '1' then 
    -- read valid data 
        data_register_r             <= s_axi_tdata; 
        s_tready_r                  <= '0';
        output_data_r               <= '1'; 
        m_tlast                     <= s_axi_tlast;
        m_axi_tdata                 <= s_axi_tdata (8-counter_r-1);
        m_tvalid_r                  <= '1';
        
        
    end if;   
end if; 

end process width_conversion; 


end behavioral;