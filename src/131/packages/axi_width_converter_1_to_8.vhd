----------------------------------------------------------------
-- File         : axi_width_converter_1_to_8.vhd
-- Created      : 02.06.2026
-- Author       : Hannah Lindner 
-- Project Name : HW/SW Project TM
-- Description  : axi stream width converter 1 bit to 8 bits 
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi_width_converter_1_to_8 is 
port(
    -- control signals
    clk_i   : in std_logic; 
    reset_i : in std_logic; 
    -- s axi intputs 
    s_axi_tvalid : in std_logic; 
    s_axi_tready : out std_logic; 
    s_axi_tdata  : in std_logic; 
    s_axi_tlast  : in std_logic; 
    -- m axi outputs
    m_axi_tvalid    : out std_logic; 
    m_axi_tready    : in std_logic; 
    m_axi_tdata     : out std_logic_vector(7 downto 0);
    m_axi_tlast     : out std_logic
); 
end entity axi_width_converter_1_to_8;

architecture behavioral of axi_width_converter_1_to_8 is

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

begin 

-- asynchronous assignments 
s_axi_datavalid_r     <= s_tready_r and s_axi_tvalid;
m_axi_datavalid_r     <= m_axi_tready and m_tvalid_r;

m_axi_tvalid          <= m_tvalid_r;
s_axi_tready          <= s_tready_r;

m_axi_tlast           <= m_tlast;

width_conversion: process (clk_i, reset_i)
begin 

if reset_i = '0' then
    -- reset necessary signals and counters  
    data_register_r <= (others => 'U');
    m_tvalid_r      <= '0';
    counter_r       <= 0;
    m_tlast         <= '0';
    
elsif rising_edge(clk_i) then 

    --s_tready_r      <= m_axi_tready;
    if m_axi_datavalid_r = '1' then
    -- written valid data  
        m_tvalid_r      <= '0';
        m_tlast         <= '0';
        s_tready_r      <= m_axi_tready;
        --m_axi_tdata     <= data_register_r;
        counter_r       <= 0;
        
    elsif s_axi_datavalid_r = '0' and counter_r <= 7 then 
        s_tready_r      <= m_axi_tready;
                
    elsif s_axi_datavalid_r = '1' then 
    -- read valid data 
        s_tready_r                  <= '0'; 
        m_tlast                     <= m_tlast OR s_axi_tlast;
        data_register_r(8-counter_r-1)  <= s_axi_tdata;
        counter_r       <= counter_r + 1;
        
        if counter_r = 7 then 
            m_tvalid_r      <= '1';
            m_axi_tdata     <= data_register_r(7 downto 1) & s_axi_tdata;
        end if; 
    end if;
    
end if; 

end process width_conversion; 


end behavioral;