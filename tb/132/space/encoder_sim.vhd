----------------------------------------------------------------
-- File : encoder_sim.vhd
-- Created : 24.04.2026
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : Testbench for the integration between the transfer frame encoder and the virtual channel buffer
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity encoder_sim is

end entity encoder_sim;

architecture behavioral of encoder_sim is
    component transfer_frame_encoder is
        port (
            clk_i: in std_logic;
            reset_i: in std_logic;
            
            -- configuration data
            transfer_frame_version_number_i: in std_logic_vector(1 downto 0);
            spacecraft_id_i: in std_logic_vector(9 downto 0);       
            
            -- output interface
            out_clk_o: out std_logic;
            out_en_o: out std_logic;
            data_o: out std_logic_vector(7 downto 0);
            out_full_i: in std_logic;
        
            -- input interface
        
            -- virtual channel 0
            vch0_frame_ready_i: in std_logic;
            vch0_data_en_o: out std_logic;
            vch0_data_i: in std_logic_vector(7 downto 0);
            vch0_virtual_channel_frame_count_i: in std_logic_vector(7 downto 0)
        );
    end component transfer_frame_encoder;
    
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

    signal transfer_frame_version_number_s: std_logic_vector(1 downto 0);
    signal spacecraft_id_s: std_logic_vector(9 downto 0);
    signal out_clk_s: std_logic := '0';
    signal out_en_s: std_logic := '0';
    signal data_o_s: std_logic_vector(7 downto 0);
    signal out_full_i_s: std_logic := '0';
    signal vch0_virtual_channel_frame_count_i_s: std_logic_vector(7 downto 0) := (others => '0');

    -- test signals
    signal test_input_data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal test_input_valid_s: std_logic := '0';
    signal test_input_ready_s: std_logic;

    -- virtual channel to transfer frame encoder signals
    signal vch0_frame_ready_o: std_logic;
    signal vch0_data_out_en_i: std_logic;
    signal vch0_data_o: std_logic_vector(7 downto 0);

begin
    transfer_frame_encoder_inst : transfer_frame_encoder
    port map(
        clk_i => clk_s,
        reset_i => reset_s,
        transfer_frame_version_number_i => transfer_frame_version_number_s,
        spacecraft_id_i => spacecraft_id_s,
        out_clk_o => out_clk_s,
        out_en_o => out_en_s,
        data_o => data_o_s,
        out_full_i => out_full_i_s,
        vch0_frame_ready_i => vch0_frame_ready_o,
        vch0_data_en_o => vch0_data_out_en_i,
        vch0_data_i => vch0_data_o,
        vch0_virtual_channel_frame_count_i => vch0_virtual_channel_frame_count_i_s
    );

    virtual_channel_buffer_inst: virtual_channel_buffer
    port map(
        clk_i => clk_s,
        reset_i => reset_s,
        data_i => test_input_data_s,
        data_valid_i => test_input_valid_s,
        ready_o => test_input_ready_s,
        frame_ready_o => vch0_frame_ready_o,
        data_out_en_i => vch0_data_out_en_i,
        data_o => vch0_data_o        
    );
    
    general_settings: process begin
        reset_s <= '0';
        transfer_frame_version_number_s <= "11";
        spacecraft_id_s <= "0000000001";
        test_input_valid_s <= '1';
        wait;
    end process general_settings;

    clock: process begin
        clk_s <= not clk_s;
        wait for CLK_PERIOD;
    end process clock;
    
    data_test: process begin
        wait for CLK_PERIOD;
        
        if (test_input_ready_s = '1') then
            test_input_data_s <= std_logic_vector((unsigned(test_input_data_s) +1));  
        end if;
        
        wait for CLK_PERIOD;
    end process data_test;

end architecture behavioral;
