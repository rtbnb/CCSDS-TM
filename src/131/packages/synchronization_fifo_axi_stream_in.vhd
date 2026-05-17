----------------------------------------------------------------
-- File : synchronization_fifo_axi_stream_in.vhd
-- Created : 06.05.2026
-- Author : Lukas Reil 
-- Project Name : HW/SW Project TM
-- Description : Generic FIFO to synchronize between two clock domains with AXI Stream as its input interface.
--               AXI Stream I/F according to: https://www.kampis-elektroecke.de/2020/04/axi-stream-interface/
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity synchronization_fifo_axi_stream_in is
    generic (
        DATA_WIDTH : integer := 8;
        DEPTH      : integer := 16
    );
    port (
        -- Input Interface
        s_axis_aclk : in  std_logic;
        s_axis_aresetn : in  std_logic;
        s_axis_tvalid : in  std_logic;
        s_axis_tdata  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        s_axis_tready : out std_logic;

        -- Read Interface
        rd_clk_i   : in  std_logic;
        rd_en_i    : in  std_logic;
        rd_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        empty_o    : out std_logic
    );
end entity synchronization_fifo_axi_stream_in;

library ieee;
use ieee.std_logic_1164.all;

architecture behavioral of synchronization_fifo_axi_stream_in is

    type fifo_mem_t is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fifo_mem_r : fifo_mem_t := (others => (others => '0'));

    signal wr_ptr_r : integer range 0 to DEPTH-1 := 0;
    signal rd_ptr_r : integer range 0 to DEPTH-1 := 0;
    signal empty_s : std_logic;
    signal full_s  : std_logic;

    signal fifo_data_out_r : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
begin

    empty_s <= '1' when wr_ptr_r = rd_ptr_r else '0';
    full_s  <= '1' when ((wr_ptr_r + 1) mod DEPTH) = rd_ptr_r else '0';

    empty_o <= empty_s;
    s_axis_tready <= not full_s;

    process(s_axis_aclk, s_axis_aresetn)
    begin
        if s_axis_aresetn = '0' then
            -- wr_ptr_r <= 0; -- Reset logic currently not implemented.
        elsif rising_edge(s_axis_aclk) then
            if s_axis_tvalid = '1' and full_s = '0' then
                fifo_mem_r(wr_ptr_r) <= s_axis_tdata;
                wr_ptr_r <= (wr_ptr_r + 1) mod DEPTH;
            end if;
        end if;
    end process;

    process(rd_clk_i)
    begin
        if rising_edge(rd_clk_i) then
            if rd_en_i = '1' and empty_s = '0' then
                fifo_data_out_r <= fifo_mem_r(rd_ptr_r);
                rd_ptr_r <= (rd_ptr_r + 1) mod DEPTH;
            end if;
        end if;
    end process;

    rd_data_o <= fifo_data_out_r;
    
end architecture behavioral;
