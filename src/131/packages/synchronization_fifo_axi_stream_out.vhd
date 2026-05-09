----------------------------------------------------------------
-- File : synchronization_fifo_axi_stream_out.vhd
-- Created : 06.05.2026
-- Author : Lukas Reil 
-- Project Name : HW/SW Project TM
-- Description : Generic FIFO to synchronize between two clock domains with AXI Stream as its output interface.
--               AXI Stream I/F according to: https://www.kampis-elektroecke.de/2020/04/axi-stream-interface/
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity synchronization_fifo_axi_stream_out is
    generic (
        data_width_g : integer := 8;
        depth_g      : integer := 16
    );
    port (
        -- Input Interface
        wr_clk_i   : in  std_logic;
        wr_en_i    : in  std_logic;
        wr_data_i  : in  std_logic_vector(data_width_g-1 downto 0);
        full_o     : out std_logic;

        -- Output Interface
        aclk_i    : in  std_logic;
        aresetn_i : in  std_logic;
        tvalid_o  : out std_logic;
        tdata_o   : out std_logic_vector(data_width_g-1 downto 0);
        tready_i  : in  std_logic
    );
end entity synchronization_fifo_axi_stream_out;

architecture behavioral of synchronization_fifo_axi_stream_out is

    type fifo_mem_t is array (0 to depth_g-1) of std_logic_vector(data_width_g-1 downto 0);
    signal fifo_mem_r : fifo_mem_t := (others => (others => '0'));

    signal wr_ptr_r : integer range 0 to depth_g-1 := 0;
    signal rd_ptr_r : integer range 0 to depth_g-1 := 0;
    signal empty_s : std_logic;
    signal full_s  : std_logic;

    signal fifo_data_out_r : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
begin

    empty_s <= '1' when wr_ptr_r = rd_ptr_r else '0';
    full_s  <= '1' when ((wr_ptr_r + 1) mod depth_g) = rd_ptr_r else '0';

    full_o  <= full_s;

    process(wr_clk_i)
    begin
        if rising_edge(wr_clk_i) then
            if wr_en_i = '1' and full_s = '0' then
                fifo_mem_r(wr_ptr_r) <= wr_data_i;
                wr_ptr_r <= (wr_ptr_r + 1) mod depth_g;
            end if;
        end if;
    end process;

    process(aclk_i, aresetn_i)
    begin
        if aresetn_i = '0' then
            -- rd_ptr_r <= 0; -- Reset logic currently not implemented.
            fifo_data_out_r <= (others => '0');
        elsif rising_edge(aclk_i) then
            if tready_i = '1' and empty_s = '0' then
                fifo_data_out_r <= fifo_mem_r(rd_ptr_r);
                rd_ptr_r <= (rd_ptr_r + 1) mod depth_g;
                tvalid_o <= '1';
            else
                tvalid_o <= '0';
            end if;
        end if;
    end process;

    tdata_o <= fifo_data_out_r;
    
end architecture behavioral;
