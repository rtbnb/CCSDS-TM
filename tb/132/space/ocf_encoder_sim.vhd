----------------------------------------------------------------
-- File : ocf_encoder_sim.vhd
-- Created : 26.11.2025
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : Simulation for the OCF Encoder
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ocf_encoder_sim is
end ocf_encoder_sim;

architecture Behavioral of ocf_encoder_sim is
component ocf_encoder is
	Port(
        ocf_type_i: in std_logic;
        sdls_fsr_report_i: in std_logic;
        project_specific_report_i: in std_logic;

        encoded_ocf_o: out std_logic_vector(31 downto 0);
        ocf_valid_o: out std_logic
	);
end component ocf_encoder;

    signal ocf_type_s: std_logic := '0';
    signal sdls_fsr_report_s: std_logic := '0';
    signal project_specific_report_s: std_logic := '0';
    signal encoded_ocf_s: std_logic_vector(31 downto 0);
    signal ocf_valid_s: std_logic;

begin

EUT: ocf_encoder port map (
    ocf_type_i => ocf_type_s,
    sdls_fsr_report_i => sdls_fsr_report_s,
    project_specific_report_i => project_specific_report_s,
    encoded_ocf_o => encoded_ocf_s,
    ocf_valid_o => ocf_valid_s
);

process is
begin

    ocf_type_s <= '0';

    wait for 10ns;
    assert ocf_valid_s = '1' severity failure;

    project_specific_report_s <= '1';

    wait for 10ns;
    assert ocf_valid_s = '0' severity failure;

    project_specific_report_s <= '0';
    sdls_fsr_report_s <= '1';

    wait for 10ns;
    assert ocf_valid_s = '0' severity failure;

    sdls_fsr_report_s <= '0';
    ocf_type_s <= '1';

    wait for 10ns;
    assert ocf_valid_s = '0' severity failure;

    project_specific_report_s <= '1';

    wait for 10ns;
    assert ocf_valid_s = '1' severity failure;

    sdls_fsr_report_s <= '1';

    wait for 10ns;
    assert ocf_valid_s = '0' severity failure;

    project_specific_report_s <= '0';

    wait for 10ns;
    assert ocf_valid_s = '1' severity failure;

    wait;
end process;


end Behavioral;
