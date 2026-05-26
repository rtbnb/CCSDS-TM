-- top level module CCSDS 131 space 

library ieee; 
use ieee.std_logic_1164.all; 

entity ccsds_131_space is
port(
    -- inputs 
    clk_i           : in std_logic; 
    reset_i         : in std_logic; 
    input_byte_i    : in std_logic_vector(7 downto 0); 
    fifo_empty_i    : in std_logic; 
    -- outputs 
    read_data_fifo_o: out std_logic;
    data_o          : out std_logic;
    data_valid_o    : out std_logic
);
end ccsds_131_space; 

architecture top_level of ccsds_131_space is

-- rs encoder signals 
signal rs_output_byte_s         : std_logic_vector(7 downto 0) := (others => '0');
signal rs_encoder_done_flag_s   : std_logic := '0';
signal rs_data_valid_s          : std_logic := '0';

-- width converter signals 
signal wc_output_bit_s      : std_logic := '0';    
signal wc_data_valid_s      : std_logic := '0';
signal wc_encoder_done_s    : std_logic := '0';

-- pseudo randomizer encoder signals 
signal pr_data_s            : std_logic := '0';   
signal pr_data_valid_s      : std_logic := '0';  
signal pr_encoder_done_s    : std_logic := '0'; 

-- asm encoder signals 
signal asm_data_s       : std_logic := '0';
signal asm_data_valid_s : std_logic := '0';
        
        
begin 

-- reed solomon encoder 
 reed_solomon_encoder_inst : entity work.reed_solomon_encoder
    port map(
        -- inputs 
        clk_i               => clk_i,
        reset_i             => reset_i,
        input_byte_i        => input_byte_i,
        fifo_empty_i        => fifo_empty_i,
        -- outputs 
        output_byte_o       => rs_output_byte_s,
        encoder_done_flag_o => rs_encoder_done_flag_s,
        data_valid_o        => rs_data_valid_s,
        read_data_fifo_o    => read_data_fifo_o
    );
    
-- width converter 8 to 1 
width_converter_8_to_1_inst: entity work.width_converter_8_to_1
    port map (
        -- input
        clk_i           => clk_i,
        reset_i         => reset_i,
        input_byte_i    => rs_output_byte_s,
        data_valid_i    => rs_data_valid_s,
        encoder_done_i  => rs_encoder_done_flag_s,
        -- output 
        output_bit_o    => wc_output_bit_s,
        data_valid_o    => wc_data_valid_s,
        encoder_done_o  => wc_encoder_done_s
    );

-- pseudo randomizer encoder 
pseudo_randomizer_inst : entity work.pseudo_randomizer
    generic map(
        clock_divider_g => 2,
        is_ground_g     => false
        )
    port map(
        -- input ports 
        clk_i           => clk_i,
        reset_i         => reset_i,
        data_valid_i    => wc_data_valid_s,
        encoder_done_i  => wc_encoder_done_s,
        data_i          => wc_output_bit_s,
        -- output ports  
        data_o          => pr_data_s,
        data_valid_o    => pr_data_valid_s,
        encoder_done_o  => pr_encoder_done_s
    );

-- asm generator 
asm_encoder_inst : entity work.asm_encoder
    generic map(
        clock_divider_g => 2
        )
    port map(
        -- input 
        clk_i           => clk_i,
        reset_i         => reset_i,
        data_i          => pr_data_s,
        encoder_done_i  => pr_encoder_done_s,
        data_valid_i    => pr_data_valid_s, 
        -- output  
        data_o          => asm_data_s,
        data_valid_o    => asm_data_valid_s
    ); 
    
-- convolutional encoder 
convolutional_encoder_inst : entity work.stub_convolutional_encoder
    port map(
        -- inputs 
        clk_i               => clk_i,
        reset_i             => reset_i,
        data_in_i           => asm_data_s,
        data_in_ready_i     => asm_data_valid_s,
        -- outputs 
        data_out_o          => data_o,
        data_out_ready_o    => data_valid_o
    );


end top_level;