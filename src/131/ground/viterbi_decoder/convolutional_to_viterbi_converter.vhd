----------------------------------------------------------------
-- File : convolutional_to_viterbi_converter.vhd
-- Created : 11.05.2026
-- Author : Lukas Reil
-- Project Name : HW/SW Project TM
-- Description : A converter module to transform convolutional encoded data into a format suitable for the Viterbi decoder.
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity convolutional_to_viterbi_converter is

    generic (
        ACQUISITION_LENGTH : integer := 96; -- Number of convolutional encoded bits to acquire before processing (Should be 6x the constraint length of the convolutional encoder)
        WINDOW_SIZE : integer := 100; -- Size of the sliding window for processing convolutional data (Should be at least 6x the constraint length of the convolutional encoder to ensure proper decoding)
        INVERT_MASK : std_logic_vector(1 downto 0) := "10" -- Mask to invert output bits, '1' means invert. CCSDS standard uses "01" to invert the second output bit.
    );

    port (
        clk_i : in std_logic;
        reset_i : in std_logic;

        -- Convolutional encoded data input
        convolutional_data_tdata : in std_logic_vector(0 downto 0);
        convolutional_data_tvalid : in std_logic;
        convolutional_data_tready : out std_logic;

        -- Data output to Viterbi decoder
        viterbi_data_tdata : out std_logic_vector(31 downto 0);
        viterbi_data_tvalid : out std_logic;
        viterbi_data_tready : in std_logic;
        viterbi_data_tlast : out std_logic := '0';

        -- Control output to Viterbi decoder
        viterbi_ctrl_tdata : out std_logic_vector(31 downto 0);
        viterbi_ctrl_tvalid : out std_logic;
        viterbi_ctrl_tready : in std_logic;
        viterbi_ctrl_tlast : out std_logic := '0'
    );
end entity convolutional_to_viterbi_converter;

architecture behavioral of convolutional_to_viterbi_converter is

    signal viterbi_config_written_r : std_logic := '0';
    signal viterbi_configured_r : std_logic := '0';


    signal first_convolutional_data_received_r : std_logic := '0';
    signal convolutional_data_phase_r : std_logic := '0'; -- '0' for first bit, '1' for second bit of the pair

    signal ready_for_data_r : std_logic := '0';

    signal viterbi_ctrl_tvalid_s : std_logic := '0';

    signal viterbi_ctrl_data_r : std_logic_vector(31 downto 0) := (others => '0');
    signal viterbi_ctrl_data_we_r : std_logic := '0';

    signal input_fifo_empty_s : std_logic := '0';
    signal input_fifo_almost_empty_s : std_logic := '0';
    signal output_fifo_full_s : std_logic := '0';
    signal output_fifo_almost_full_s : std_logic := '0';

    signal input_fifo_read_r : std_logic := '0';
    signal input_fifo_read_delay_r : std_logic := '0';
    signal input_fifo_data_s : std_logic_vector(0 downto 0) := (others => '0');

    signal output_fifo_write_r : std_logic := '0';
    signal output_fifo_data_r : std_logic_vector(31 downto 0) := (others => '0');

