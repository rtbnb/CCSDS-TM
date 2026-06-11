----------------------------------------------------------------
-- File : top_level_space_132.vhd
-- Created : 11.06.2026
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Top Level Encoder Entity
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.virtual_channel_configuration.all;

entity top_level_space_132 is
    port (
        space_clk_i: std_logic;
        reset_i: std_logic;

        -- virtual channel 0 input interface
        vch0_s_axis_tdata        : in std_logic_vector(7 downto 0);
        vch0_s_axis_tvalid       : in std_logic;
        vch0_s_axis_tready       : out std_logic;        

        -- virtual channel 1 input interface
        vch1_s_axis_tdata        : in std_logic_vector(7 downto 0);
        vch1_s_axis_tvalid       : in std_logic;
        vch1_s_axis_tready       : out std_logic;

        -- output interface
        m_axis_tvalid : out std_logic;
        m_axis_tdata  : out std_logic_vector(7 downto 0);
        m_axis_tready : in  std_logic;
        m_axis_tlast : out std_logic
    );
end entity top_level_space_132;

architecture behavioral of top_level_space_132 is
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
           virtual_channel: integer := 1; -- zero is not allowed as a value for the virtual channel
           transfer_frame_version_number: integer := 0;
           spacecraft_id: integer := 1;
           option_has_ocf: boolean := false;
           option_has_fecf: boolean := false
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
    
    signal virtual_channel_select_s: std_logic_vector(2 downto 0);
    signal encoder_ready_s: std_logic;

    signal vch0_frame_ready_s: std_logic;
    signal vch0_data_s: std_logic_vector(7 downto 0);
    signal vch0_end_of_frame_s: std_logic;
    signal vch0_encoder_config_s: virtual_channel_configuration_t;

    signal vch1_frame_ready_s: std_logic;
    signal vch1_data_s: std_logic_vector(7 downto 0);
    signal vch1_end_of_frame_s: std_logic;
    signal vch1_encoder_config_s: virtual_channel_configuration_t;

begin

    vch0_inst: virtual_channel_buffer
    generic map (
        virtual_channel => 1,
        transfer_frame_version_number => 0,
        spacecraft_id => 1,
        option_has_ocf => false,
        option_has_fecf => false
    )
    port map (
        clk_i => space_clk_i,
        reset_i => reset_i,
        s_axis_tdata => vch0_s_axis_tdata,
        s_axis_tvalid => vch0_s_axis_tvalid,
        s_axis_tready => vch0_s_axis_tready,
        frame_ready_o => vch0_frame_ready_s,
        virtual_channel_select_i => virtual_channel_select_s,
        encoder_ready_i => encoder_ready_s,
        data_o => vch0_data_s,
        end_of_frame_o => vch0_end_of_frame_s,
        encoder_config_o => vch0_encoder_config_s
    );

    vch1_inst: virtual_channel_buffer
    generic map (
        virtual_channel => 2,
        transfer_frame_version_number => 0,
        spacecraft_id => 1,
        option_has_ocf => false,
        option_has_fecf => false
    )
    port map (
        clk_i => space_clk_i,
        reset_i => reset_i,
        s_axis_tdata => vch1_s_axis_tdata,
        s_axis_tvalid => vch1_s_axis_tvalid,
        s_axis_tready => vch1_s_axis_tready,
        frame_ready_o => vch1_frame_ready_s,
        virtual_channel_select_i => virtual_channel_select_s,
        encoder_ready_i => encoder_ready_s,
        data_o => vch1_data_s,
        end_of_frame_o => vch1_end_of_frame_s,
        encoder_config_o => vch1_encoder_config_s
    );

    transfer_frame_encoder_inst: transfer_frame_encoder
    port map(
        clk_i => space_clk_i,
        reset_i => reset_i,
        m_axis_tvalid => m_axis_tvalid,
        m_axis_tdata => m_axis_tdata,
        m_axis_tready => m_axis_tready,
        m_axis_tlast => m_axis_tlast,
        virtual_channel_select_o => virtual_channel_select_s,
        encoder_ready_o => encoder_ready_s,
        vch0_frame_ready_i => vch0_frame_ready_s,
        vch0_data_i => vch0_data_s,
        vch0_end_of_frame_i => vch0_end_of_frame_s,
        vch0_encoder_config_i => vch0_encoder_config_s,
        vch1_frame_ready_i => vch1_frame_ready_s,
        vch1_data_i => vch1_data_s,
        vch1_end_of_frame_i => vch1_end_of_frame_s,
        vch1_encoder_config_i => vch1_encoder_config_s
    );



end architecture behavioral;