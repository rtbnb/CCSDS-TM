----------------------------------------------------------------
-- File         : pseudo_randomizer_component.vhd
-- Created      : 28.11.2025
-- Author       : Hannah Lindner 
-- Project Name : HW/SW Project TM
-- Description  : component of pseudorandomizer, polynomial h(x) = x^17 + x^14 + 1
----------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity pseudo_randomizer is 
    port(
        -- input ports 
        clk_i           : in std_logic; 
        reset_i         : in std_logic;
        -- axi intput ports 
        s_axi_tvalid    : in std_logic; 
        s_axi_tready    : out std_logic; 
        s_axi_tdata     : in std_logic; 
        s_axi_tlast     : in std_logic; 
        
        -- axi output ports 
        m_axi_tvalid    : out std_logic; 
        m_axi_tready    : in std_logic;
        m_axi_tdata     : out std_logic; 
        m_axi_tlast     : out std_logic
    );
end entity pseudo_randomizer; 


architecture behavioral of pseudo_randomizer is 
    constant INIT_SEQUENCE          : std_logic_vector(16 downto 0) := "11000111000111000"; 
    signal randomization_sequence_r : std_logic_vector(16 downto 0) := INIT_SEQUENCE;
begin 

    -- process to generate the random sequence and XOR it with input data 
    generate_randomization : process (clk_i, reset_i)
        variable new_element_s      : std_logic;
        variable new_vector_long_s  : std_logic_vector(17 downto 0);
    begin 
        if reset_i = '0' then 
            -- reset signals 
            -- check if encoder done, set data valid accordingly 
            m_axi_tvalid                <= '0';
            m_axi_tlast                 <= '0';
            m_axi_tdata                 <= '0';
            randomization_sequence_r    <= INIT_SEQUENCE;
            -- reset variables  
            new_element_s               := '0'; 
            new_vector_long_s           := (others => '0');

        elsif rising_edge(clk_i) then
            -- XOR data 
            m_axi_tdata     <= s_axi_tdata XOR randomization_sequence_r(0);
            m_axi_tvalid    <= '1';
            m_axi_tlast     <= '0';
            
            -- generate new element + shift vector 
            new_element_s := randomization_sequence_r(0) XOR randomization_sequence_r(14);
            new_vector_long_s := new_element_s & randomization_sequence_r;
            randomization_sequence_r <= new_vector_long_s(17 downto 1); 
            
            if s_axi_tlast = '1' then 
                m_axi_tlast <= '1'; 
                randomization_sequence_r <= INIT_SEQUENCE;
            end if; 
            
        end if; -- rising edge logic 
    end process generate_randomization;

end architecture behavioral;