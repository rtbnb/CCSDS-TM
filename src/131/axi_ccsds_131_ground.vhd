
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi_ccsds_131_ground is
    Port ( 
    -- control signals 
    clk_i   : in std_logic; 
    rst_i   : in std_logic;
    reed_solomon_failure_o : out std_logic; 
    -- s_axi signals 
    s_axi_tvalid    : in std_logic; 
    s_axi_tready    : out std_logic; 
    s_axi_tdata     : in std_logic; 
    -- m_axi signals 
    m_axi_tvalid    : out std_logic; 
    m_axi_tready    : in std_logic; 
    m_axi_tdata     : out std_logic_vector(31 downto 0);
    m_axi_tlast     : out std_logic
    );
end axi_ccsds_131_ground;

architecture connectivity of axi_ccsds_131_ground is

-- signals to connect viterbi decoder to asm deletion
signal    viterbi_axi_tvalid    : std_logic; 
signal    viterbi_axi_tready    : std_logic; 
signal    viterbi_axi_tdata     : std_logic; 
signal    viterbi_axi_tlast     : std_logic;

-- signals to map asm decoder to pseudorandomizer
signal    asm_axi_tvalid    : std_logic; 
signal    asm_axi_tready    : std_logic; 
signal    asm_axi_tdata     : std_logic; 
signal    asm_axi_tlast     : std_logic;

-- signals to connect pseudo randomizer to width converter 
signal    pseudorand_axi_tvalid    : std_logic; 
signal    pseudorand_axi_tready    : std_logic; 
signal    pseudorand_axi_tdata     : std_logic; 
signal    pseudorand_axi_tlast     : std_logic;

-- signals to connect width-converter to reed solomon decoder 
signal    widthconvrt_axi_tvalid    : std_logic; 
signal    widthconvrt_axi_tready    : std_logic; 
signal    widthconvrt_axi_tdata     : std_logic_vector(7 downto 0); 
signal    widthconvrt_axi_tlast     : std_logic;

signal    reedsolomon_axi_tdata    : std_logic_vector(7 downto 0);
signal    m_tvalid                  : std_logic; 

begin

viterbi_decoder_inst : entity work.viterbi_decoder 
    port map(
        clk_i   => clk_i,
        reset_i => rst_i,

        -- Convolutional encoded data input
        convolutional_data_tdata    => s_axi_tdata,
        convolutional_data_tvalid   => s_axi_tvalid,
        convolutional_data_tready   => s_axi_tready,

        -- Data output from Viterbi decoder
        decoded_data_tdata  => viterbi_axi_tdata,
        decoded_data_tvalid => viterbi_axi_tvalid,
        decoded_data_tready => viterbi_axi_tready,
        decoded_data_tlast  => viterbi_axi_tlast
    );

asm_decoder_inst : entity work.asm_decoder
    generic map(
        ASM_PATTERN   => x"1ACFFC1D", 
        FRAME_LENGTH  => 255*8
    )
    port map( 
        -- input ports 
        clk_i       => clk_i,
        reset_i     => rst_i, 
        
        -- axi stream input 
        s_axi_tvalid    => viterbi_axi_tvalid,
        s_axi_tready    => viterbi_axi_tready,
        s_axi_tdata     => viterbi_axi_tdata,
        s_axi_tlast     => viterbi_axi_tlast,
         
        -- axi stream output  
        m_axi_tvalid    => asm_axi_tvalid,
        m_axi_tready    => asm_axi_tready, 
        m_axi_tdata     => asm_axi_tdata,
        m_axi_tlast     => asm_axi_tlast
    );

pseudorandomizer_inst : entity work.pseudo_randomizer_entity
    port map (
            -- input ports 
        clk_i           => clk_i,
        reset_i         => rst_i,
        -- axi intput ports 
        s_axi_tvalid     => asm_axi_tvalid,
        s_axi_tready     => asm_axi_tready,
        s_axi_tdata      => asm_axi_tdata,
        s_axi_tlast      => asm_axi_tlast,
        
        -- axi output ports 
        m_axi_tvalid     => pseudorand_axi_tvalid,
        m_axi_tready     => pseudorand_axi_tready,
        m_axi_tdata      => pseudorand_axi_tdata,
        m_axi_tlast      => pseudorand_axi_tlast
    ); 

width_converter_inst : entity  work.axi_width_converter_1_to_8
port map(
    -- control signals
    clk_i   => clk_i,
    reset_i => rst_i,
    -- s axi intputs 
    s_axi_tvalid => pseudorand_axi_tvalid,
    s_axi_tready => pseudorand_axi_tready,
    s_axi_tdata  => pseudorand_axi_tdata,
    s_axi_tlast  => pseudorand_axi_tlast,
    -- m axi outputs
    m_axi_tvalid    => widthconvrt_axi_tvalid,
    m_axi_tready    => widthconvrt_axi_tready,
    m_axi_tdata     => widthconvrt_axi_tdata,
    m_axi_tlast     => widthconvrt_axi_tlast
); 

reed_solomon_decoder_inst : entity work.reed_solomon_decoder_top
generic map(
    max_number_of_errors_g => 16
)
port map(
    clk_i   => clk_i,
    reset_i => rst_i,
    reed_solomon_failure_o => reed_solomon_failure_o,

    -- axi inputs 
    s_axi_tvalid    => widthconvrt_axi_tvalid,
    s_axi_tready    => widthconvrt_axi_tready,
    s_axi_tdata     => widthconvrt_axi_tdata,
    s_axi_tlast     => widthconvrt_axi_tlast, 

    -- axi outputs
    m_axi_tvalid    => m_tvalid,
    m_axi_tready    => m_axi_tready,
    m_axi_tdata     => reedsolomon_axi_tdata,
    m_axi_tlast     => open
);


m_axi_tdata <= x"000000" & reedsolomon_axi_tdata;
m_axi_tlast     <= m_tvalid;
m_axi_tvalid    <= m_tvalid;


end connectivity;
