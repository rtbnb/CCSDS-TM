----------------------------------------------------------------
-- File : transfer_frame_encoder.vhd
-- Created : 23.04.2026
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Transfer Frame Encoder
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.virtual_channel_configuration.all;

entity transfer_frame_encoder is
	Port(
        clk_i: in std_logic;
        reset_i: in std_logic;
        
        -- output interface
        m_axis_tvalid : out std_logic;
        m_axis_tdata  : out std_logic_vector(7 downto 0);
        m_axis_tready : in  std_logic;
        m_axis_tlast : out std_logic := '0';
	   
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
end entity transfer_frame_encoder;

architecture behavioral of transfer_frame_encoder is
    component header_encoder is
        Port(
            transfer_frame_version_number_i: in std_logic_vector(1 downto 0);
            spacecraft_id_i: in std_logic_vector(9 downto 0);
            virtual_channel_id_i: in std_logic_vector(2 downto 0);
            ocf_flag_i: in std_logic;
            master_channel_frame_count_i: in std_logic_vector(7 downto 0);
            virtual_channel_frame_count_i: in std_logic_vector(7 downto 0);
            transfer_frame_secondary_header_flag_i: in std_logic;
            snych_flag_i: in std_logic;
            packet_order_flag_i: in std_logic;
            segment_length_id_i: in std_logic_vector(1 downto 0);
            first_header_pointer_i: in std_logic_vector(10 downto 0);
            is_oid_flag_i: in std_logic;
            header_data_o: out std_logic_vector(47 downto 0)
        );
    end component header_encoder;
    
    component secondary_header_encoder is
        generic (
            SECONDARY_HEADER_DATA_FIELD_WIDTH_OCTETS : integer := 63 -- maximum length of this parameter is 63 according to CCSDS-132.0-B-3 4.1.3.1.6
        );
        port (
            output_clk_i : in std_logic;
            input_clk_i : in std_logic;
            version_number_i : in std_logic_vector(1 downto 0);
            length_i : in std_logic_vector(5 downto 0);
            data_field_i : in std_logic_vector(7 downto 0);
            secondary_header_o : out std_logic_vector(7 downto 0) := (others => '0');
            secondary_header_fully_read_o : out std_logic := '0'; -- high in the clk cycle when the last byte is read
            secondary_header_valid_o : out std_logic := '0'
        );
    end component secondary_header_encoder;  
    
    component oid_generator is
        port(
            -- input ports 
            clk_i           : in std_logic; 
            reset_i         : in std_logic;
            enable_i        : in std_logic;  
            -- output ports  
            data_o          : out std_logic_vector(7 downto 0);
            data_valid_o    : out std_logic
        );
    end component oid_generator;
    
    component fecf_encoder is
        port(
            clk_i: in std_logic;
            en_i: in std_logic;
            reset_i: in std_logic;
            data_i: in std_logic_vector(7 downto 0);
            
            fecf_o: out std_logic_vector(15 downto 0)        
        );
    end component fecf_encoder;    

    constant PRIMARY_HEADER_LENGTH: integer := 6;
    constant GENERIC_SPACECRAFT_ID: std_logic_vector(9 downto 0) := "0000000001";
    constant OID_FIRST_HEADER_POINTER: std_logic_vector(10 downto 0) := "11111111110";

    type state_machine_t IS (RESET, PRIMARY_HEADER, SECONDARY_HEADER, PAYLOAD, OCF, FECF);
    type selected_vch_t IS (OID_VCH, VCH0, VCH1);    

    function f_select_next_vch (
        is_oid_frame_r          : in std_logic;
        vch0_frame_ready_i      : in std_logic;
        vch1_frame_ready_i      : in std_logic
    ) return selected_vch_t is
    begin
        if is_oid_frame_r = '1' then
            return OID_VCH;
        else
            if vch0_frame_ready_i = '1' then
                return VCH0;
            elsif vch1_frame_ready_i = '1' then
                return VCH1;
            end if;
        end if;
        
        return OID_VCH;
    
    end function f_select_next_vch;
    
    --state machine signal
    signal state_r: state_machine_t := RESET;
    
    -- signal to show which vch is selected
    signal selected_vch_r: selected_vch_t := OID_VCH;
    signal is_oid_frame_s: std_logic;
    
    --virtual buffer combination signals
    signal any_vch_available_s: std_logic := '0';
    
    -- oid helper signals
    signal oid_vch_config_r: virtual_channel_configuration_t;
    signal oid_end_of_frame_r: std_logic := '0';
    
    -- currently selected virtual buffer data
    signal current_vch_config_r: virtual_channel_configuration_t;
    signal current_vch_data_r: std_logic_vector(7 downto 0);
    signal current_vch_end_of_frame_r: std_logic;
    signal current_vch_valid_r: std_logic := '0';
    signal current_vch_ready_r: std_logic := '0';
    
    signal internal_valid_s : std_logic := '0';
    signal internal_tlast_s : std_logic := '0';
    
    signal master_channel_frame_count_r: std_logic_vector(7 downto 0) := (others => '0');
    
    signal header_data_r: std_logic_vector(47 downto 0);
    signal primary_header_ptr_r: integer range 0 to PRIMARY_HEADER_LENGTH -1 := 0;
    
    constant OID_PACKET_LENGTH: integer := 2040;
    signal oid_length_counter_r: integer range 0 to OID_PACKET_LENGTH -1 := 0;
    
    signal virtual_channel_out_enable_r: std_logic;
    
    -- oid generator signals
    signal oid_generator_enable_s: std_logic := '0';
    signal oid_generator_data_s: std_logic_vector(7 downto 0);
    signal oid_generator_data_valid_s: std_logic;
    
    signal oid_primed_s: std_logic := '0';
    signal oid_primed_used_s: std_logic := '0';
    
    -- fecf encoder signals
    signal fecf_data_s: std_logic_vector(15 downto 0) := (others => '0');
    
begin
    
    header_encoder_inst: header_encoder port map (
        transfer_frame_version_number_i => current_vch_config_r.transfer_frame_version_number,
        spacecraft_id_i => current_vch_config_r.spacecraft_id,
        virtual_channel_id_i => current_vch_config_r.virtual_channel_id,
        ocf_flag_i => current_vch_config_r.has_ocf,
        master_channel_frame_count_i => master_channel_frame_count_r,
        virtual_channel_frame_count_i => current_vch_config_r.virtual_channel_frame_count,
        transfer_frame_secondary_header_flag_i => current_vch_config_r.has_secondary_header,
        snych_flag_i => '0',
        packet_order_flag_i => '0',
        segment_length_id_i => "11",
        first_header_pointer_i => current_vch_config_r.first_header_pointer,
        is_oid_flag_i => is_oid_frame_s,
        header_data_o => header_data_r
    );
    
    secondary_header_encoder_inst: secondary_header_encoder
    generic map(
        SECONDARY_HEADER_DATA_FIELD_WIDTH_OCTETS => 63
    )
    port map(
        output_clk_i => '0',
        input_clk_i => '0',
        version_number_i => (others => '0'),
        length_i => (others => '0'),
        data_field_i => (others => '0')
--        secondary_header_o => (others => '0'),
--        secondary_header_fully_read_o => (others => '0'),
--        secondary_header_valid_o => (others => '0')
    );
    
    oid_generator_inst: oid_generator
    port map(
        clk_i => clk_i,
        reset_i => reset_i,
        enable_i => oid_generator_enable_s,  
        data_o => oid_generator_data_s,
        data_valid_o => oid_generator_data_valid_s     
    );
    
    fecf_encoder_inst: fecf_encoder
    port map(
        clk_i => clk_i,
        en_i => '0',
        reset_i => reset_i,
        data_i => (others => '0'),
        fecf_o => fecf_data_s     
    );
    
    
    oid_vch_config_r <= (
        has_ocf => '0',
        ocf_data => (others => '0'),
        has_fecf => '0',
        has_secondary_header => '0',
        first_header_pointer => (others => '0'),
        virtual_channel_frame_count => (others => '0'),
        master_channel_frame_count_trigger => '0',
        transfer_frame_version_number => (others => '0'),
        spacecraft_id => GENERIC_SPACECRAFT_ID,
        virtual_channel_id => (others => '0'),
        secondary_header_data => (others => '0'),
        secondary_header_valid => '0',
        secondary_header_last_byte => '0'
    );
    
    
    with selected_vch_r select
        is_oid_frame_s <= '1' when OID_VCH,
                          '0' when others;
    
    any_vch_available_s <= vch0_frame_ready_i or vch1_frame_ready_i;
    encoder_ready_o <= m_axis_tready and current_vch_ready_r;
    m_axis_tvalid <= internal_valid_s;
    
    
    m_axis_tlast <= internal_tlast_s;
    
    with selected_vch_r select
        current_vch_config_r <= vch0_encoder_config_i when VCH0,
                                vch1_encoder_config_i when VCH1,
                                oid_vch_config_r when others;                          

    with selected_vch_r select
        current_vch_data_r <= vch0_data_i when VCH0,
                              vch1_data_i when VCH1,
                              oid_generator_data_s when others;
    
    with selected_vch_r select
        current_vch_end_of_frame_r <= vch0_end_of_frame_i when VCH0,
                                      vch1_end_of_frame_i when VCH1,
                                      oid_end_of_frame_r when OID_VCH,
                                      '0' when others;
    
    with selected_vch_r select
        virtual_channel_select_o <= vch0_encoder_config_i.virtual_channel_id when VCH0,
                                    vch1_encoder_config_i.virtual_channel_id when VCH1,
                                    (others => '0') when others; 
    
    with selected_vch_r select
        current_vch_valid_r <= oid_generator_data_valid_s when OID_VCH,
                               '1' when others;
    
    with selected_vch_r select
        oid_generator_enable_s <= current_vch_ready_r when OID_VCH,
                                  '0' when others; 
        
    tlast_delay: process(clk_i)
    begin
        if rising_edge(clk_i) then
            
        end if;
        
    end process tlast_delay;
    
    main_state_machine: process(clk_i)
    begin
        if reset_i = '0' then  
            current_vch_ready_r <= '0';
            state_r <= RESET;
            master_channel_frame_count_r <= (others => '0');
            m_axis_tdata <= (others => '0');

            internal_valid_s <= '0';
            
        else
            if rising_edge(clk_i) then
                if (state_r = RESET) then
                    
                    state_r <= PRIMARY_HEADER;
                    master_channel_frame_count_r <= (others => '0');
                    selected_vch_r <= OID_VCH;
                    oid_primed_used_s <= '0';
                    internal_tlast_s <= '0';
       
                elsif (state_r = PRIMARY_HEADER) and m_axis_tready = '1' then
                    if internal_tlast_s = '1' then
                        internal_tlast_s <= '0';
                    end if;
                
                    internal_valid_s <= '1'; -- This sets valid once
                
                    m_axis_tdata <= header_data_r(7 + (primary_header_ptr_r * 8) downto 0 + (primary_header_ptr_r * 8));
                    primary_header_ptr_r <= primary_header_ptr_r + 1;
                    
                    if (primary_header_ptr_r = PRIMARY_HEADER_LENGTH -1) then
                        if current_vch_config_r.has_secondary_header = '1' then
                            state_r <= SECONDARY_HEADER;
                        else
                            state_r <= PAYLOAD;
                            current_vch_ready_r <= '1';
                        end if;
                        
                        primary_header_ptr_r <= 0;
                    end if;            
                
                elsif (state_r = SECONDARY_HEADER) then
                
                elsif (state_r = PAYLOAD) then
                    if (selected_vch_r = OID_VCH and current_vch_valid_r = '1') or selected_vch_r /= OID_VCH or (oid_primed_s = '1' and oid_primed_used_s = '0' and selected_vch_r = OID_VCH) then
                        
                        if oid_primed_s = '1' and oid_primed_used_s = '0' and selected_vch_r = OID_VCH then
                            oid_primed_used_s <= '1';
                        end if; 
                        
                        m_axis_tdata <= current_vch_data_r;
                        internal_valid_s <= '1';
                    else
                        internal_valid_s <= '0';
                    end if; 
                    
                    if oid_primed_used_s = '1' and oid_primed_s = '0' then
                        oid_primed_used_s <= '0';
                    end if;  
                    
                    if current_vch_end_of_frame_r = '1' then
                        current_vch_ready_r <= '0';
                        
                    
                        if current_vch_config_r.has_ocf = '1' then
                            state_r <= OCF;
                        elsif current_vch_config_r.has_fecf = '1' then
                            state_r <= FECF;
                        else
                            selected_vch_r <= f_select_next_vch(
                                not any_vch_available_s,
                                vch0_frame_ready_i,
                                vch1_frame_ready_i
                            );
                            state_r <= PRIMARY_HEADER;
                            internal_tlast_s <= '1';
                        end if;
                    else
                        current_vch_ready_r <= '1';             
                    end if;
                elsif (state_r = OCF) then
                
                elsif (state_r = FECF) then
                
                end if;
            end if;  
        end if;
    end process main_state_machine;
    
    oid_end_flag_generator: process(oid_generator_data_valid_s)
    begin
        if reset_i = '0' then
            oid_length_counter_r <= 0;
            oid_end_of_frame_r <= '0';
        else
            if rising_edge(oid_generator_data_valid_s) then
                if (selected_vch_r = OID_VCH and oid_end_of_frame_r = '0' and oid_generator_data_valid_s = '1') or (oid_primed_s = '1' and oid_primed_used_s = '1') then
                    oid_length_counter_r <= oid_length_counter_r + 1;
                    
                    if oid_length_counter_r = OID_PACKET_LENGTH -1 then
                        oid_length_counter_r <= 0;
                        oid_end_of_frame_r <= '1';  
                    end if;
                elsif oid_end_of_frame_r = '1' then
                    oid_end_of_frame_r <= '0';
                    oid_primed_s <= '1';
                end if;
                
                if oid_primed_s = '1' and oid_primed_used_s = '1' then
                    oid_primed_s <= '0'; 
                end if;
                
            end if;
        end if; 
        
    end process oid_end_flag_generator;

end architecture behavioral;
