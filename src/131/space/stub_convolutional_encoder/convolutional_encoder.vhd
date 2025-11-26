-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- File : convolutional_encoder.vhd
-- Created : 26.11.2025
-- Author : Lukas Reil
-- Project Name : HW/SW Project TM
-- Description : A stub for a convolutional encoder module. It does produce the same data rate as a real convolutional encoder, but uses a constraint length of 1.
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

library ieee;
use ieee.std_logic_1164.all;

entity convolutional_encoder is
    port (
        clk_i               : in  std_logic;
        reset_i             : in  std_logic;
        data_in_i           : in  std_logic;
        data_in_ready_i     : in  std_logic;
        data_out_o          : out std_logic;
        data_out_ready_o    : out std_logic
    );
end entity convolutional_encoder;


architecture behavioral of convolutional_encoder is
    signal counter_r : std_logic := '0';

    signal data_in_buffered_r : std_logic := '0';
    signal data_out_buffered_r : std_logic := '0';
    signal data_in_ready_buffered_r : std_logic := '0';
    signal data_out_ready_buffered_r : std_logic := '0';
begin

    process (clk_i, reset_i, data_in_ready_i)
    begin
        if reset_i = '0' then
            counter_r <= '0';
        elsif rising_edge(clk_i) then
            if data_in_ready_i = '1' then
                counter_r <= not counter_r;
            end if;
        end if;
    end process;

    process (clk_i, reset_i, counter_r)
    begin
        if reset_i = '0' then
            data_in_buffered_r <= '0';
            data_out_buffered_r <= '0';
            data_in_ready_buffered_r <= '0';
            data_out_ready_buffered_r <= '0';
        elsif rising_edge(clk_i) then
            if counter_r = '1' then
                data_in_buffered_r <= data_in_i;
            end if;
            
            data_out_buffered_r <= data_in_buffered_r when counter_r = '0' else not data_in_buffered_r;
            data_in_ready_buffered_r <= data_in_ready_i;
            data_out_ready_buffered_r <= data_in_ready_buffered_r;
        end if;
    end process;

    data_out_o       <= data_out_buffered_r;
    data_out_ready_o <= data_out_ready_buffered_r;


end architecture behavioral;