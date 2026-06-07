----------------------------------------------------------------
-- File : synchronization_fifo_axi_stream_out.vhd
-- Created : 06.05.2026
-- Author : Lukas Reil 
-- Project Name : HW/SW Project TM
-- Description : Generic FIFO to synchronize between two clock domains with AXI Stream as its output interface.
--               AXI Stream I/F according to: https://www.kampis-elektroecke.de/2020/04/axi-stream-interface/
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity synchronization_fifo_axi_stream_out is
    generic (
        DATA_WIDTH : integer := 8;
        DEPTH      : integer := 16
    );
    port (

        reset_i   : in  std_logic := '1';

        -- Input Interface
        wr_clk_i   : in  std_logic;
        wr_en_i    : in  std_logic;
        wr_data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        full_o     : out std_logic;

        -- Output Interface
        m_axis_aclk : in  std_logic;
        m_axis_tvalid : out std_logic;
        m_axis_tdata  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        m_axis_tready : in  std_logic
    );
end entity synchronization_fifo_axi_stream_out;

architecture behavioral of synchronization_fifo_axi_stream_out is

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

    full_o  <= full_s;

    write_process : process(wr_clk_i, reset_i)
    begin
        if reset_i = '0' then
            wr_ptr_r <= 0;
        elsif rising_edge(wr_clk_i) then
            if wr_en_i = '1' and full_s = '0' then
                fifo_mem_r(wr_ptr_r) <= wr_data_i;
                wr_ptr_r <= (wr_ptr_r + 1) mod DEPTH;
            end if;
        end if;
    end process write_process;

    read_process : process(m_axis_aclk, reset_i)
    begin
        if reset_i = '0' then
            rd_ptr_r <= 0;
            fifo_data_out_r <= (others => '0');
            m_axis_tvalid <= '0';
        elsif rising_edge(m_axis_aclk) then
            if m_axis_tready = '1' and empty_s = '0' then
                fifo_data_out_r <= fifo_mem_r(rd_ptr_r);
                rd_ptr_r <= (rd_ptr_r + 1) mod DEPTH;
                m_axis_tvalid <= '1';
            else
                m_axis_tvalid <= '0';
            end if;
        end if;
    end process read_process;

    m_axis_tdata <= fifo_data_out_r;
    
end architecture behavioral;
