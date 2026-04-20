----------------------------------------------------------------
-- File : data_encoder.vhd
-- Created : 03.04.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Data Decoder
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_decoder is
    port (
        -- outputs
        data_o: out std_logic_vector(31 downto 0); -- to axi stream entity
        data_clk_o: out std_logic;
        date_fully_read_o: out std_logic;

        tf_prime_header_o: out std_logic_vector(47 downto 0);

        -- inputs
        data_i: in std_logic_vector(15 downto 0);
        data_clk_i: in std_logic
    );
end entity data_decoder;

architecture behavioral of data_decoder is
    -- TF prime header
    constant OUTPUT_DATA_SIZE: integer := 32;
    constant INPUT_DATA_SIZE: integer := 16;
    constant PRIME_HEADER_16_BIT_MULTIPLIES: integer := 3;
    component header_decoder is
        port (
            data_i: in std_logic_vector(47 downto 0);
            is_oid_flag_o: out std_logic;
            transfer_frame_version_number_o: out std_logic_vector(1 downto 0);
            spacecraft_id_o: out std_logic_vector(9 downto 0);
            virtual_channel_id_o: out std_logic_vector(2 downto 0);
            ocf_flag_o: out std_logic;
            master_channel_frame_count_o: out std_logic_vector(7 downto 0);
            virtual_channel_frame_count_o: out std_logic_vector(7 downto 0);
            transfer_frame_secondary_header_flag_o: out std_logic;
            snych_flag_o: out std_logic;
            packet_order_flag_o: out std_logic;
            segment_length_id_o: out std_logic_vector(1 downto 0);
            first_header_pointer_o: out std_logic_vector(10 downto 0)
        );
    end component header_decoder;
    
    signal mcid_s: std_logic_vector(11 downto 0);
    signal vcid_s: std_logic_vector(2 downto 0);
    signal ocf_flag_s: std_logic;
    signal master_channel_frame_count_s: std_logic_vector(7 downto 0);
    signal virtual_channel_frame_count_s: std_logic_vector(7 downto 0);
    signal secondary_header_flag_s: std_logic;
    signal synch_flag_s: std_logic;
    signal packet_order_flag_s: std_logic;
    signal segment_length_id_s: std_logic_vector(1 downto 0);
    signal first_header_pointer_s: std_logic_vector(10 downto 0);
    -- TF secondary header

    -- data
    signal prime_header_r: std_logic_vector(47 downto 0);
    signal data_r: std_logic_vector(255 downto 0); -- storage for one space packet
    signal input_data_counter_r: integer range 0 to 1022; -- 2046 octets of a frame can be split into 1023 16Bit values
    signal is_oid_flag_s: std_logic;
    
    
    type deserialization_state_t is (header, data);
    signal state_s: deserialization_state_t := header;
    signal data_field_size_s: integer;
    
begin
    hd: header_decoder port map(
        data_i => prime_header_r,
        is_oid_flag_o => is_oid_flag_s,
        transfer_frame_version_number_o => mcid_s(11 downto 10),
        spacecraft_id_o => mcid_s(9 downto 0),
        virtual_channel_id_o => vcid_s,
        ocf_flag_o => ocf_flag_s,
        master_channel_frame_count_o => master_channel_frame_count_s,
        virtual_channel_frame_count_o => virtual_channel_frame_count_s,
        transfer_frame_secondary_header_flag_o => secondary_header_flag_s,
        snych_flag_o => synch_flag_s,
        packet_order_flag_o => packet_order_flag_s,
        segment_length_id_o => segment_length_id_s,
        first_header_pointer_o => first_header_pointer_s
    );

    tf_prime_header_o <= prime_header_r;

    deserialization: process(data_clk_i)

    begin
        if rising_edge(data_clk_i) then
            case state_s is
                when header =>
                    prime_header_r(((input_data_counter_r + 1) * INPUT_DATA_SIZE) - 1 downto input_data_counter_r * INPUT_DATA_SIZE) <= data_i(((input_data_counter_r + 1) * INPUT_DATA_SIZE) - 1 downto input_data_counter_r * INPUT_DATA_SIZE);
                    input_data_counter_r <= input_data_counter_r + 1;
                    if (input_data_counter_r = PRIME_HEADER_16_BIT_MULTIPLIES - 1) then
                        state_s <= data;
                        input_data_counter_r <= 0;
                    end if;
                when data =>
                    
            end case;
        end if;

    end process deserialization;

end architecture behavioral;