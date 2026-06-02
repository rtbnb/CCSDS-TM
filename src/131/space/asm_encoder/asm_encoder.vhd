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
        ASM_PATTERN   : std_logic_vector(31 downto 0) := x"1ACFFC1D"
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

-- counter 
signal counter_r        : integer range 0 to 32 := 0;
-- flags for datavalid state 
signal s_axi_datavalid_r  : std_logic := '0';
signal m_axi_datavalid_r  : std_logic := '0';
-- additional signals 
signal m_tvalid_r         : std_logic := '0';
signal s_tready_r         : std_logic := '0';
signal generate_asm_r     : std_logic := '0';


begin

-- asynchronous assignments 
s_axi_datavalid_r     <= s_tready_r and s_axi_tvalid;
m_axi_datavalid_r     <= m_axi_tready and m_tvalid_r;
m_axi_tvalid          <= m_tvalid_r;
s_axi_tready          <= s_tready_r;



asm_encoding: process(clk_i,reset_i)
begin 
    if reset_i = '0' then 
        -- reset counter 
        counter_r       <= 0;
        -- reset axi signals 
        m_tvalid_r        <= '0';
        s_tready_r        <= '0';
        
    elsif rising_edge(clk_i) then
        -- reset data valid flags 
        s_tready_r    <=  m_axi_tready;
        
        -- valid data on m_axi
        if m_axi_datavalid_r = '1' then
            m_tvalid_r        <= '0';
            m_axi_tlast      <= '0';
            
            if generate_asm_r = '1' then 
                counter_r <= counter_r + 1;
                s_tready_r    <='0';
                -- check if entire asm is generated 
                if counter_r = 32 then 
                    counter_r       <= 0;
                    generate_asm_r    <= '0';
                end if; -- counter logic 
            end if; -- asm counter 
        
        -- valid data on s_axi     
        elsif generate_asm_r = '1' then 
            m_tvalid_r        <= '1';
            s_tready_r        <= '0';
            m_axi_tdata     <= ASM_PATTERN(32-counter_r); 
            
        elsif s_axi_datavalid_r = '1' then 
            m_tvalid_r        <= '1';
            s_tready_r        <= '0';
            m_axi_tdata     <= s_axi_tdata;
            if s_axi_tlast = '1' then
                generate_asm_r <= '1';     
            end if; -- tlast check 
        end if;  -- data valid checks        
    end if; -- reset & rising edge logic
end process; --asm_encoding 

end behavioral;
