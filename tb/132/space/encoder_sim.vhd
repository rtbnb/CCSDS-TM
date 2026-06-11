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
library work;
use work.virtual_channel_configuration.all;

entity encoder_sim is

end entity encoder_sim;

architecture behavioral of encoder_sim is
    component transfer_frame_encoder is
        port (
            clk_i: in std_logic;
            reset_i: in std_logic;
            
            -- output interface
            m_axis_tvalid : out std_logic;
            m_axis_tdata  : out std_logic_vector(7 downto 0);
            m_axis_tready : in  std_logic;
            m_axis_tlast : out std_logic;
           
            -- input interface
            virtual_channel_select_o: out std_logic_vector(2 downto 0) := (others => '0');
            encoder_ready_o: out std_logic; -- this signal tells the virtual channel that the next byte can be send
            
            -- master channel 0
                -- virtual channel 0
            vch0_frame_ready_i: in std_logic;
            vch0_data_i: in std_logic_vector(7 downto 0) := (others => '0');
            vch0_end_of_frame_i: in std_logic;
            vch0_encoder_config_i: in virtual_channel_configuration_t;
            
                -- virtual channel 1
            vch1_frame_ready_i: in std_logic;
            vch1_data_i: in std_logic_vector(7 downto 0) := (others => '0');
            vch1_end_of_frame_i: in std_logic;
            vch1_encoder_config_i: in virtual_channel_configuration_t
        );
    end component transfer_frame_encoder;
    
    component virtual_channel_buffer is
        generic(
            VIRTUAL_CHANNEL: integer := 1; -- zero is not allowed as a value for the virtual channel
            TRANSFER_FRAME_VERSION_NUMBER: integer := 0;
            SPACECRAFT_ID: integer := 1;
            OPTION_HAS_OCF: boolean := false;
            OPTION_HAS_FECF: boolean := false
        );
        port(
            clk_i: in std_logic;
            reset_i: in std_logic;
        
            -- input interface
            s_axis_tdata        : in std_logic_vector(7 downto 0);
            s_axis_tvalid       : in std_logic;
            s_axis_tready       : out std_logic;
    
            -- output interface
            frame_ready_o: out std_logic;
            virtual_channel_select_i: in std_logic_vector(2 downto 0); -- this signal signals the virtual channel that it will be read out
            encoder_ready_i: in std_logic; -- this signal tells the virtual channel that the next byte can be send
            data_o: out std_logic_vector(7 downto 0) := (others => '0');
            end_of_frame_o: out std_logic;
            
            -- output config data
            encoder_config_o: out virtual_channel_configuration_t
        );
    end component virtual_channel_buffer;
    
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

    constant CLK_PERIOD : time := 10 ns;
    
    signal empty_vch_config_s : virtual_channel_configuration_t := (
        has_ocf => '0',
        ocf_data => (others => '0'),
        has_fecf => '0',
        first_header_pointer => (others => '0'),
        virtual_channel_frame_count => (others => '0'),
        master_channel_frame_count_trigger => '0',
        
        transfer_frame_version_number => (others => '0'),
        spacecraft_id => (others => '0'),
        virtual_channel_id => (others => '0'),
        
        has_secondary_header => '0',
        secondary_header_data => (others => '0'),
        secondary_header_valid => '0',
        secondary_header_last_byte => '0'
    );

    constant SPACE_PACKET_HEADER_SIZE: integer := 6;
    constant SPACE_PACKET_SIZE: integer := 256;
    constant SPACE_PACKET_DATA_SIZE: integer := 200; -- This is the size that is used inside the simulation as the space package size    
    signal space_packet_counter_r: integer range 0 to SPACE_PACKET_SIZE -1 := 0;
    
    -- space packet encoder signals
    signal space_packet_header_s: std_logic_vector(47 downto 0);
    
    signal clk_s: std_logic := '0';
    signal reset_s: std_logic := '0';
    
    -- signals between the transfer frame encoder and the virtual buffers
    signal virtual_channel_select_s: std_logic_vector(2 downto 0) := (others => '0');
    signal encoder_ready_s: std_logic := '0';

    
    -- vch0
    signal vch0_frame_ready_s: std_logic;
    signal vch0_data_s: std_logic_vector(7 downto 0);
    signal vch0_end_of_frame_s: std_logic;
    signal vch0_encoder_config_s: virtual_channel_configuration_t;
    
    -- input test signals
    signal s_axis_tdata_s  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_axis_tvalid_s : std_logic := '0';
    signal s_axis_tready_s : std_logic := '0';    
    
    -- output test signals
    signal m_axis_tvalid_s   : std_logic := '0';
    signal m_axis_tdata_s    : std_logic_vector(7 downto 0) := (others => '0');
    signal m_axis_tready_s   : std_logic := '0';
    signal m_axis_tlast_s    : std_logic := '0';

    -- virtual channel to transfer frame encoder signals
    signal vch0_frame_ready_o: std_logic;
    signal vch0_data_out_en_i: std_logic;
    signal vch0_data_o: std_logic_vector(7 downto 0);

