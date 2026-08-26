
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity tb_asm_hamming_distance is
--  Port ( );
end tb_asm_hamming_distance;

architecture Test of tb_asm_hamming_distance is

-- signals 
signal        clk_i       : std_logic := '0'; 
signal        reset_i     : std_logic := '0'; 
        -- axi stream input 
signal        s_axis_tvalid    : std_logic; 
signal        s_axis_tready    : std_logic; 
signal        s_axis_tdata     : std_logic; 
signal        s_axis_tlast     : std_logic := '0'; 
        -- axi stream output  
signal        m_axis_tvalid    : std_logic;
signal        m_axis_tready    : std_logic; 
signal        m_axis_tdata     : std_logic;
signal        m_axis_tlast     : std_logic;

-- other signals 
signal ASM_PATTERN : std_logic_vector(31 downto 0) := "00011010110010011111110000011101";
      
begin

-- clock and reset behaviour 
clk_i   <= not clk_i after 10 ns; 
reset_i <= '1' after 100 ns; 

-- component instantiation
asm_inst: entity  work.asm_decoder 
--    generic map(
--        ASM_PATTERN   => "1ACFFC1D",
--        FRAME_LENGTH  => 10
--    )
    port map( 
        -- input ports 
        clk_i           => clk_i,
        reset_i         => reset_i,
        -- axi stream input 
        s_axi_tvalid    => s_axis_tvalid,
        s_axi_tready    => s_axis_tready,
        s_axi_tdata     => s_axis_tdata,
        s_axi_tlast     => s_axis_tlast,
        -- axi stream output  
        m_axi_tvalid    => m_axis_tvalid,
        m_axi_tready    => m_axis_tready,
        m_axi_tdata     => m_axis_tdata,
        m_axi_tlast     => m_axis_tlast
    );

-- stimulus 
stimulus: process 
begin 
    wait for 50 ns; 
    -- write ones into the ASM gen 
    m_axis_tready <= '1'; 
    s_axis_tvalid <= '1'; 
    s_axis_tdata <= '1';
    wait for 1000 ns; 
    
    for i in 0 to 31 loop
        s_axis_tdata <= ASM_PATTERN(31-i);
        wait for 40ns;
    end loop; 
    
end process; 


end Test;
