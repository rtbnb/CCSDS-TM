----------------------------------------------------------------
-- File : transfer_frame_encoder.vhd
-- Created : 23.04.2026
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Transfer Frame Encoder
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity transfer_frame_encoder is
	Port(
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
        vch0_data_en_o: out std_logic := '0';
        vch0_data_i: in std_logic_vector(7 downto 0);
        vch0_virtual_channel_frame_count_i: in std_logic_vector(7 downto 0)
	   
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
            secondary_header_data_field_width_octets_g : integer := 63 -- maximum length of this parameter is 63 according to CCSDS-132.0-B-3 4.1.3.1.6
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

    constant PRIMARY_HEADER_LENGTH: integer := 6;
    
    type state_machine_t IS (INITIAL, PRIMARY_HEADER, SECONDARY_HEADER, PAYLOAD, TRAILOR);
    signal state_r: state_machine_t := INITIAL;
    
    signal vch_available_s: std_logic := '0';
    signal virtual_channel_id_r: std_logic_vector(2 downto 0) := (others => '0');
    signal virtual_channel_frame_count_r: std_logic_vector(7 downto 0) := (others => '0');
    signal master_channel_frame_count_r: std_logic_vector(7 downto 0) := (others => '0');
    signal first_header_pointer_s: std_logic_vector(10 downto 0) := (others => '0');
    signal is_oid_frame_r: std_logic := '0';
    
    signal header_data_r: std_logic_vector(47 downto 0);
    signal primary_header_ptr_r: integer range 0 to PRIMARY_HEADER_LENGTH -1 := 0;
    
    signal testCounter_r: std_logic_vector(7 downto 0) := (others => '0');
    constant OID_PACKET_LENGTH: integer := 2040;
    signal oid_length_counter_r: integer range 0 to OID_PACKET_LENGTH -1 := 0;
begin
    
    header_encoder_inst: header_encoder port map (
        transfer_frame_version_number_i => transfer_frame_version_number_i,
        spacecraft_id_i => spacecraft_id_i,
        virtual_channel_id_i => virtual_channel_id_r,
        ocf_flag_i => '0',
        master_channel_frame_count_i => master_channel_frame_count_r,
        virtual_channel_frame_count_i => virtual_channel_frame_count_r,
        transfer_frame_secondary_header_flag_i => '0',
        snych_flag_i => '0',
        packet_order_flag_i => '0',
        segment_length_id_i => "11",
        first_header_pointer_i => first_header_pointer_s,
        is_oid_flag_i => is_oid_frame_r,
        header_data_o => header_data_r
    );
    
    secondary_header_encoder_inst: secondary_header_encoder
    generic map(
        secondary_header_data_field_width_octets_g => 63
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
    
    vch_available_s <= vch0_frame_ready_i;
    out_clk_o <= clk_i;
    with is_oid_frame_r select
        first_header_pointer_s <= "11111111110" when '1',
                                  (others => '0') when others;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            testCounter_r <= std_logic_vector((unsigned(testCounter_r) +1)); 
        end if;
    end process;
    
    process(clk_i)
    begin
        
        if falling_edge(clk_i) then
                   
            if (state_r = INITIAL) then
                virtual_channel_id_r <= "000";
                is_oid_frame_r <= '1';
                state_r <= PRIMARY_HEADER;
            elsif (state_r = PAYLOAD) and out_full_i = '0' then
                
                if is_oid_frame_r = '1' then
                    oid_length_counter_r <= oid_length_counter_r + 1;
                    data_o <= testCounter_r;
                else
                    data_o <= vch0_data_i;
                end if;
                
                -- this only gets triggert when the frame is ending
                if (is_oid_frame_r = '1' and oid_length_counter_r = OID_PACKET_LENGTH -1) or (is_oid_frame_r = '0' and vch0_frame_ready_i = '0') then
                    is_oid_frame_r <= not vch_available_s;        
                    master_channel_frame_count_r <= std_logic_vector(unsigned(master_channel_frame_count_r) + 1);
                    state_r <= PRIMARY_HEADER;
                    vch0_data_en_o <= '0';
                    
                end if;
             
            elsif (state_r = PRIMARY_HEADER) and out_full_i = '0' then
                out_en_o <= '1'; -- This needs only to be set once
            
                data_o <= header_data_r(7 + (primary_header_ptr_r * 8) downto 0 + (primary_header_ptr_r * 8));
                primary_header_ptr_r <= primary_header_ptr_r + 1;
                if (primary_header_ptr_r = PRIMARY_HEADER_LENGTH -1) then
                    state_r <= PAYLOAD;
                    primary_header_ptr_r <= 0;
                    
                    if is_oid_frame_r = '1' then
                        vch0_data_en_o <= '0';
                    else
                        vch0_data_en_o <= '1';    
                    end if;
                end if;
            end if;
        end if;
        
    end process;

end architecture behavioral;
