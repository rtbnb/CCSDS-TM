

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi_ccsds_131_space is
    Port ( 
    -- control signals 
    clk_i   : in std_logic; 
    rst_i   : in std_logic;
    -- s_axi signals 
    s_axi_tvalid    : in std_logic; 
    s_axi_tready    : out std_logic; 
    s_axi_tdata     : in std_logic_vector(7 downto 0); 
    s_axi_tlast     : in std_logic;
    -- m_axi signals 
    m_axi_tvalid    : out std_logic; 
    m_axi_tready    : in std_logic; 
    m_axi_tdata     : out std_logic
    );
end axi_ccsds_131_space;

architecture connectivity of axi_ccsds_131_space is

-- signals to connect reed solomon encoder with width converter
signal    reedsolomon_axi_tvalid    : std_logic; 
signal    reedsolomon_axi_tready    : std_logic; 
signal    reedsolomon_axi_tdata     : std_logic_vector(7 downto 0); 
signal    reedsolomon_axi_tlast     : std_logic;

-- signals to connect width-converter to pseudo_randomizer 
signal    widthconvrt_axi_tvalid    : std_logic; 
signal    widthconvrt_axi_tready    : std_logic; 
signal    widthconvrt_axi_tdata     : std_logic; 
signal    widthconvrt_axi_tlast     : std_logic;

-- signals to connect pseudo randomizer to asm encoder 
signal    pseudorand_axi_tvalid    : std_logic; 
signal    pseudorand_axi_tready    : std_logic; 
signal    pseudorand_axi_tdata     : std_logic; 
signal    pseudorand_axi_tlast     : std_logic;

-- signals to map asm encoder to convolutional encoder
signal    asm_axi_tvalid    : std_logic; 
signal    asm_axi_tready    : std_logic; 
signal    asm_axi_tdata     : std_logic; 
signal    asm_axi_tlast     : std_logic;

begin

reed_solomon_encoder_inst : entity work.reed_solomon_encoder
    generic map(
        USE_DUAL_BASIS => FALSE
    )
    port map (
        clk_i   => clk_i,
        reset_i => rst_i,
        
        -- axi inputs 
        s_axi_tvalid    => s_axi_tvalid,
        s_axi_tready    => s_axi_tready,
        s_axi_tdata     => s_axi_tdata,
        s_axi_tlast     => s_axi_tlast,

        -- axi outputs
        m_axi_tvalid    => reedsolomon_axi_tvalid,
        m_axi_tready    => reedsolomon_axi_tready,
        m_axi_tdata     => reedsolomon_axi_tdata,
        m_axi_tlast     => reedsolomon_axi_tlast
    );

width_converter_inst : entity work.axi_width_converter_8_to_1
    port map (
        -- control signals
        clk_i   => clk_i,
        reset_i => rst_i,
        -- s axi intputs 
        s_axi_tvalid => reedsolomon_axi_tvalid,
        s_axi_tready => reedsolomon_axi_tready,
        s_axi_tdata  => reedsolomon_axi_tdata,
        s_axi_tlast  => reedsolomon_axi_tlast,
        -- m axi outputs
        m_axi_tvalid    => widthconvrt_axi_tvalid,
        m_axi_tready    => widthconvrt_axi_tready,
        m_axi_tdata     => widthconvrt_axi_tdata,
        m_axi_tlast     => widthconvrt_axi_tlast
    );
    
pseudorandomizer_inst : entity work.pseudo_randomizer_entity
    port map (
            -- input ports 
        clk_i           => clk_i,
        reset_i         => rst_i,
        -- axi intput ports 
        s_axi_tvalid     => widthconvrt_axi_tvalid,
        s_axi_tready     => widthconvrt_axi_tready,
        s_axi_tdata      => widthconvrt_axi_tdata,
        s_axi_tlast      => widthconvrt_axi_tlast,
        
        -- axi output ports 
        m_axi_tvalid     => pseudorand_axi_tvalid,
        m_axi_tready     => pseudorand_axi_tready,
        m_axi_tdata      => pseudorand_axi_tdata,
        m_axi_tlast      => pseudorand_axi_tlast
    ); 

asm_encoder_inst : entity work.asm_encoder
    generic map (
        ASM_PATTERN   => x"1ACFFC1D"
    )
    port map (
        -- input 
        clk_i           => clk_i,
        reset_i         => rst_i,
        
        -- axi stream input 
        s_axi_tvalid    => pseudorand_axi_tvalid,
        s_axi_tready    => pseudorand_axi_tready,
        s_axi_tdata     => pseudorand_axi_tdata,
        s_axi_tlast     => pseudorand_axi_tlast,

        -- axi stream output
        m_axi_tvalid    => asm_axi_tvalid,
        m_axi_tready    => asm_axi_tready,
        m_axi_tdata     => asm_axi_tdata,
        m_axi_tlast     => asm_axi_tlast
    );

convolutional_encoder_inst : entity work.convolutional_encoder
    generic map(
        K           => 7,
        G1          => 8#171#,
        G2          => 8#133#,
        INVERT_MASK => "10"
    )
    port map(
        clk_i               => clk_i,
        reset_i             => rst_i,

        s_axis_tdata(0)     => asm_axi_tdata,
        s_axis_tvalid       => asm_axi_tvalid,
        s_axis_tready       => asm_axi_tready,

        m_axis_tdata(0)     => m_axi_tdata,
        m_axis_tvalid       => m_axi_tvalid,
        m_axis_tready       => m_axi_tready
    );


end connectivity;
