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
end entity convolutional_to_viterbi_converter;

architecture behavioral of convolutional_to_viterbi_converter is

    signal viterbi_configured_r : std_logic := '0';

    signal first_convolutional_data_received_r : std_logic := '0';
    signal convolutional_data_phase_r : std_logic := '0'; -- '0' for first bit, '1' for second bit of the pair

    signal ready_for_data_r : std_logic := '0';

begin

    convolutional_data_tready <= ready_for_data_r and viterbi_data_tready; -- Ready to receive convolutional data when configured and Viterbi decoder is ready for data

    viterbi_configuration : process(clk_i, reset_i)
    begin
        if reset_i = '0' then
            viterbi_configured_r <= '0';
            viterbi_ctrl_tdata <= (others => '0');
            viterbi_ctrl_tvalid <= '0';
            viterbi_ctrl_tlast <= '0';
        elsif rising_edge(clk_i) then
            if viterbi_configured_r = '0' and viterbi_ctrl_tready = '1' then
                viterbi_configured_r <= '1';

                viterbi_ctrl_tdata(15 downto 0) <= std_logic_vector(to_unsigned(ACQUISITION_LENGTH_g, 16)); -- Set acquisition length
                viterbi_ctrl_tdata(31 downto 16) <= std_logic_vector(to_unsigned(WINDOW_SIZE_g, 16)); -- Set window size

                viterbi_ctrl_tvalid <= '1';
                viterbi_ctrl_tlast <= '1';
            else
                viterbi_ctrl_tvalid <= '0';
                viterbi_ctrl_tlast <= '0';
            end if;
        end if;
    end process viterbi_configuration;


    convolutional_ready_indicator : process(clk_i, reset_i)
    begin
        if reset_i = '0' then
            ready_for_data_r <= '0';
        elsif rising_edge(clk_i) and viterbi_configured_r = '1' then
            ready_for_data_r <= '1';
        end if;
    end process convolutional_ready_indicator;

    convolutional_data_processing : process(clk_i, reset_i)
        variable inverted_bit_0 : std_logic := '0';
        variable inverted_bit_1 : std_logic := '0';
        variable viterbi_llr_bit_0 : std_logic_vector(1 downto 0) := "00";
        variable viterbi_llr_bit_1 : std_logic_vector(1 downto 0) := "00";
    begin
        if reset_i = '0' then
            first_convolutional_data_received_r <= '0';
            convolutional_data_phase_r <= '0';
            viterbi_data_tdata <= (others => '0');
            viterbi_data_tvalid <= '0';
            viterbi_data_tlast <= '0';
        elsif rising_edge(clk_i) and ready_for_data_r = '1' then
            if convolutional_data_tvalid = '1' then
                if convolutional_data_phase_r = '0' then
                    first_convolutional_data_received_r <= convolutional_data_tdata; -- Store the first bit of the pair

                    -- The Viterbi decoder expects pairs of bits, so no output is generated until the second bit is received.
                    viterbi_data_tvalid <= '0';
                    viterbi_data_tlast <= '0';
                else
                    inverted_bit_0 := first_convolutional_data_received_r    xor INVERT_MASK_g(0);   -- Invert first bit if mask indicates
                    inverted_bit_1 := convolutional_data_tdata               xor INVERT_MASK_g(1);   -- Invert second bit if mask indicates
                    viterbi_llr_bit_0 := inverted_bit_0 & (not inverted_bit_0);
                    viterbi_llr_bit_1 := inverted_bit_1 & (not inverted_bit_1);
                    -- The bits are byte aligned to allow for soft decision decoding (currently not implemented).
                    viterbi_data_tdata(1 downto 0) <= viterbi_llr_bit_0;
                    viterbi_data_tdata(9 downto 8) <= viterbi_llr_bit_1;
                    viterbi_data_tvalid <= '1';
                    viterbi_data_tlast <= '0'; -- Set to '1' when the last bit of a frame is processed (not implemented as the Viterbi decoder ignores this signal in the current implementation)
                end if;

                convolutional_data_phase_r <= not convolutional_data_phase_r; -- Toggle phase for next bit
            else
                viterbi_data_tvalid <= '0';
                viterbi_data_tlast <= '0';
            end if;
        end if;
    end process convolutional_data_processing;



end architecture behavioral;