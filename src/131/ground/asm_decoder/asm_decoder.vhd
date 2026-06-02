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
        ASM_PATTERN   : std_logic_vector(31 downto 0) := x"1ACFFC1D"; 
        FRAME_LENGTH  : integer := 255
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

-- shift register to detect asm in 
signal shift_register_r : std_logic_vector(32 downto 0) := (others => '0');     
-- counter 
signal counter_r        : integer range 0 to FRAME_LENGTH := 0;
-- flags for datavalid state 
signal s_axi_datavalid_r    : std_logic := '0';
signal m_axi_datavalid_r    : std_logic := '0';
-- additional signals 
signal m_tvalid_r           : std_logic := '0';
signal s_tready_r           : std_logic := '0';
signal detect_asm_r         : std_logic := '0';
signal asm_detected_r       : std_logic := '0'; 
signal register_full_r      : std_logic := '0';

begin

-- asynchronous assignments 
s_axi_datavalid_r     <= s_tready_r and s_axi_tvalid;
m_axi_datavalid_r     <= m_axi_tready and m_tvalid_r;
m_axi_tvalid        <= m_tvalid_r;
s_axi_tready        <= s_tready_r;

check_for_asm: process(clk_i, reset_i)
  
begin 
    if reset_i = '0' then 
        -- reset all variables and signals 
        counter_r           <= 0;
        register_full_r     <= '0'; 
        m_tvalid_r          <= '0'; 
        s_tready_r          <= '0'; 
        
    elsif rising_edge(clk_i)then
        s_tready_r <= m_axi_tready;
        -- valid data on m_axi
        if m_axi_datavalid_r = '1' then
            m_tvalid_r      <= '0';
            m_axi_tlast     <= '0';
            counter_r       <= counter_r + 1;
                       
            -- switch to detect asm after frame length           
            if counter_r = FRAME_LENGTH + 31 then 
                detect_asm_r    <= '1'; 
                counter_r       <= 0; 
            end if;      
            
        -- valid data on s_axi     
        elsif s_axi_datavalid_r = '1' then 
            s_tready_r    <= '0'; 
            -- shift data into register 
            shift_register_r    <= shift_register_r(31 downto 0) & s_axi_tdata;
            if register_full_r = '1' then 
                if detect_asm_r = '1' then 
                    if asm_detected_r = '0' then 
                        -- check for asm pattern in shift register 
                        if (shift_register_r(31 downto 0) = ASM_PATTERN) then 
                            m_axi_tdata <= shift_register_r(32); 
                            asm_detected_r  <= '1'; 
                            m_axi_tlast     <= '1';
                            m_tvalid_r      <= '1';
                            counter_r       <= 0;
                        else 
                        -- if asm is too late 
                            m_axi_tdata <= shift_register_r(32); 
                            m_tvalid_r  <= '1';      
                        end if;  -- check shift register = asm  
                    else 
                        counter_r   <= counter_r + 1; 
                        m_tvalid_r <= '0';
                        if counter_r = 32 then 
                            asm_detected_r  <= '0';
                            detect_asm_r    <= '0';
                        end if;     
                    end if; -- detected asm        
                else 
                    m_axi_tdata <= shift_register_r(32); 
                    m_tvalid_r  <= '1';      
                end if; -- detect asm 
            else 
                counter_r <= counter_r + 1;
                -- logic to check if register is filled, only necessary after reset
                if counter_r = 32 then 
                    register_full_r <= '1';     
                end if;
            end if; -- register full check 
        end if; -- valid data check 
    end if; -- reset logic
    
end process; 

end behavioral;
