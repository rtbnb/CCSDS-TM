----------------------------------------------------------------
-- File : width_conversion_fifo_tb.vhd
-- Created : 23.04.2026
-- Author : Lukas Reil 
-- Project Name : HW/SW Project TM
-- Description : Testbench for a generic FIFO to synchronize between two clock domains with width conversion
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity width_conversion_fifo_tb is
end entity width_conversion_fifo_tb;

architecture behavioral of width_conversion_fifo_tb is

    constant DATA_WIDTH : integer := 8;
    constant DEPTH      : integer := 16;

    signal wr_clk_r   : std_logic := '0';
    signal wr_en_r    : std_logic := '0';
    signal wr_data_r  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal full_s     : std_logic;

    signal rd_clk_r   : std_logic := '0';
    signal rd_en_r    : std_logic := '0';
    signal rd_data_s  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal empty_s    : std_logic;

    signal reset_r : std_logic := '1';

    constant RD_CLK_PERIOD : time := 10 ns;
    constant WR_CLK_PERIOD : time := 7 ns;



begin

    fifo : entity work.width_conversion_fifo
        generic map (
            input_data_width_g => DATA_WIDTH,
            output_data_width_g => DATA_WIDTH,
            depth_g      => DEPTH
        )
        port map (
            reset_i   => reset_r,
            wr_clk_i   => wr_clk_r,
            wr_en_i    => wr_en_r,
            wr_data_i  => wr_data_r,
            full_o     => full_s,
            rd_clk_i   => rd_clk_r,
            rd_en_i    => rd_en_r,
            rd_data_o  => rd_data_s,
            empty_o    => empty_s
        );

    rd_clk_process : process
    begin
        rd_clk_r <= '0';
        wait for RD_CLK_PERIOD / 2;
        rd_clk_r <= '1';
        wait for RD_CLK_PERIOD / 2;
    end process rd_clk_process;

    wr_clk_process : process
    begin
        wr_clk_r <= '0';
        wait for WR_CLK_PERIOD / 2;
        wr_clk_r <= '1';
        wait for WR_CLK_PERIOD / 2;
    end process wr_clk_process;

    write_process : process
    begin
        wait for WR_CLK_PERIOD;
        wr_en_r <= '1';
        wr_data_r <= x"AA";
        wait for WR_CLK_PERIOD;
        wr_en_r <= '0';
        wait for WR_CLK_PERIOD;
        wr_en_r <= '1';
        wr_data_r <= x"BB";
        wait for WR_CLK_PERIOD;
        wr_data_r <= x"CC";
        wait for WR_CLK_PERIOD;
        wr_data_r <= x"DD";
        wait for WR_CLK_PERIOD;
        wr_en_r <= '0';
        wait for WR_CLK_PERIOD * 5;
        for i in 0 to 15 loop
            wr_en_r <= '1';
            wr_data_r <= std_logic_vector(to_unsigned(i, DATA_WIDTH));
            wait for WR_CLK_PERIOD;
        end loop;
        wr_en_r <= '0';
        wait;
    end process write_process;

    read_process : process
    begin
        wait for RD_CLK_PERIOD * 2;
        rd_en_r <= '1';
        wait for RD_CLK_PERIOD;
        rd_en_r <= '0';
        wait for RD_CLK_PERIOD * 2;
        rd_en_r <= '1';
        wait for RD_CLK_PERIOD;
        rd_en_r <= '0';
        wait for RD_CLK_PERIOD * 20;
        rd_en_r <= '1';
        wait for RD_CLK_PERIOD * 20;
        rd_en_r <= '0';
        wait;
    end process read_process;

end architecture behavioral;