----------------------------------------------------------------
-- File : virtual_channel_buffer.vhd
-- Created : 23.04.2026
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Virtual Channel Buffer Entity
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.virtual_channel_configuration.all;

entity virtual_channel_buffer is
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
end entity virtual_channel_buffer;

architecture behavioral of virtual_channel_buffer is
    component space_packet_decoder is
        port (
            header_data_i: in std_logic_vector(47 downto 0);
            packet_version_number_o: out std_logic_vector(2 downto 0);
            packet_type_o: out std_logic;
            secondary_header_flag_o: out std_logic;
            application_process_identifier_o: out std_logic_vector(10 downto 0);
            sequence_flags_o: out std_logic_vector(1 downto 0);
            packet_sequence_count_o: out std_logic_vector(13 downto 0);
            packet_length_o: out std_logic_vector(15 downto 0)
        );
    end component space_packet_decoder;
    
    component ocf_encoder is
        port(
            ocf_type_i: in std_logic;    
            sdls_fsr_report_i: in std_logic;
            project_specific_report_i: in std_logic;
            
            encoded_ocf_o: out std_logic_vector(31 downto 0);
            ocf_valid_o: out std_logic
        );
    end component ocf_encoder; 
     
    constant FRAME_DATA_BUFFER_SIZE: integer := 2040; -- 2040 bytes maximum TRANSFER FRAME DATA FIELD (ref CCSDS 132.0-B-3 Figure 4.1) and SPC-REQ-7
    constant SPACE_PACKET_PRIMARY_HEADER_SIZE: integer := 6; -- size of space packet header based on the CCSDS 133 specification
    constant SPACE_PACKET_MAX_SIZE: integer := 256; -- The maximum defined size of the space package data field as defined by SeeSat
    constant SPACE_PACKET_MAX_DATA_SIZE: integer := SPACE_PACKET_MAX_SIZE - SPACE_PACKET_PRIMARY_HEADER_SIZE; 
    
    type buffer_mem_t is array (0 to FRAME_DATA_BUFFER_SIZE -1) of std_logic_vector(7 downto 0);
    
    signal frame_data_buffer_r : buffer_mem_t := (others => (others => '0'));
    signal space_packet_header_buffer_r: std_logic_vector(47 downto 0);
    
    signal space_packet_data_length_s: std_logic_vector(15 downto 0);
    signal space_packet_size_s: integer range 0 to SPACE_PACKET_MAX_SIZE := 0;


    type space_package_decoding_state_machine_t IS (RESET, WORKING);
    signal space_packet_decoding_state_r: space_package_decoding_state_machine_t := RESET; 
    
    -- encoder config signals
    signal master_channel_frame_count_trigger_s : std_logic;
    
    -- config signals
    signal own_virtual_channel_s: std_logic_vector(2 downto 0);
    signal ocf_data_s: std_logic_vector(31 downto 0);

    -- space packet decoding signals
    signal space_packet_write_ptr_r: integer range 0 to SPACE_PACKET_MAX_SIZE -1 := 0;
    
    -- virtual channel signals
    signal virtual_channel_frame_count_r: std_logic_vector(7 downto 0) := (others => '0');

    signal internal_first_header_pointer_r: std_logic_vector(10 downto 0) := (others => '0');
    signal external_first_header_pointer_r: std_logic_vector(10 downto 0) := (others => '0');
    signal first_header_pointer_set_r: std_logic := '0';
    signal frame_write_ptr_r: integer range 0 to FRAME_DATA_BUFFER_SIZE -1 := 0;
    signal frame_read_ptr_r: integer range 0 to FRAME_DATA_BUFFER_SIZE := FRAME_DATA_BUFFER_SIZE;
    
    -- status signals
    signal frame_full_r: std_logic := '0';
    signal frame_armed_r: std_logic := '0';
    signal readout_active_r: std_logic := '0';
    signal pre_loading_active_r: std_logic := '0';
    signal end_of_frame_r: std_logic := '0';
    
    -- ocf encoder signals
    signal ocf_encoding_valid_s: std_logic;    

