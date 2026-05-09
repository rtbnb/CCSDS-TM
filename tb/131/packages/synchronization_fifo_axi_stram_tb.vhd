----------------------------------------------------------------
-- File : synchronization_fifo_axi_stream_tb.vhd
-- Created : 06.05.2025
-- Author : Lukas Reil 
-- Project Name : HW/SW Project TM
-- Description : Testbench for a FIFO to synchronize between two clock domains with AXI Stream
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity synchronization_fifo_axi_stream_tb is
end entity synchronization_fifo_axi_stream_tb;

architecture behavioral of synchronization_fifo_axi_stream_tb is

    constant DATA_WIDTH : integer := 8;
    constant DEPTH      : integer := 16;
    
    constant RD_CLK_PERIOD : time := 10 ns;
    constant WR_CLK_PERIOD : time := 11 ns;
    constant ACLK_PERIOD : time := 7 ns;
    
    signal aclk_r : std_logic := '0';
    signal aresetn_r : std_logic := '1';
    signal data_i : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal data_o : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal empty : std_logic;
    signal full : std_logic;
    
    signal rd_clk_r   : std_logic := '0';
    signal rd_en_r    : std_logic := '0';
    signal wr_clk_r   : std_logic := '0';
    signal wr_en_r    : std_logic := '0';


    component design_2_wrapper is
        port (
            aclk : in STD_LOGIC;
            aresetn : in STD_LOGIC;
            data_i : in STD_LOGIC_VECTOR ( 7 downto 0 );
            data_o : out STD_LOGIC_VECTOR ( 7 downto 0 );
            empty : out STD_LOGIC;
            full : out STD_LOGIC;
            rd_clk : in STD_LOGIC;
            rd_en : in STD_LOGIC;
            wr_clk : in STD_LOGIC;
            wr_en : in STD_LOGIC
        );
    end component design_2_wrapper;


begin

    dut : design_2_wrapper
        port map (
            aclk => aclk_r,
            aresetn => aresetn_r,
            data_i => data_i,
            data_o => data_o,
            empty => empty,
            full => full,
            rd_clk => rd_clk_r,
            rd_en => rd_en_r,
            wr_clk => wr_clk_r,
            wr_en => wr_en_r
        );

    rd_clk_r <= not rd_clk_r after RD_CLK_PERIOD / 2;
    wr_clk_r <= not wr_clk_r after WR_CLK_PERIOD / 2;
    aclk_r <= not aclk_r after ACLK_PERIOD / 2;

    write_process : process
    begin
        wait for WR_CLK_PERIOD;
        wr_en_r <= '1';
        data_i <= x"AA";
        wait for WR_CLK_PERIOD;
        wr_en_r <= '0';
        wait for WR_CLK_PERIOD;
        wr_en_r <= '1';
        data_i <= x"BB";
        wait for WR_CLK_PERIOD;
        data_i <= x"CC";
        wait for WR_CLK_PERIOD;
        data_i <= x"DD";
        wait for WR_CLK_PERIOD;
        wr_en_r <= '0';
        wait for WR_CLK_PERIOD * 5;
        for i in 0 to 15 loop
            wr_en_r <= '1';
            data_i <= std_logic_vector(to_unsigned(i, DATA_WIDTH));
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
        wait for RD_CLK_PERIOD * 30;
        rd_en_r <= '1';
        wait for RD_CLK_PERIOD * 20;
        rd_en_r <= '0';
        wait;
    end process read_process;

end architecture behavioral;