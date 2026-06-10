----------------------------------------------------------------
-- File : conv_encoder_fifo_tb.vhd
-- Created : 09.06.2026
-- Author : Lukas Reil
-- Project Name : HW/SW Project TM
-- Description : Testbench for the convolutional encoder module with FIFO.
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity conv_encoder_fifo_tb is
end entity conv_encoder_fifo_tb;

architecture behavioral of conv_encoder_fifo_tb is

    signal clk_r               : std_logic := '0';
    signal reset_r             : std_logic := '1';
    signal data_i              : std_logic_vector(0 downto 0) := (others => '0');
    signal write_i             : std_logic := '0';
    signal full_i              : std_logic;
    signal data_o              : std_logic_vector(0 downto 0);
    signal read_o              : std_logic := '0';
    signal empty_o             : std_logic;


    signal axis_0_tdata        : std_logic_vector(0 downto 0);
    signal axis_0_tvalid       : std_logic;
    signal axis_0_tready       : std_logic;

    signal axis_1_tdata        : std_logic_vector(0 downto 0);
    signal axis_1_tvalid       : std_logic;
    signal axis_1_tready       : std_logic;

    constant clk_period : time := 10 ns;

begin

    dut : entity work.convolutional_encoder
        generic map (
            K => 7,
            G1 => 8#171#,
            G2 => 8#133#,
            INVERT_MASK => "10"
        )
        port map (
            clk_i               => clk_r,
            reset_i             => reset_r,

            s_axis_tdata        => axis_0_tdata,
            s_axis_tvalid       => axis_0_tvalid,
            s_axis_tready       => axis_0_tready,

            m_axis_tdata        => axis_1_tdata,
            m_axis_tvalid       => axis_1_tvalid,
            m_axis_tready       => axis_1_tready
        );
    
    input_fifo : entity work.synchronization_fifo_axi_stream_out
        generic map (
            DATA_WIDTH => 1,
            DEPTH => 16
        )
        port map (
            wr_clk_i => clk_r,

            wr_en_i => write_i,
            wr_data_i => data_i,
            full_o => full_i,

            m_axis_aclk => clk_r,
            m_axis_aresetn => reset_r,
            m_axis_tvalid => axis_0_tvalid,
            m_axis_tdata => axis_0_tdata,
            m_axis_tready => axis_0_tready
        )
    ;

    output_fifo : entity work.synchronization_fifo_axi_stream_in
        generic map (
            DATA_WIDTH => 1,
            DEPTH => 16
        )
        port map (
            s_axis_aclk => clk_r,
            s_axis_aresetn => reset_r,
            s_axis_tvalid => axis_1_tvalid,
            s_axis_tdata => axis_1_tdata,
            s_axis_tready => axis_1_tready,

            rd_clk_i => clk_r,
            rd_en_i => read_o,
            rd_data_o => data_o,
            empty_o => empty_o
        )
    ;

    clk_r <= not clk_r after clk_period / 2;


    stimulus : process
    begin
        wait for 20 ns;
        reset_r <= '0';
        wait for 20 ns;
        reset_r <= '1';
        wait for 20 ns;

        data_i <= "1";
        write_i <= '0';
        wait for clk_period * 10; -- No output expected since write_i is '0'


        write_i <= '1';
        wait for clk_period;
        data_i <= "0";
        wait for clk_period;
        data_i <= "0";
        wait for clk_period;
        data_i <= "1";
        wait for clk_period * 10;

        for i in 0 to 100 loop
            data_i <= "0";
            wait for clk_period;
            data_i <= "1";
            wait for clk_period;
        end loop;


    end process stimulus;


    output_ctrl : process
    begin
        wait until empty_o = '0';
        read_o <= '1';
        wait for clk_period * 1;
        read_o <= '0';

        wait for clk_period * 30;
        read_o <= '1';
        wait;
    end process output_ctrl;


end architecture behavioral;