begin
    space_packet_decoder_inst: space_packet_decoder
    port map(
        header_data_i => space_packet_header_buffer_r,
        packet_length_o => space_packet_data_length_s
    );
    
    ocf_encoder_inst: ocf_encoder
    port map(
        ocf_type_i => '1',    
        sdls_fsr_report_i => '0',
        project_specific_report_i => '1',
        
        encoded_ocf_o => encoder_config_o.ocf_data,
        ocf_valid_o => ocf_encoding_valid_s      
    );
    
    encoder_config_o.first_header_pointer <= external_first_header_pointer_r;
    encoder_config_o.virtual_channel_frame_count <= virtual_channel_frame_count_r;
    encoder_config_o.master_channel_frame_count_trigger <= master_channel_frame_count_trigger_s;
    encoder_config_o.transfer_frame_version_number <= std_logic_vector(to_unsigned(transfer_frame_version_number, encoder_config_o.transfer_frame_version_number'length));
    encoder_config_o.spacecraft_id <= std_logic_vector(to_unsigned(spacecraft_id, encoder_config_o.spacecraft_id'length));
    
    own_virtual_channel_s <= std_logic_vector(to_unsigned(virtual_channel, own_virtual_channel_s'length));

    space_packet_size_s <= to_integer(signed(space_packet_data_length_s)) + SPACE_PACKET_PRIMARY_HEADER_SIZE;
    first_header_pointer_o <= external_first_header_pointer_r;
    
    s_axis_tready <= ((not readout_active_r) or pre_loading_active_r) and (not frame_full_r);
    frame_ready_o <= frame_armed_r;
    virtual_channel_frame_count_o <= virtual_channel_frame_count_r;
    end_of_frame_o <= end_of_frame_r;
    
    with (option_has_ocf) select
        encoder_config_o.has_ocf <= '1' when true,
                   '0' when others;
            
    with (option_has_fecf) select
        encoder_config_o.has_fecf <= '1' when true,
                    '0' when others;    
    
    -- preloading is extracted into its own process that reacts on the falling edge to make interaction with this entity more predictable
    preload_switch: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if ((frame_read_ptr_r - frame_write_ptr_r) > 1 and readout_active_r = '1') then
                pre_loading_active_r <= '1';
            else
                pre_loading_active_r <= '0';
            end if;
        end if;
        
    end process preload_switch;

    space_package_ingestion: process(clk_i)
    begin
        if rising_edge(clk_i) and reset_i = '1' then
            if (frame_armed_r = '1' and frame_full_r = '1') or (frame_full_r = '1' and readout_active_r = '1') then
                frame_full_r <= '0';
                frame_write_ptr_r <= 0;
            end if;
        
            if space_packet_decoding_state_r = RESET then
                space_packet_write_ptr_r <= 0;
                frame_write_ptr_r <= 0;
                
                space_packet_decoding_state_r <= WORKING;
                
                -- processing the first eight bits
                if s_axis_tvalid = '1' then
                    frame_data_buffer_r(frame_write_ptr_r) <= s_axis_tdata;
                    space_packet_header_buffer_r((space_packet_write_ptr_r * 8) +7 downto (space_packet_write_ptr_r * 8)) <= s_axis_tdata;
                     
                    space_packet_write_ptr_r <= space_packet_write_ptr_r + 1;
                    frame_write_ptr_r <= frame_write_ptr_r + 1;
                    if first_header_pointer_set_r = '0' then
                        internal_first_header_pointer_r <= std_logic_vector(to_unsigned(frame_write_ptr_r, internal_first_header_pointer_r'length));
                        first_header_pointer_set_r <= '1';    
                    end if;
                else
                    space_packet_header_buffer_r <= (others => '0');                
                end if;
                
            elsif space_packet_decoding_state_r = WORKING then
            
                if (frame_read_ptr_r - frame_write_ptr_r) > 1 and s_axis_tvalid = '1' and frame_full_r = '0' then
                    frame_data_buffer_r(frame_write_ptr_r) <= s_axis_tdata;    
                    frame_write_ptr_r <= frame_write_ptr_r + 1;
                    
                    space_packet_write_ptr_r <= space_packet_write_ptr_r + 1;
                    if space_packet_write_ptr_r < SPACE_PACKET_PRIMARY_HEADER_SIZE then
                        space_packet_header_buffer_r((space_packet_write_ptr_r * 8) +7 downto (space_packet_write_ptr_r * 8)) <= s_axis_tdata;
                    end if;
                    
                    if space_packet_write_ptr_r = 0 and first_header_pointer_set_r = '0' then
                        internal_first_header_pointer_r <= std_logic_vector(to_unsigned(frame_write_ptr_r, internal_first_header_pointer_r'length));
                        first_header_pointer_set_r <= '1';                      
                    end if;
                    
                end if;
            
                if space_packet_write_ptr_r > SPACE_PACKET_PRIMARY_HEADER_SIZE and space_packet_write_ptr_r = space_packet_size_s -1 then
                    space_packet_write_ptr_r <= 0;
                end if;
                
                if frame_write_ptr_r = FRAME_DATA_BUFFER_SIZE -1 then
                    frame_full_r <= '1';
                    external_first_header_pointer_r <= internal_first_header_pointer_r;
                    first_header_pointer_set_r <= '0';
                end if;                                
            end if;
        elsif reset_i = '0' then
            space_packet_write_ptr_r <= 0;
            space_packet_header_buffer_r <= (others => '0');
            frame_write_ptr_r <= 0;
                  
            space_packet_decoding_state_r <= RESET;
        end if;
        
        
        
    end process space_package_ingestion;
    
    
    data_readout: process(clk_i)
    begin
        if rising_edge(clk_i) and reset_i = '1' then
            if readout_active_r = '1' and frame_armed_r = '1' then
                frame_armed_r <= '0';
            end if;

            if end_of_frame_r = '1' then
                master_channel_frame_count_trigger_s <= '0';
                end_of_frame_r <= '0';
            end if;


            if frame_full_r = '1' and frame_armed_r = '0' and readout_active_r = '0' then
                frame_armed_r <= '1';
                frame_read_ptr_r <= 1;

                data_o <= frame_data_buffer_r(0);

                if virtual_channel_select_i = own_virtual_channel_s then
                    readout_active_r <= '1';
                end if;
                
                if virtual_channel_select_i = own_virtual_channel_s and encoder_ready_i = '1' then
                    frame_read_ptr_r <= 1; -- in this case the first octet has already been read so this has to be set to the one address
                end if;
            elsif frame_armed_r = '1' and readout_active_r = '0' and virtual_channel_select_i = own_virtual_channel_s then
                readout_active_r <= '1';
            end if;
            
            if readout_active_r = '1' and encoder_ready_i = '1' then
                data_o <= frame_data_buffer_r(frame_read_ptr_r);
                frame_read_ptr_r <= frame_read_ptr_r + 1;
                
                if frame_read_ptr_r = FRAME_DATA_BUFFER_SIZE -1 then -- This Signals the End of an TM Transfer Frame transmission
                    readout_active_r <= '0';
                    frame_read_ptr_r <= FRAME_DATA_BUFFER_SIZE;
                    virtual_channel_frame_count_r <= std_logic_vector(to_unsigned(to_integer(signed(virtual_channel_frame_count_r)) + 1, virtual_channel_frame_count_r'length));
                    master_channel_frame_count_trigger_s <= '1';
                    end_of_frame_r <= '1';
                end if;   
            end if;
        elsif reset_i = '0' then
            frame_read_ptr_r <= FRAME_DATA_BUFFER_SIZE;
        end if;


    end process data_readout;


end architecture behavioral;
