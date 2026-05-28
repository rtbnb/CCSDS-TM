----------------------------------------------------------------
-- File : convolutional_encoder_tb.vhd
-- Created : 06.05.2026
-- Author : Lukas Reil
-- Project Name : HW/SW Project TM
-- Description : Testbench for the convolutional encoder module.
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity convolutional_encoder_tb is
end entity convolutional_encoder_tb;

architecture behavioral of convolutional_encoder_tb is

    component convolutional_encoder is
        generic (
            -- Standard convolutional code as per CCSDS 131.0-B-5
            K : integer := 7; -- Constraint length
            G1 : integer := 8#171#; -- Generator polynomial G1 (octal)
            G2 : integer := 8#133#; -- Generator polynomial G2 (octal)
            INVERT_MASK : std_logic_vector(1 downto 0) := "10" -- Mask to invert output bits, '1' means invert. CCSDS standard uses "01" to invert the second output bit.
        );
        port (
            clk_i               : in  std_logic;
            reset_i             : in  std_logic;

            s_axis_tdata        : in std_logic_vector(0 downto 0);
            s_axis_tvalid       : in std_logic;
            s_axis_tready       : out std_logic;

            m_axis_tdata        : out std_logic_vector(0 downto 0);
            m_axis_tvalid       : out std_logic;
            m_axis_tready       : in std_logic
        );
    end component convolutional_encoder;

    signal clk_r               : std_logic := '0';
    signal reset_r             : std_logic := '1';
    signal data_in_r           : std_logic := '0';
    signal data_in_valid_r     : std_logic := '0';
    signal data_in_ready_s     : std_logic;
    signal data_out_s          : std_logic;
    signal data_out_valid_s    : std_logic;
    signal data_out_ready_r    : std_logic := '1';

    constant clk_period : time := 10 ns;

begin

    dut : convolutional_encoder
        generic map (
            K => 7,
            G1 => 8#171#,
            G2 => 8#133#,
            INVERT_MASK => "10"
        )
        port map (
            clk_i               => clk_r,
            reset_i             => reset_r,

            s_axis_tdata(0)     => data_in_r,
            s_axis_tvalid       => data_in_valid_r,
            s_axis_tready       => data_in_ready_s,

            m_axis_tdata(0)     => data_out_s,
            m_axis_tvalid       => data_out_valid_s,
            m_axis_tready       => data_out_ready_r
        );
    

    clk_r <= not clk_r after clk_period / 2;


    stimulus : process
    begin
        wait for 20 ns;
        reset_r <= '0';
        wait for 20 ns;
        reset_r <= '1';
        wait for 20 ns;

        data_in_r <= '1';
        wait for clk_period * 10; -- No output expected since data_in_ready_r is '0'

        data_in_valid_r <= '1';
        wait for clk_period;
        data_in_valid_r <= '0';
        wait for clk_period;
        data_in_r <= '0';
        data_in_valid_r <= '1';
        wait for clk_period;
        data_in_valid_r <= '0';
        wait for clk_period;
        data_in_r <= '0';
        data_in_valid_r <= '1';
        wait for clk_period;
        data_in_valid_r <= '0';
        wait for clk_period;
        data_in_r <= '1';
        data_in_valid_r <= '1';
        wait for clk_period;
        data_in_valid_r <= '0';
        for i in 0 to 8 loop
            wait for clk_period;
            data_in_valid_r <= '1';
            wait for clk_period;
            data_in_valid_r <= '0';
        end loop;
        wait for clk_period * 2 * 8;

        for i in 0 to 15 loop
            data_in_r <= not data_in_r; -- Alternate between '0' and '1'
            data_in_valid_r <= '1';
            wait for clk_period;
            data_in_valid_r <= '0';
            wait for clk_period;
        end loop;
        data_in_valid_r <= '0';
        wait;


    end process stimulus;



end architecture behavioral;