----------------------------------------------------------------
-- File : width_conversion_fifo.vhd
-- Created : 23.04.2026
-- Author : Lukas Reil 
-- Project Name : HW/SW Project TM
-- Description : FIFO to change data width between two clock domains. The FIFO can be configured to have an input data width that is either wider, narrower or the same as the output data width. The FIFO depth is defined in terms of the number of output data words it can hold.
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity width_conversion_fifo is
    generic (
        input_data_width_g : integer := 8;
        output_data_width_g : integer := 8;
        depth_g      : integer := 16  -- How many entries the FIFO can hold (the width is which ever is wider)
    );
    port (
        -- Write Interface
        wr_clk_i   : in  std_logic;
        wr_en_i    : in  std_logic;
        wr_data_i  : in  std_logic_vector(input_data_width_g-1 downto 0);
        full_o     : out std_logic;

        -- Read Interface
        rd_clk_i   : in  std_logic;
        rd_en_i    : in  std_logic;
        rd_data_o  : out std_logic_vector(output_data_width_g-1 downto 0);
        empty_o    : out std_logic
    );
end entity width_conversion_fifo;

architecture behavioral of width_conversion_fifo is

    type fifo_mode_t is (SAME, INPUT_WIDER, OUTPUT_WIDER);
    constant FIFO_MODE : fifo_mode_t := 
                SAME            when input_data_width_g = output_data_width_g else
                INPUT_WIDER     when input_data_width_g > output_data_width_g else
                OUTPUT_WIDER;
    
    constant RATIO : integer := 
                1               when FIFO_MODE = SAME else
                input_data_width_g / output_data_width_g when FIFO_MODE = INPUT_WIDER else
                output_data_width_g / input_data_width_g;
    
    constant FIFO_MEM_WIDTH : integer := 
                input_data_width_g  when FIFO_MODE = SAME or FIFO_MODE = INPUT_WIDER else
                output_data_width_g;
    
    type fifo_mem_t is array (0 to depth_g-1) of std_logic_vector(FIFO_MEM_WIDTH-1 downto 0);
    signal fifo_mem_r : fifo_mem_t := (others => (others => '0'));

    signal wr_ptr_r : integer range 0 to depth_g-1 := 0;
    signal rd_ptr_r : integer range 0 to depth_g-1 := 0;
    signal empty_s : std_logic;
    signal full_s  : std_logic;

    signal fifo_data_out_r : std_logic_vector(output_data_width_g-1 downto 0) := (others => '0');

    
begin

    assert (
        (input_data_width_g > 0) and (output_data_width_g > 0) and (depth_g > 0)
    ) 
    report "Data widths and depth must be positive integers" severity failure;

    assert (
        ((input_data_width_g mod output_data_width_g) = 0 and (input_data_width_g > output_data_width_g))
        or 
        ((input_data_width_g mod input_data_width_g) = 0 and (output_data_width_g > input_data_width_g))
        or
        (input_data_width_g = output_data_width_g)
    )
    report "Input and output data widths must be multiples of each other" severity failure;

    empty_s <= '1' when wr_ptr_r = rd_ptr_r else '0';
    full_s  <= '1' when ((wr_ptr_r + 1) mod depth_g) = rd_ptr_r else '0';

    empty_o <= empty_s;
    full_o  <= full_s;

    write_process : process(wr_clk_i)
        variable expander_counter_v : integer range 0 to RATIO-1 := RATIO - 1;
    begin
        if rising_edge(wr_clk_i) then
            if wr_en_i = '1' and full_s = '0' then
                if FIFO_MODE = SAME or FIFO_MODE = INPUT_WIDER then
                    fifo_mem_r(wr_ptr_r) <= wr_data_i;
                    wr_ptr_r <= (wr_ptr_r + 1) mod depth_g;
                elsif FIFO_MODE = OUTPUT_WIDER then
                    fifo_mem_r(wr_ptr_r)(
                        (expander_counter_v + 1) * input_data_width_g - 1 downto expander_counter_v * input_data_width_g
                    ) <= wr_data_i;
                    expander_counter_v := (expander_counter_v - 1) mod RATIO;
                    if expander_counter_v = RATIO - 1 then
                        wr_ptr_r <= (wr_ptr_r + 1) mod depth_g;
                    end if;
                end if;
            end if;
        end if;
    end process write_process;

    read_process : process(rd_clk_i)
        variable expander_counter_v : integer range 0 to RATIO-1 := RATIO - 1;  
    begin
        if rising_edge(rd_clk_i) then
            if rd_en_i = '1' and empty_s = '0' then
                
                if FIFO_MODE = SAME or FIFO_MODE = OUTPUT_WIDER then
                    fifo_data_out_r <= fifo_mem_r(rd_ptr_r);
                    rd_ptr_r <= (rd_ptr_r + 1) mod depth_g;
                elsif FIFO_MODE = INPUT_WIDER then
                    fifo_data_out_r <= fifo_mem_r(rd_ptr_r)(
                        (expander_counter_v + 1) * output_data_width_g - 1 downto expander_counter_v * output_data_width_g
                    );
                    expander_counter_v := (expander_counter_v - 1) mod RATIO;
                    if expander_counter_v = RATIO - 1 then
                        rd_ptr_r <= (rd_ptr_r + 1) mod depth_g;
                    end if;
                end if;

            end if;
        end if;
    end process read_process;

    rd_data_o <= fifo_data_out_r;
    
end architecture behavioral;
