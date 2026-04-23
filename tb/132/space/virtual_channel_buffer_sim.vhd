----------------------------------------------------------------
-- File : virtual_channel_buffer_sim.vhd
-- Created : 26.11.2025
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : Testbench for the virtual_channel_buffer implementation
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity virtual_channel_buffer_sim is

end entity virtual_channel_buffer_sim;

architecture behavioral of virtual_channel_buffer_sim is
    component virtual_channel_buffer is
        port (
            clk_i: in std_logic;
            reset_i: in std_logic;
        
            -- input interface
            data_i: in std_logic_vector(7 downto 0);
            data_valid_i: in std_logic;
            ready_o: out std_logic;

            -- output interface
            frame_ready_o: out std_logic;
            data_out_en_i: in std_logic;
            data_o: out std_logic_vector(7 downto 0)
        );
    end component virtual_channel_buffer;

    constant CLK_PERIOD : time := 10 ns;

    signal clk_s: std_logic := '0';
    signal reset_s: std_logic := '0';

    signal data_i_s: std_logic_vector(7 downto 0) := (others => '0');
    signal data_valid_i_s: std_logic := '0';
    signal ready_o: std_logic;

    signal frame_ready_o_s: std_logic;
    signal data_out_en_i_s: std_logic := '0';
    signal data_o_s: std_logic_vector(7 downto 0);

begin
    virtual_channel_buffer_inst : virtual_channel_buffer
    port map(
        clk_i => clk_s,
        reset_i => reset_s,
        data_i => data_i_s,
        data_valid_i => data_valid_i_s,
        ready_o => ready_o_s,
        frame_ready_o => frame_ready_o_s,
        data_out_en_i => data_out_en_i_s,
        data_o => data_o_s
    );
    
    general_settings: process begin
        reset_s <= '0';
        wait for 50ns;
        data_valid_i_s <= '1';
        wait for CLK_PERIOD; 
        wait until frame_ready_o_s = '1'; -- time for the buffer to fill up
        wait for CLK_PERIOD; 
        data_valid_i_s <= '1';
        data_out_en_i_s <= '1';
        wait for CLK_PERIOD * 10;
        data_out_en_i_s <= '0';
        wait for CLK_PERIOD * 10;
        data_out_en_i_s <= '1';
        
    end process general_settings;

    clock: process begin
        clk_s <= not clk_s;
        wait for CLK_PERIOD;
    end process clock;
    
    data_test: process begin
        wait for CLK_PERIOD;
        
        if (ready_o_s = '1') then
            data_i_s <= std_logic_vector((unsigned(data_i_s) +1));  
        end if;
        
        wait for CLK_PERIOD;
    end process data_test;

end architecture behavioral;
