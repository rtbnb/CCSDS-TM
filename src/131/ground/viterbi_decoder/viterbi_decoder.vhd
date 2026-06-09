----------------------------------------------------------------
-- File : viterbi_decoder.vhd
-- Created : 16.05.2026
-- Author : Lukas Reil
-- Project Name : HW/SW Project TM
-- Description : A integration of all components of the Viterbi decoder, including the convolutional to Viterbi converter and the Viterbi decoder itself.
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity viterbi_decoder is
    port (
        clk_i : in std_logic;
        reset_i : in std_logic;

        -- Convolutional encoded data input
        convolutional_data_tdata : in std_logic;
        convolutional_data_tvalid : in std_logic;
        convolutional_data_tready : out std_logic;

        -- Data output from Viterbi decoder
        decoded_data_tdata : out std_logic;
        decoded_data_tvalid : out std_logic;
        decoded_data_tready : in std_logic;
        decoded_data_tlast : out std_logic
    );
end entity viterbi_decoder;

architecture connectivity of viterbi_decoder is

    signal viterbi_ctrl_tdata : std_logic_vector(31 downto 0);
    signal viterbi_ctrl_tvalid : std_logic;
    signal viterbi_ctrl_tready : std_logic;
    signal viterbi_ctrl_tlast : std_logic;

    signal viterbi_data_tdata : std_logic_vector(31 downto 0);
    signal viterbi_data_tvalid : std_logic;
    signal viterbi_data_tready : std_logic;
    signal viterbi_data_tlast : std_logic;

    signal decoded_data_tdata_internal : std_logic;
    signal decoded_data_tvalid_internal : std_logic;
    signal decoded_data_tready_internal : std_logic;
    signal decoded_data_tlast_internal : std_logic;

    component convolutional_to_viterbi_converter is
        generic (
            ACQUISITION_LENGTH_g : integer := 96; -- Number of convolutional encoded bits to acquire before processing (Should be 6x the constraint length of the convolutional encoder)
            WINDOW_SIZE_g : integer := 250; -- Size of the sliding window for processing convolutional data (Should be at least 6x the constraint length of the convolutional encoder to ensure proper decoding)
            INVERT_MASK_g : std_logic_vector(1 downto 0) := "10" -- Mask to invert output bits, '1' means invert. CCSDS standard uses "01" to invert the second output bit.
        );

        port (
            clk_i : in std_logic;
            reset_i : in std_logic;

            -- Convolutional encoded data input
            convolutional_data_tdata : in std_logic;
            convolutional_data_tvalid : in std_logic;
            convolutional_data_tready : out std_logic;

            -- Data output to Viterbi decoder
            viterbi_data_tdata : out std_logic_vector(31 downto 0);
            viterbi_data_tvalid : out std_logic;
            viterbi_data_tready : in std_logic;
            viterbi_data_tlast : out std_logic;

            -- Control output to Viterbi decoder
            viterbi_ctrl_tdata : out std_logic_vector(31 downto 0);
            viterbi_ctrl_tvalid : out std_logic;
            viterbi_ctrl_tready : in std_logic;
            viterbi_ctrl_tlast : out std_logic
        );
    end component convolutional_to_viterbi_converter;

    component dec_viterbi is
        port(

        --
        -- The core only uses AXI4-Stream interfaces,
        -- based on AMBA4 AXI4-Stream Protocol with restrictions according to
        -- Xilinx Migration, described in Xilinx AXI Reference UG761 (v13.3).
        --

        aclk      : in std_logic;

        -- Synchronous reset, active low.
        aresetn   : in std_logic;


        --
        -- Slave (input) data signals
        -- Delivers the parity LLR values, one byte per LLR value.
        --
        s_axis_input_tvalid : in std_logic;
        s_axis_input_tdata  : in std_logic_vector(31 downto 0);
        s_axis_input_tlast  : in std_logic;
        s_axis_input_tready : out std_logic;


        --
        -- Master (output) data signals
        -- Delivers the decoded systematic (payload) bits.
        --
        m_axis_output_tvalid : out std_logic;
        m_axis_output_tdata  : out std_logic;
        m_axis_output_tlast  : out std_logic;
        m_axis_output_tready : in  std_logic;


        --
        -- Slave (input) configuration signals
        -- Configures window length and acquisition length.
        --
        s_axis_ctrl_tvalid : in std_logic;
        s_axis_ctrl_tdata  : in std_logic_vector(31 downto 0);
        s_axis_ctrl_tlast  : in std_logic;
        s_axis_ctrl_tready : out std_logic
    );
    end component dec_viterbi;

begin

    viterbi_controller : convolutional_to_viterbi_converter
        generic map(
            ACQUISITION_LENGTH_g => 480,
            WINDOW_SIZE_g => 500,
            INVERT_MASK_g => "10"
        )
        port map(
            clk_i => clk_i,
            reset_i => reset_i,
            convolutional_data_tdata => convolutional_data_tdata,
            convolutional_data_tvalid => convolutional_data_tvalid,
            convolutional_data_tready => convolutional_data_tready,
            viterbi_data_tdata => viterbi_data_tdata,
            viterbi_data_tvalid => viterbi_data_tvalid,
            viterbi_data_tready => viterbi_data_tready,
            viterbi_data_tlast => viterbi_data_tlast,
            viterbi_ctrl_tdata => viterbi_ctrl_tdata,
            viterbi_ctrl_tvalid => viterbi_ctrl_tvalid,
            viterbi_ctrl_tready => viterbi_ctrl_tready,
            viterbi_ctrl_tlast => viterbi_ctrl_tlast
        );

    viterbi_decoder_core : dec_viterbi
        port map(
            aclk => clk_i,
            aresetn => reset_i,
            s_axis_input_tvalid => viterbi_data_tvalid,
            s_axis_input_tdata => viterbi_data_tdata,
            s_axis_input_tlast => viterbi_data_tlast,
            s_axis_input_tready => viterbi_data_tready,
            m_axis_output_tvalid => decoded_data_tvalid_internal,
            m_axis_output_tdata => decoded_data_tdata_internal,
            m_axis_output_tlast => decoded_data_tlast_internal,
            m_axis_output_tready => decoded_data_tready_internal,
            s_axis_ctrl_tvalid => viterbi_ctrl_tvalid,
            s_axis_ctrl_tdata => viterbi_ctrl_tdata,
            s_axis_ctrl_tlast => viterbi_ctrl_tlast,
            s_axis_ctrl_tready => viterbi_ctrl_tready
        );

    viterbi_axi_adapter_inst : entity work.viterbi_axi_adapter
        port map(
            clk_i => clk_i,
            reset_i => reset_i,
            s_axis_output_tvalid => decoded_data_tvalid_internal,
            s_axis_output_tdata => decoded_data_tdata_internal,
            s_axis_output_tlast => decoded_data_tlast_internal,
            s_axis_output_tready => decoded_data_tready_internal,
            m_axis_tdata => decoded_data_tdata,
            m_axis_tvalid => decoded_data_tvalid,
            m_axis_tready => decoded_data_tready,
            m_axis_tlast => decoded_data_tlast
        );


end architecture connectivity;