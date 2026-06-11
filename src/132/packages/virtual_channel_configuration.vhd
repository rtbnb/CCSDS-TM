----------------------------------------------------------------
-- File : virtual_channel_configuration.vhd
-- Created : 10.06.2026
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : Custom Package for better interfacing between the virtual channel and the transfer frame encoder
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package virtual_channel_configuration is

    type virtual_channel_configuration_t is record
        has_ocf: std_logic;
        ocf_data: std_logic_vector(31 downto 0);
        has_fecf: std_logic;
        
        first_header_pointer: std_logic_vector(10 downto 0);
        
        virtual_channel_frame_count: std_logic_vector(7 downto 0);
        master_channel_frame_count_trigger: std_logic; 
        
        transfer_frame_version_number: std_logic_vector(1 downto 0);
        spacecraft_id: std_logic_vector(9 downto 0);
        virtual_channel_id: std_logic_vector(2 downto 0);
        
        has_secondary_header: std_logic;
        secondary_header_data: std_logic_vector(7 downto 0);
        secondary_header_valid: std_logic;
        secondary_header_last_byte: std_logic;
    end record virtual_channel_configuration_t;
    
end package virtual_channel_configuration;
 
package body virtual_channel_configuration is



end package body virtual_channel_configuration;