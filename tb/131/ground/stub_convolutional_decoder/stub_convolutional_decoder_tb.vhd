----------------------------------------------------------------
-- File : stub_convolutional_decoder_tb.vhd
-- Created : 27.11.2025
-- Author : Lukas Reil
-- Project Name : HW/SW Project TM
-- Description : Testbench for the stub convolutional decoder module.
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

    signal clk_r               : std_logic := '0';
    signal reset_r             : std_logic := '1';
    signal data_in_r           : std_logic := '0';
    signal data_in_ready_r     : std_logic := '0';
    signal data_out_s          : std_logic;
    signal data_out_ready_s    : std_logic;

    signal encoded_data_s        : std_logic;
    signal encoded_data_ready_s  : std_logic;

    constant clk_period : time := 10 ns;

begin

    dut_ce : stub_convolutional_encoder
        port map (
            clk_i               => clk_r,
            reset_i             => reset_r,
            data_in_i           => data_in_r,
            data_in_ready_i     => data_in_ready_r,
            data_out_o          => encoded_data_s,
            data_out_ready_o    => encoded_data_ready_s
        );

    dut_cd : stub_convolutional_decoder
        port map (
            clk_i               => clk_r,
            reset_i             => reset_r,
            data_in_i           => encoded_data_s,
            data_in_ready_i     => encoded_data_ready_s,
            data_out_o          => data_out_s,
            data_out_ready_o    => data_out_ready_s
        );
    

    clock_gen : process
    begin
        clk_r <= '1';
        wait for clk_period / 2;
        clk_r <= '0';
        wait for clk_period / 2;
    end process clock_gen;

    stimulus : process
    begin

         wait for 20 ns;
        reset_r <= '0';
        wait for 20 ns;
        reset_r <= '1';
        wait for 20 ns;

        data_in_r <= '1';
        wait for clk_period * 10; -- No output expected since data_in_ready_r is '0'

        data_in_ready_r <= '1';
        wait for clk_period * 2; -- Inputs need to be held for two clock cycles
        data_in_r <= '0';
        wait for clk_period * 2;
        data_in_r <= '0';
        wait for clk_period * 2;
        data_in_r <= '1';
        wait for clk_period * 2;
        data_in_ready_r <= '0';
        wait for clk_period * 10;

        data_in_r <= '0';
        data_in_ready_r <= '1';
        wait for clk_period * 2;
        data_in_r <= '1';
        wait for clk_period * 2;
        data_in_r <= '0';
        wait for clk_period * 2;
        data_in_ready_r <= '0';
        wait for clk_period * 10;
        wait;

        -- Expected output:
        -- ...XXX1001XXXXX010XXXX...
        -- X denotes don't care values due to input not being ready
        -- Output ready signal should align with valid output data

        
        

    end process stimulus;


end architecture behavioral;