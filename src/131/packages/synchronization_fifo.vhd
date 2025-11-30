----------------------------------------------------------------
-- File : synchronization_fifo.vhd
-- Created : 29.11.2025
-- Author : Lukas Reil 
-- Project Name : HW/SW Project TM
-- Description : Generic FIFO to synchronize between two clock domains
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity synchronization_fifo is
    generic (
        DATA_WIDTH : integer := 8;
        DEPTH      : integer := 16
    );
    port (
        -- Write Interface
        wr_clk_i   : in  std_logic;
        wr_en_i    : in  std_logic;
        wr_data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        full_o     : out std_logic;

        -- Read Interface
        rd_clk_i   : in  std_logic;
        rd_en_i    : in  std_logic;
        rd_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        empty_o    : out std_logic
    );
end entity synchronization_fifo;

architecture behavioral of synchronization_fifo is

    type fifo_mem_t is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fifo_mem : fifo_mem_t := (others => (others => '0'));

    signal wr_ptr : integer range 0 to DEPTH-1 := 0;
    signal rd_ptr : integer range 0 to DEPTH-1 := 0;

    signal empty_s : std_logic;
    signal full_s  : std_logic;

    signal fifo_data_out_r : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

begin

    empty_s <= '1' when wr_ptr = rd_ptr else '0';
    full_s  <= '1' when ((wr_ptr + 1) mod DEPTH) = rd_ptr else '0';

    empty_o <= empty_s;
    full_o  <= full_s;

    process(wr_clk_i)
    begin
        if rising_edge(wr_clk_i) then
            if wr_en_i = '1' and full_s = '0' then
                fifo_mem(wr_ptr) <= wr_data_i;
                wr_ptr <= (wr_ptr + 1) mod DEPTH;
            end if;
        end if;
    end process;

    process(rd_clk_i)
    begin
        if rising_edge(rd_clk_i) then
            if rd_en_i = '1' and empty_s = '0' then
                fifo_data_out_r <= fifo_mem(rd_ptr);
                rd_ptr <= (rd_ptr + 1) mod DEPTH;
            end if;
        end if;
    end process;

    rd_data_o <= fifo_data_out_r;
    
end architecture behavioral;