begin


    conv_input_fifo : entity work.synchronization_fifo_axi_stream_in_with_almost_empty
        generic map (
            DATA_WIDTH => 1,
            DEPTH => 16
        )
        port map (
            s_axis_aclk => clk_i,
            s_axis_aresetn => reset_i,
            s_axis_tvalid => convolutional_data_tvalid,
            s_axis_tdata => convolutional_data_tdata,
            s_axis_tready => convolutional_data_tready,

            rd_clk_i => clk_i,
            empty_o => input_fifo_empty_s,
            almost_empty_o => input_fifo_almost_empty_s,
            rd_en_i => input_fifo_read_r,
            rd_data_o => input_fifo_data_s
        );
    
    conv_output_fifo : entity work.synchronization_fifo_axi_stream_out_with_almost_full
        generic map (
            DATA_WIDTH => 32,
            DEPTH => 16
        )
        port map (
            wr_clk_i => clk_i,
            full_o => output_fifo_full_s,
            almost_full_o => output_fifo_almost_full_s,
            wr_en_i => output_fifo_write_r,
            wr_data_i => output_fifo_data_r,

            m_axis_aclk => clk_i,
            m_axis_aresetn => reset_i,
            m_axis_tvalid => viterbi_data_tvalid,
            m_axis_tdata => viterbi_data_tdata,
            m_axis_tready => viterbi_data_tready
        );
    
    ctrl_fifo : entity work.synchronization_fifo_axi_stream_out
        generic map (
            DATA_WIDTH => 32,
            DEPTH => 16
        )
        port map (

            wr_clk_i => clk_i,
            wr_en_i => viterbi_ctrl_data_we_r,
            wr_data_i => viterbi_ctrl_data_r,
            full_o => open,

            m_axis_aclk => clk_i,
            m_axis_aresetn => reset_i,
            m_axis_tvalid => viterbi_ctrl_tvalid_s,
            m_axis_tdata => viterbi_ctrl_tdata,
            m_axis_tready => viterbi_ctrl_tready
        );

    viterbi_ctrl_tvalid <= viterbi_ctrl_tvalid_s;

    viterbi_configuration : process(clk_i, reset_i)
    begin
        if reset_i = '0' then
            viterbi_configured_r <= '0';
            viterbi_config_written_r <= '0';
        elsif rising_edge(clk_i) then
            if viterbi_config_written_r = '0' then
                viterbi_config_written_r <= '1';
                viterbi_ctrl_data_r(15 downto 0) <= std_logic_vector(to_unsigned(ACQUISITION_LENGTH, 16)); -- Set acquisition length
                viterbi_ctrl_data_r(31 downto 16) <= std_logic_vector(to_unsigned(WINDOW_SIZE, 16)); -- Set window size
                viterbi_ctrl_data_we_r <= '1'; -- Write control data to FIFO
            else
                viterbi_ctrl_data_we_r <= '0'; -- Stop writing control data after the first write
            end if;

            if viterbi_ctrl_tvalid_s = '1' and viterbi_ctrl_tready = '1' then
                -- Assume configuration is successful after writing the config data
                viterbi_configured_r <= '1'; 
            end if;
        end if;
    end process viterbi_configuration;


    convolutional_data_processing : process(clk_i, reset_i)
        variable inverted_bit_0 : std_logic := '0';
        variable inverted_bit_1 : std_logic := '0';
        variable viterbi_llr_bit_0 : std_logic_vector(1 downto 0) := "00";
        variable viterbi_llr_bit_1 : std_logic_vector(1 downto 0) := "00";
    begin
        if reset_i = '0' then
            first_convolutional_data_received_r <= '0';
            convolutional_data_phase_r <= '0';
            output_fifo_write_r <= '0';
            output_fifo_data_r <= (others => '0');
            input_fifo_read_r <= '0';
            input_fifo_read_delay_r <= '0';
        elsif rising_edge(clk_i) and viterbi_configured_r = '1' then

            if input_fifo_almost_empty_s = '0' and output_fifo_almost_full_s = '0' then
                input_fifo_read_r <= '1'; -- Read convolutional data from FIFO
            else
                input_fifo_read_r <= '0';
            end if;

            input_fifo_read_delay_r <= input_fifo_read_r; -- Delay the read signal to align with data availability
            
            if input_fifo_read_delay_r = '1' then
                -- Data processing will be triggered in the next clock cycle when the data is available
                if convolutional_data_phase_r = '0' then
                    first_convolutional_data_received_r <= input_fifo_data_s(0); -- Store the first bit of the pair

                    -- The Viterbi decoder expects pairs of bits, so no output is generated until the second bit is received.
                    output_fifo_write_r <= '0';
                else
                    inverted_bit_0 := first_convolutional_data_received_r    xor INVERT_MASK(0);   -- Invert first bit if mask indicates
                    inverted_bit_1 := input_fifo_data_s(0)                   xor INVERT_MASK(1);   -- Invert second bit if mask indicates
                    viterbi_llr_bit_0 := inverted_bit_0 & (not inverted_bit_0);
                    viterbi_llr_bit_1 := inverted_bit_1 & (not inverted_bit_1);
                    -- The bits are byte aligned to allow for soft decision decoding (currently not implemented).
                    output_fifo_data_r(1 downto 0) <= viterbi_llr_bit_0;
                    output_fifo_data_r(9 downto 8) <= viterbi_llr_bit_1;
                    output_fifo_write_r <= '1';
                end if;

                convolutional_data_phase_r <= not convolutional_data_phase_r; -- Toggle phase for next bit
            else
                output_fifo_write_r <= '0';
            end if;

        end if;
    end process convolutional_data_processing;



end architecture behavioral;