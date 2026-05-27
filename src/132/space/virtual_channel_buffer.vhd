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

entity virtual_channel_buffer is
	Port(
        clk_i: in std_logic;
        reset_i: in std_logic;
    
        -- input interface
        data_i: in std_logic_vector(7 downto 0);
        data_valid_i: in std_logic;
        ready_o: out std_logic;

        -- output interface
        frame_ready_o: out std_logic;
        data_out_en_i: in std_logic;
        data_o: out std_logic_vector(7 downto 0) := (others => '0');
        virtual_channel_frame_count_o: out std_logic_vector(7 downto 0);
        first_header_pointer: out std_logic_vector(10 downto 0)
	);
end entity virtual_channel_buffer;

architecture behavioral of virtual_channel_buffer is
    constant BUFFER_SIZE: integer := 2040; -- 2040 bytes maximum TRANSFER FRAME DATA FIELD (ref CCSDS 132.0-B-3 Figure 4.1) and SPC-REQ-7
    constant SPACE_PACKET_PRIMARY_HEADER_SIZE: integer := 6; -- size of space packet header based on the CCSDS 133 specification
    constant SPACE_PACKET_MAX_DATA_SIZE: integer := 256; -- The maximum defined size of the space package data field as defined by SeeSat
    constant SPACE_PACKET_MAX_SIZE: integer := SPACE_PACKET_PRIMARY_HEADER_SIZE + SPACE_PACKET_MAX_DATA_SIZE;
    
    type buffer_mem_t is array (0 to BUFFER_SIZE -1) of std_logic_vector(7 downto 0);
    type space_package_mem_t is array (0 to SPACE_PACKET_MAX_SIZE -1) of std_logic_vector(7 downto 0);
    
    signal data_buffer_r : buffer_mem_t := (others => (others => '0'));
    signal space_packet_buffer_r: space_package_mem_t := (others => (others => '0'));

    type space_package_decoding_state_machine_t IS (RESET, WRITE, INSPECT, READ);
    signal space_packet_decoding_state_r: space_package_decoding_state_machine_t := RESET; 
    
    signal space_packet_write_ptr_r: integer range 0 to SPACE_PACKET_MAX_DATA_SIZE -1 := 0;
    signal space_packet_read_ptr_r: integer range 0 to SPACE_PACKET_MAX_DATA_SIZE -1 := 0;
    signal remaining_octets_in_space_package_r: integer range 0 to SPACE_PACKET_MAX_DATA_SIZE -1 := 0;
    signal space_packet_data_length: integer range 0 to SPACE_PACKET_MAX_DATA_SIZE -1 := 0;
    
    signal write_ptr_r: integer range 0 to BUFFER_SIZE -1 := 0;
    signal read_ptr_r: integer range 0 to BUFFER_SIZE -1 := 0;
    
    signal pre_loading_active_r: std_logic := '0';
    
    signal readout_active_r: std_logic := '0';

begin
    
    ready_o <= (not readout_active_r) or pre_loading_active_r;
    frame_ready_o <= readout_active_r;
    
    -- preloading is extracted into its own process that reacts on the falling edge to make interaction with this entity more predictable
    preload_switch: process(clk_i)
    begin
        if falling_edge(clk_i) then
            if ((read_ptr_r - write_ptr_r) > 1 and readout_active_r = '1') then
                pre_loading_active_r <= '1';
            else
                pre_loading_active_r <= '0';
            end if;
        end if;
        
    end process preload_switch;
    
    space_package_ingestion: process(clk_i)
    begin
        if rising_edge(clk_i) and reset_i = '1' then
            if space_packet_decoding_state_r = RESET then
                space_packet_write_ptr_r <= 0;
                space_packet_read_ptr_r <= 0;
                remaining_octets_in_space_package_r <= 0; 
                
            
            elsif space_packet_decoding_state_r = WRITE and data_valid_i = '1' then
                
                space_packet_buffer_r(space_packet_write_ptr_r) <= data_i;    
                space_packet_write_ptr_r <= space_packet_write_ptr_r + 1;
                
                if space_packet_write_ptr_r = SPACE_PACKET_PRIMARY_HEADER_SIZE then
                
                end if;
                
                if space_packet_write_ptr_r = SPACE_PACKET_MAX_DATA_SIZE -1 then
                    space_packet_write_ptr_r <= 0;
                    space_packet_decoding_state_r <= INSPECT; 
                end if;
                
            elsif space_packet_decoding_state_r = INSPECT then            
                
                
            elsif space_packet_decoding_state_r = READ then
                
            
            
            end if;
        elsif reset_i = '0' then
            space_packet_write_ptr_r <= 0;
            space_packet_read_ptr_r <= 0;
            remaining_octets_in_space_package_r <= 0;         
            space_packet_decoding_state_r <= RESET;
        end if;
        
        
        
    end process space_package_ingestion;
    
    
    data_handling: process(clk_i) 
    begin
        if rising_edge(clk_i) then
            if (readout_active_r = '0' and data_valid_i = '1') or (pre_loading_active_r = '1' and (read_ptr_r - write_ptr_r) > 1) then
                
                data_buffer_r(write_ptr_r) <= data_i;
                write_ptr_r <= write_ptr_r + 1;

                if (write_ptr_r = BUFFER_SIZE -1) then
                    write_ptr_r <= 0;
                    readout_active_r <= '1';
                end if;
                
            end if;

            if (readout_active_r = '1' and data_out_en_i = '1') then
                read_ptr_r <= read_ptr_r + 1; 
                data_o <= data_buffer_r(read_ptr_r);
                
                if (read_ptr_r = BUFFER_SIZE -1) then
                    read_ptr_r <= 0;
                    readout_active_r <= '0';
                end if;

            end if;

        end if;


    end process data_handling;


end architecture behavioral;
