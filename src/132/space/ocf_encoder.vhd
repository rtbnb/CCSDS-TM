----------------------------------------------------------------
-- File : ocf_encoder.vhd
-- Created : 26.05.2026
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 O OPERATIONAL CONTROL FIELD Encoder
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ocf_encoder is
	Port(
        ocf_type_i: in std_logic;    
        sdls_fsr_report_i: in std_logic;
        project_specific_report_i: in std_logic;
        
        encoded_ocf_o: out std_logic_vector(31 downto 0);
        ocf_valid_o: out std_logic
        
	);
end entity ocf_encoder;

architecture behavioral of ocf_encoder is
begin
    -- When encoded_ocf_o(0) is 0 -> Type One Report in Accordance with CCSDS 232
    -- When encoded_ocf_o(0) is 1 -> Type Two Report
        -- When encoded_ocf_o(0) = 1 and encoded_ocf_o(1) = 0 -> Project Specific Content inside OCF
        -- When encoded_ocf_o(0) = 1 and encoded_ocf_o(1) = 1 -> SDLS FSR Report in Accordance with CCSDS 355.1
    
    encoded_ocf_o(0) <= ocf_type_i;
    
    encoded_ocf_o(1) <= (sdls_fsr_report_i xor project_specific_report_i) and not project_specific_report_i;
    encoded_ocf_o(31 downto 2) <= (others => '0');
    
    ocf_valid_o <= 
        not (sdls_fsr_report_i and  project_specific_report_i) and 
        not (not ocf_type_i and sdls_fsr_report_i) and
        not (not ocf_type_i and project_specific_report_i) and
        not (ocf_type_i and not (sdls_fsr_report_i or project_specific_report_i));
    
    
end architecture behavioral;
