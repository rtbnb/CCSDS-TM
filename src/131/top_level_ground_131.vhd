-- top level module CCSDS 131 ground

library ieee; 
use ieee.std_logic_1164.all; 

entity ccsds_131_ground is
port(
    -- inputs 
    clk_i               : in std_logic; 
    reset_i             : in std_logic;  
    data_i              : in std_logic;
    data_valid_i        : in std_logic;
    -- outputs 
    output_byte_o       : out std_logic_vector(7 downto 0); 
    data_valid_o        : out std_logic;
    decoder_failure_o   : out std_logic 
);
end ccsds_131_ground; 

architecture top_level of ccsds_131_ground is

-- convolutional decoder signals 
signal conv_data_s          : std_logic := '0';
signal conv_data_valid_s    : std_logic := '0';

-- asm decoder signals 
signal asm_data_s           : std_logic := '0';  
signal asm_data_valid_s     : std_logic := '0'; 
signal asm_decoder_done_s   : std_logic := '0'; 

-- pseudo randomizer signals 
signal pr_data_s            : std_logic := '0';
signal pr_data_valid_s      : std_logic := '0';
signal pr_decoder_done_s    : std_logic := '0';

-- width converter signal 
signal wc_output_byte_s         : std_logic_vector (7 downto 0) := (others => '0');
signal wc_data_valid_s          : std_logic := '0';
signal wc_data_valid_in_s       : std_logic := '0';
signal wc_asm_done_s            : std_logic := '0';


begin 

-- convolutional decoder 
convolutional_decoder_inst : entity work.stub_convolutional_decoder
    port map(
        -- inputs
        clk_i               => clk_i,
        reset_i             => reset_i,
        data_in_i           => data_i,
        data_in_ready_i     => data_valid_i,
        -- outputs
        data_out_o          => conv_data_s,
        data_out_ready_o    => conv_data_valid_s
    );

-- asm decoder 
asm_decoder_inst : entity work.asm_decoder
    generic map(
        clock_divider_g => 1
        )
    port map( 
    -- input ports 
    clk_i           => clk_i,
    reset_i         => reset_i,
    data_i          => conv_data_s,
    data_valid_i    => conv_data_valid_s,
    -- output ports 
    data_o          => asm_data_s,
    data_valid_o    => asm_data_valid_s,
    decoder_done_o  => asm_decoder_done_s
    );

-- pseudo randomizer decoder 

pseudo_randomizer_inst : entity work.pseudo_randomizer
    generic map(
        clock_divider_g     => 1,
        is_ground_g         => true
        )
    port map(
        -- input ports 
        clk_i           => clk_i,
        reset_i         => reset_i,
        data_valid_i    => asm_data_valid_s,
        encoder_done_i  => asm_decoder_done_s,
        data_i          => asm_data_s,
        -- output ports  
        data_o          => pr_data_s,
        data_valid_o    => pr_data_valid_s,
        encoder_done_o  => pr_decoder_done_s
    );

-- width converter 1 to 8 
width_converter_1_to_8_inst : entity work.width_converter_1_to_8
    port map (
        -- inputs 
        clk_i           => clk_i,  
        reset_i         => reset_i,
        input_bit_i     => pr_data_s,
        data_valid_i    => wc_data_valid_in_s,
        asm_done_i      => pr_decoder_done_s,
        -- outputs 
        output_byte_o   => wc_output_byte_s,
        data_valid_o    => wc_data_valid_s,
        asm_done_o      => wc_asm_done_s
    );

-- reed solomon decoder 
reed_solomon_decoder_inst : entity work.reed_solomon_decoder_top
    port map(
        -- inputs
        clk_i           => clk_i,
        reset_i         => reset_i,
        input_byte_i    => wc_output_byte_s,
        data_valid_i    => wc_data_valid_s,
        asm_done_i      => wc_asm_done_s,
        -- outputs
        data_valid_o    => data_valid_o,
        output_byte_o   => output_byte_o,
        reed_solomon_failure_o  => decoder_failure_o
    );
    
    --this logic fixes warning that there shall not be function calls inside of a port map
    --that why this signal is set outside of the portmap and then mapped indireclty (see width_converter_1_to_8_inst)
    wc_data_valid_in_s <= ((not pr_decoder_done_s) and pr_data_valid_s);
    
end top_level;