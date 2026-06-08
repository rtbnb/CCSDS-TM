----------------------------------------------------------------
-- File : stub_convolutional_decoder.vhd
-- Created : 27.11.2025
-- Author : Lukas Reil
-- Project Name : HW/SW Project TM
-- Description : A stub for a convolutional decoder module. It does produce the same data rate as a real convolutional decoder, but uses a constraint length of 1.
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity stub_convolutional_decoder is
    port (
        clk_i               : in  std_logic;
        reset_i             : in  std_logic;
        data_in_i           : in  std_logic;
        data_in_ready_i     : in  std_logic;
        data_out_o          : out std_logic;
        data_out_ready_o    : out std_logic
    );
end entity stub_convolutional_decoder;

architecture behavioral of stub_convolutional_decoder is
    constant CLOCK_DIVIDER : integer := 100;
    -- Divide by 4, because the decoder produces a bit every 100 clock cycles and the encoder produces 2 bits every 100 clock cycles.
    -- The input gets sampled in the middle of the first transmitted bit, which is the bit, that belongs to the original data.
    constant PHASE_OFFSET : integer := CLOCK_DIVIDER / 4;

    signal data_in_buffered_r : std_logic := '0';
    signal data_out_ready_r : std_logic := '0';

begin

    data_processing : process (clk_i, reset_i)
        variable clock_cycle_count_r : integer range 0 to CLOCK_DIVIDER := 0;
    begin
        if reset_i = '0' then
            clock_cycle_count_r := 0;
            data_in_buffered_r <= '0';
            data_out_ready_r <= '0';
        elsif rising_edge(clk_i) then
            if data_in_ready_i = '0' then
                clock_cycle_count_r := 0;
            else
                clock_cycle_count_r := clock_cycle_count_r + 1;
                if clock_cycle_count_r = CLOCK_DIVIDER then
                    clock_cycle_count_r := 0;
                elsif clock_cycle_count_r = PHASE_OFFSET then
                    data_in_buffered_r <= data_in_i;
                    data_out_ready_r <= '1';
                elsif clock_cycle_count_r = PHASE_OFFSET + 1 then
                    data_out_ready_r <= '0';
                end if;
            end if;
        end if;
    end process data_processing;

    data_out_o       <= data_in_buffered_r;
    data_out_ready_o <= data_out_ready_r;   

end architecture behavioral;