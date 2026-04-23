----------------------------------------------------------------
-- File : data_decoder_sim.vhd
-- Created : 23.04.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Data Decoder Simulation File
----------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity data_decoder_sim is
end data_decoder_sim;

architecture Behavioral of data_decoder_sim is
component data_decoder is
    generic (
        tm_frame_data_size_octet_g: integer := 2040
    );

	port(
        -- outputs
        data_o: out std_logic_vector(31 downto 0); -- to axi stream entity
        data_valid_o: out std_logic := '0';
        data_fully_read_o: out std_logic := '0';

        -- inputs
        data_i: in std_logic_vector(7 downto 0);
        clk_i: in std_logic; -- "8 Bit" x4 clock
        data_valid_i: in std_logic := '0'
	);
end component data_decoder;
-- component header_decoder is
--     port(
--         header_data_i: in std_logic_vector(47 downto 0);
--         is_oid_flag_o: out std_logic;
--         transfer_frame_version_number_o: out std_logic_vector(1 downto 0);
--         spacecraft_id_o: out std_logic_vector(9 downto 0);
--         virtual_channel_id_o: out std_logic_vector(2 downto 0);
--         ocf_flag_o: out std_logic;
--         master_channel_frame_count_o: out std_logic_vector(7 downto 0);
--         virtual_channel_frame_count_o: out std_logic_vector(7 downto 0);
--         transfer_frame_secondary_header_flag_o: out std_logic;
--         snych_flag_o: out std_logic;
--         packet_order_flag_o: out std_logic;
--         segment_length_id_o: out std_logic_vector(1 downto 0);
--         first_header_pointer_o: out std_logic_vector(10 downto 0);
--     );
-- end component header_decoder;
    signal data_o_s: std_logic_vector(31 downto 0) := (others => '0');
    signal data_valid_o_s: std_logic := '0';
    signal data_fully_read_s: std_logic := '0';
    signal data_i_s: std_logic_vector(7 downto 0) := (others => '0');
    signal clk_s: std_logic := '0';
    signal data_valid_i_s: std_logic := '0';

    -- signal header_data_s: std_logic_vector(47 downto 0) := (others => '0');
    -- signal first_header_pointer_s: std_logic_vector(10 downto 0) := (others => '0');
begin

EUT: data_decoder port map (
    data_o => data_o_s,
    data_valid_o => data_valid_o_s,
    data_fully_read_o => data_fully_read_s,
    data_i => data_i_s,
    clk_i => clk_s,
    data_valid_i => data_valid_i_s
);

-- HD: header_decoder port map (
--     header_data_i => header_data_s;
--     first_header_pointer_o => first_header_pointer_s;
-- );

clk: process is
begin
    clk_s <= '0';
    wait for 5ns;
    clk_s <= '1';
    wait for 5ns;
end process clk;

data: process is
begin
    data_i_s <= x"FF";
    wait for 10ns;
    data_i_s <= x"00";
    wait for 10ns;
    data_i_s <= x"FF";
    wait for 10ns;
    data_i_s <= x"00";
    wait for 10ns;
    data_i_s <= x"00";
    wait for 10ns;
    data_i_s <= x"03";
    wait for 10ns;
    data_i_s <= x"01";
    wait for 10ns;
    data_i_s <= x"02";
    wait for 10ns;
    data_i_s <= x"03";
    wait for 10ns;
    data_i_s <= x"FF";
    wait for 10ns;
end process data;


end Behavioral;
