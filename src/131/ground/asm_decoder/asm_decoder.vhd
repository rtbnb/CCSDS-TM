----------------------------------------------------------------
-- File         : asm_decoder.vhd
-- Created      : 24.04.2025
-- Author       : Hannah Lindner 
-- Project Name : HW/SW Project TM
-- Description  : ASM Pattern decoder, removes asm pattern from bitstream
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity asm_decoder is
    generic (
        asm_pattern_g   : std_logic_vector(31 downto 0) := x"1ACFFC1D"
    );
    port( 
        -- input ports 
        clk_i       : in std_logic; 
        reset_i     : in std_logic; 
        
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
end asm_decoder;

architecture behavioral of asm_decoder is

    signal shift_register_r : std_logic_vector(32 downto 0) := (others => '0'); 
    signal counter_r        : integer range 0 to 33 := 0;
    signal register_full_r  : integer range 0 to 33 := 0;
    signal asm_detected_r   : std_logic := '0'; 

begin

check_for_asm: process(clk_i, reset_i)
  
begin 
    if reset_i = '0' then 
        -- reset all variables and signals 
        m_axi_tdata         <= 'U';
        m_axi_tvalid        <= '0';
        m_axi_tlast         <= '0';
        s_axi_tready        <= '0';
        asm_detected_r      <= '0';
        register_full_r     <= 0;
        counter_r           <= 0;
        shift_register_r    <= (others => '0');
        
    elsif rising_edge(clk_i)then 
        s_axi_tready <= m_axi_tready;
        if s_axi_tvalid = '1' and m_axi_tready = '1' then 
            -- shift register
            register_full_r     <= register_full_r + 1; 
            m_axi_tdata         <= shift_register_r(32);
            shift_register_r    <= shift_register_r(31 downto 0) & s_axi_tdata;
            
            s_axi_tready <= '1';
            if register_full_r = 33 then 
            -- only work if shift register is full 
                register_full_r <= 33;
                
                -- check if asm patter detected 
                if asm_detected_r = '0' then 
                    if shift_register_r(31 downto 0) = asm_pattern_g then
                        asm_detected_r <= '1'; 
                       -- m_axi_tvalid <= '0';
                        m_axi_tlast <= '1';
                       -- m_axi_tdata <= 'U';
                    else 
                        m_axi_tvalid <= '1';
                    end if; 
                    
                elsif asm_detected_r = '1' then 
                -- if asm pattern was already detected, delay data valid flag for 32 cycles 
                    if counter_r = 31 then 
                        counter_r <= 0; 
                        asm_detected_r <= '0'; 
                        --m_axi_tvalid <= '1';
                        m_axi_tlast <= '0';
                    else
                        counter_r <= counter_r + 1; 
                        asm_detected_r <= '1'; 
                        m_axi_tvalid <= '0';
                    end if; 
                end if; -- asm detection
            end if; -- register full check
        end if; -- data valid check
        
    end if; -- reset logic
end process; 

end behavioral;
