----------------------------------------------------------------
-- File : virtual_channel_buffer_sim.vhd
-- Created : 26.11.2025
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : Testbench for the virtual_channel_buffer implementation
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity virtual_channel_buffer_sim is

end entity virtual_channel_buffer_sim;

architecture behavioral of virtual_channel_buffer_sim is
    component space_packet_encoder is
        port (
            packet_version_number_i: in std_logic_vector(2 downto 0);
            packet_type_i: in std_logic;
            secondary_header_flag_i: in std_logic;
            application_process_identifier_i: in std_logic_vector(10 downto 0);
            sequence_flags_i: in std_logic_vector(1 downto 0);
            packet_sequence_count_i: in std_logic_vector(13 downto 0);
            packet_length_i: in std_logic_vector(15 downto 0);
            header_data_o: out std_logic_vector(47 downto 0)        
        );
    end component space_packet_encoder;

    component virtual_channel_buffer is
        generic(
           virtual_channel: integer range 0 to 7
        );
        port(
            clk_i: in std_logic;
            reset_i: in std_logic;
        
            -- input interface
            data_i: in std_logic_vector(7 downto 0);
            data_valid_i: in std_logic;
            ready_o: out std_logic;
    
            -- output interface
            frame_ready_o: out std_logic;
            virtual_channel_select_i: in std_logic_vector(2 downto 0); -- this signal signals the virtual channel that it will be read out
            data_out_en_i: in std_logic; -- this signal tells the virtual channel that the next byte can be send
            data_o: out std_logic_vector(7 downto 0) := (others => '0');
            virtual_channel_frame_count_o: out std_logic_vector(7 downto 0);
            master_channel_frame_count_trigger_o: out std_logic;
            first_header_pointer_o: out std_logic_vector(10 downto 0);
            end_of_frame_o: out std_logic      
        );
    end component virtual_channel_buffer;

    constant CLK_PERIOD : time := 10 ns;
    constant SPACE_PACKET_HEADER_SIZE: integer := 6;
    constant SPACE_PACKET_SIZE: integer := 256;
    constant SPACE_PACKET_DATA_SIZE: integer := 200; -- This is the size that is used inside the simulation as the space package size
    
    
    -- DUT Signals
    signal clk_s: std_logic := '0';
    signal reset_s: std_logic := '0';

    signal data_i_s: std_logic_vector(7 downto 0) := (others => '0');
    signal data_valid_i_s: std_logic := '0';
    signal ready_o_s: std_logic;

    signal frame_ready_o_s: std_logic;
    signal data_out_en_i_s: std_logic := '0';
    signal data_o_s: std_logic_vector(7 downto 0);
    signal virtual_channel_frame_count_s: std_logic_vector(7 downto 0);
    signal first_header_pointer_s: std_logic_vector(10 downto 0);
    signal virtual_channel_select_i_s: std_logic_vector(2 downto 0);
    signal master_channel_frame_count_trigger_o_s: std_logic;
    signal end_of_frame_o_s: std_logic;
    
    
    -- space packet header encoder signals
    signal space_packet_header_s: std_logic_vector(47 downto 0);
    
    -- simulation specific signals
    signal space_packet_counter_r: integer range 0 to SPACE_PACKET_SIZE -1 := 0;
    signal next_valid_s: std_logic := '0';
    

begin
    space_packet_header_encoder_inst: space_packet_encoder
    port map(
        packet_version_number_i => "101",
        packet_type_i => '0',
        secondary_header_flag_i => '0',
        application_process_identifier_i => (others => '0'),
        sequence_flags_i => "10",
        packet_sequence_count_i => (others => '0'),
        packet_length_i => std_logic_vector(to_unsigned(SPACE_PACKET_DATA_SIZE, 16)),
        header_data_o => space_packet_header_s
    );


    dut : virtual_channel_buffer
    generic map(
        virtual_channel => 1    
    )
    port map(
        clk_i => clk_s,
        reset_i => reset_s,
        data_i => data_i_s,
        data_valid_i => data_valid_i_s,
        ready_o => ready_o_s,
        frame_ready_o => frame_ready_o_s,
        virtual_channel_select_i => virtual_channel_select_i_s,
        data_out_en_i => data_out_en_i_s,
        data_o => data_o_s,
        virtual_channel_frame_count_o => virtual_channel_frame_count_s,
        first_header_pointer_o => first_header_pointer_s,
        master_channel_frame_count_trigger_o => master_channel_frame_count_trigger_o_s,
        end_of_frame_o => end_of_frame_o_s
    );
    
    general_settings: process begin
        reset_s <= '0';
        
        wait for 10ns;
        reset_s <= '1';
        
        wait for 35ns;
        next_valid_s <= '1';
        wait for 15ns;
        data_valid_i_s <= '1';
        
        wait;
        
    end process general_settings;

    read_out: process begin
        wait until frame_ready_o_s = '1'; -- time for the buffer to fill up
        wait for CLK_PERIOD;
        virtual_channel_select_i_s <= std_logic_vector(to_unsigned(1, virtual_channel_select_i_s'length));
        wait for CLK_PERIOD;
        data_out_en_i_s <= '1';
        
        wait for 10 * CLK_PERIOD;
        data_out_en_i_s <= '0';
        wait for 10 * CLK_PERIOD;
        data_out_en_i_s <= '1';
        
        wait;
        
    end process read_out;

    clock: process begin
        clk_s <= not clk_s;
        wait for CLK_PERIOD;
    end process clock;
    
    data_test: process begin
        wait for CLK_PERIOD;
        
        if (ready_o_s = '1' and (data_valid_i_s = '1' or next_valid_s = '1')) then
            if (space_packet_counter_r < SPACE_PACKET_HEADER_SIZE) then
                data_i_s <= space_packet_header_s((space_packet_counter_r * 8) + 7 downto (space_packet_counter_r * 8));
                space_packet_counter_r <= space_packet_counter_r +1;
            else
                data_i_s <= std_logic_vector((unsigned(data_i_s) +1));
                space_packet_counter_r <= space_packet_counter_r +1;  
            end if;
            
            if space_packet_counter_r = SPACE_PACKET_DATA_SIZE + SPACE_PACKET_HEADER_SIZE -1 then
                space_packet_counter_r <= 0;    
            end if;
        
        
             
        end if;
        
        wait for CLK_PERIOD;
    end process data_test;

end architecture behavioral;
