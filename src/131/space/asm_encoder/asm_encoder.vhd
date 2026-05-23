----------------------------------------------------------------
-- File         : asm_encoder.vhd
-- Created      : 26.03.2026
-- Author       : Hannah Lindner 
-- Project Name : HW/SW Project TM
-- Description  : component to add asm stream after pseudo randomization,
-- ASM Pattern  : 0x1ACFFC1D
----------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity asm_encoder is
    generic(
        asm_pattern_g   : std_logic_vector(31 downto 0) := x"1ACFFC1D"
    );
    port (
        -- input 
        clk_i           : in std_logic; 
        reset_i         : in std_logic;
        
        -- axi stream input 
        s_axi_tvalid    : in std_logic;
        s_axi_tready    : out std_logic; 
        s_axi_tdata     : in std_logic;
        s_axi_tlast     : in std_logic; 

        -- axi stream output
        m_axi_tvalid    : out std_logic; 
        m_axi_tready    : in std_logic;
        m_axi_tdata     : out std_logic;
        m_axi_tlast     : out std_logic
    ); 
end asm_encoder;

architecture behavioral of asm_encoder is

signal counter_r        : integer range 0 to 32 := 0;
signal generate_asm     : std_logic := '0';

begin

P1: process(clk_i,reset_i)
 
begin 
    if reset_i = '0' then 
        -- reset all variables and signals 
        counter_r       <= 0;
        m_axi_tdata     <= '0';
        m_axi_tvalid    <= '0';
        m_axi_tlast     <= '0';
        
    elsif rising_edge(clk_i) then
        if s_axi_tvalid = '1' and m_axi_tready = '1' then 
            m_axi_tdata <= s_axi_tdata;
            m_axi_tlast     <= '0';
            if s_axi_tlast = '1' then 
                generate_asm <= '1';
                s_axi_tready <= '0';
            end if; 
        
        elsif generate_asm = '1' then 
            m_axi_tdata <= asm_pattern_g(31-counter_r);
            counter_r <= counter_r + 1;
            if counter_r = 31 then 
                counter_r <= 0;
                generate_asm <= '0';
                m_axi_tlast <= '1';
            end if; 
        else 
            m_axi_tvalid <= '0';
        end if;
    end if;
    
end process P1; 

end behavioral;
