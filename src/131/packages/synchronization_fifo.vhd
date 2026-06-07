----------------------------------------------------------------
-- File : synchronization_fifo.vhd
-- Created : 29.11.2025
-- Author : Lukas Reil 
-- Project Name : HW/SW Project TM
-- Description : Generic FIFO to synchronize between two clock domains
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity synchronization_fifo is
    generic (
        data_width_g : integer := 8;
        depth_g      : integer := 16
    );
    port (

        reset_i   : in  std_logic := '1';

        -- Write Interface
        wr_clk_i   : in  std_logic;
        wr_en_i    : in  std_logic;
        wr_data_i  : in  std_logic_vector(data_width_g-1 downto 0);
        full_o     : out std_logic;

        -- Read Interface
        rd_clk_i   : in  std_logic;
        rd_en_i    : in  std_logic;
        rd_data_o  : out std_logic_vector(data_width_g-1 downto 0);
        empty_o    : out std_logic
    );
end entity synchronization_fifo;

architecture behavioral of synchronization_fifo is

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

    empty_o <= empty_s;
    full_o  <= full_s;

    write_process : process(wr_clk_i, reset_i)
    begin
        if reset_i = '0' then
            wr_ptr_r <= 0;
        elsif rising_edge(wr_clk_i) then
            if wr_en_i = '1' and full_s = '0' then
                fifo_mem_r(wr_ptr_r) <= wr_data_i;
                wr_ptr_r <= (wr_ptr_r + 1) mod depth_g;
            end if;
        end if;
    end process write_process;

    read_process : process(rd_clk_i, reset_i)
    begin
        if reset_i = '0' then
            rd_ptr_r <= 0;
        elsif rising_edge(rd_clk_i) then
            if rd_en_i = '1' and empty_s = '0' then
                fifo_data_out_r <= fifo_mem_r(rd_ptr_r);
                rd_ptr_r <= (rd_ptr_r + 1) mod depth_g;
            end if;
        end if;
    end process read_process;

    rd_data_o <= fifo_data_out_r;
    
end architecture behavioral;