begin
    transfer_frame_encoder_inst : transfer_frame_encoder
    port map(
        clk_i => clk_s,
        reset_i => reset_s,
        
        -- output interface
        m_axis_tvalid => m_axis_tvalid_s,
        m_axis_tdata => m_axis_tdata_s,
        m_axis_tready => m_axis_tready_s,
        m_axis_tlast => m_axis_tlast_s,
       
        -- input interface
        virtual_channel_select_o => virtual_channel_select_s,
        encoder_ready_o => encoder_ready_s,
        
        -- master channel 0
            -- virtual channel 0
        vch0_frame_ready_i => vch0_frame_ready_s,
        vch0_data_i => vch0_data_s,
        vch0_end_of_frame_i => vch0_end_of_frame_s,
        vch0_encoder_config_i => vch0_encoder_config_s,
        
            -- virtual channel 1
        vch1_frame_ready_i => '0',
        vch1_data_i => (others => '0'),
        vch1_end_of_frame_i => '0',
        vch1_encoder_config_i => empty_vch_config_s
    );

    vch0_buffer_inst: virtual_channel_buffer
    port map(
            clk_i => clk_s,
            reset_i => reset_s,
        
            -- input interface
            s_axis_tdata => s_axis_tdata_s,
            s_axis_tvalid => s_axis_tvalid_s,
            s_axis_tready => s_axis_tready_s,
    
            -- output interface
            frame_ready_o => vch0_frame_ready_s,
            virtual_channel_select_i => virtual_channel_select_s, -- this signal signals the virtual channel that it will be read out
            encoder_ready_i => encoder_ready_s,
            data_o => vch0_data_s,
            end_of_frame_o => vch0_end_of_frame_s,
            
            -- output config data
            encoder_config_o => vch0_encoder_config_s  
    );
    
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

    
    general_settings: process begin
        reset_s <= '0';
        wait for 100 * CLK_PERIOD;
        reset_s <= '1';
        wait;
    end process general_settings;

    clock: process begin
        clk_s <= not clk_s;
        wait for CLK_PERIOD;
    end process clock;
    
    data_inject_test: process begin
        wait for 2 * CLK_PERIOD;
        
        if s_axis_tready_s = '1' and reset_s = '1' then
            s_axis_tvalid_s <= '1';
            if (space_packet_counter_r < SPACE_PACKET_HEADER_SIZE) then
                s_axis_tdata_s <= space_packet_header_s((space_packet_counter_r * 8) + 7 downto (space_packet_counter_r * 8));
                space_packet_counter_r <= space_packet_counter_r +1;
            else
                s_axis_tdata_s <= std_logic_vector((unsigned(s_axis_tdata_s) +1));
                space_packet_counter_r <= space_packet_counter_r +1;  
            end if;
            
            if space_packet_counter_r = SPACE_PACKET_DATA_SIZE + SPACE_PACKET_HEADER_SIZE -1 then
                space_packet_counter_r <= 0;    
            end if;
        end if;
    end process data_inject_test;

    data_out_process: process begin
        wait for 50 * CLK_PERIOD;
        m_axis_tready_s <= '1'; 
        
        wait;
    end process data_out_process;

end architecture behavioral;
