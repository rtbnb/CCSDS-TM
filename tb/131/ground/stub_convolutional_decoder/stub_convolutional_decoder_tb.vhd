----------------------------------------------------------------
-- File : stub_convolutional_decoder_tb.vhd
-- Created : 27.11.2025
-- Author : Lukas Reil
-- Project Name : HW/SW Project TM
-- Description : Testbench for the stub convolutional decoder module.
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity stub_convolutional_decoder_tb is
end entity stub_convolutional_decoder_tb;

architecture behavioral of stub_convolutional_decoder_tb is

    component stub_convolutional_encoder
        port (
            clk_i               : in  std_logic;
            reset_i             : in  std_logic;
            data_in_i           : in  std_logic;
            data_in_ready_i     : in  std_logic;
            data_out_o          : out std_logic;
            data_out_ready_o    : out std_logic
        );
    end component stub_convolutional_encoder;

    component stub_convolutional_decoder
        port (
            clk_i               : in  std_logic;
            reset_i             : in  std_logic;
            data_in_i           : in  std_logic;
            data_in_ready_i     : in  std_logic;
            data_out_o          : out std_logic;
            data_out_ready_o    : out std_logic
        );
    end component stub_convolutional_decoder;

    signal encoder_clk_r       : std_logic := '0';
    signal decoder_clk_r       : std_logic := '0';
    signal reset_r             : std_logic := '1';
    signal data_in_r           : std_logic := '0';
    signal data_in_ready_r     : std_logic := '0';
    signal data_out_s          : std_logic;
    signal data_out_ready_s    : std_logic;

    signal encoded_data_s        : std_logic;
    signal encoded_data_ready_s  : std_logic;

    constant DECODER_CLK_PERIOD : time := 10 ns;
    -- The decoder runs at 50 times the clock speed of the encoder (100 MHz vs 2 MHz)
    constant ENCODER_CLK_PERIOD : time := 10 * 50 ns;

begin

    dut_ce : stub_convolutional_encoder
        port map (
            clk_i               => encoder_clk_r,
            reset_i             => reset_r,
            data_in_i           => data_in_r,
            data_in_ready_i     => data_in_ready_r,
            data_out_o          => encoded_data_s,
            data_out_ready_o    => encoded_data_ready_s
        );

    dut_cd : stub_convolutional_decoder
        port map (
            clk_i               => decoder_clk_r,
            reset_i             => reset_r,
            data_in_i           => encoded_data_s,
            data_in_ready_i     => encoded_data_ready_s,
            data_out_o          => data_out_s,
            data_out_ready_o    => data_out_ready_s
        );
    

    decoder_clock_gen : process
    begin
        decoder_clk_r <= '1';
        wait for DECODER_CLK_PERIOD / 2;
        decoder_clk_r <= '0';
        wait for DECODER_CLK_PERIOD / 2;
    end process decoder_clock_gen;

    encoder_clock_gen : process
    begin
        encoder_clk_r <= '1';
        wait for ENCODER_CLK_PERIOD / 2;
        encoder_clk_r <= '0';
        wait for ENCODER_CLK_PERIOD / 2;
    end process encoder_clock_gen;

    stimulus : process
    begin

         wait for 20 ns;
        reset_r <= '0';
        wait for 20 ns;
        reset_r <= '1';
        wait for 20 ns;

        data_in_r <= '1';
        wait for ENCODER_CLK_PERIOD * 10; -- No output expected since data_in_ready_r is '0'

        data_in_ready_r <= '1';
        wait for ENCODER_CLK_PERIOD * 2; -- Inputs need to be held for two clock cycles
        data_in_r <= '0';
        wait for ENCODER_CLK_PERIOD * 2;
        data_in_r <= '0';
        wait for ENCODER_CLK_PERIOD * 2;
        data_in_r <= '1';
        wait for ENCODER_CLK_PERIOD * 2;
        data_in_ready_r <= '0';
        wait for ENCODER_CLK_PERIOD * 10;

        data_in_r <= '0';
        data_in_ready_r <= '1';
        wait for ENCODER_CLK_PERIOD * 2;
        data_in_r <= '1';
        wait for ENCODER_CLK_PERIOD * 2;
        data_in_r <= '0';
        wait for ENCODER_CLK_PERIOD * 2;
        data_in_ready_r <= '0';
        wait for ENCODER_CLK_PERIOD * 10;
        wait;

        -- Expected output:
        -- ...XXX1001XXXXX010XXXX...
        -- X denotes don't care values due to input not being ready
        -- Output ready signal should align with the beginning of each valid output bit

        
        

    end process stimulus;


end architecture behavioral;