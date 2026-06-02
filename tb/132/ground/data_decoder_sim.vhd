----------------------------------------------------------------
-- File : data_decoder_sim.vhd
-- Created : 23.04.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Data Decoder Simulation File
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

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
        rdy_o: out std_logic := '1';

        -- inputs
        data_i: in std_logic_vector(7 downto 0);
        clk_i: in std_logic; -- "8 Bit" x4 clock
        data_valid_i: in std_logic := '0';
        tm_frame_first_header_pointer_i: in std_logic_vector(10 downto 0) := (others => '0');
        reset_i: in std_logic
	);
end component data_decoder;

    constant MAX_SPACE_PACKET_SIZE_OCTET: integer := 256;
    constant CLK_PERIOD: time := 5 ns;

    signal rdy_s: std_logic;
    signal data_o_s: std_logic_vector(31 downto 0) := (others => '0');
    signal data_valid_o_s: std_logic := '0';
    signal data_fully_read_s: std_logic := '0';
    signal data_i_s: std_logic_vector(7 downto 0) := (others => '0');
    signal clk_s: std_logic := '0';
    signal data_valid_i_s: std_logic := '0';
    signal tm_frame_first_header_pointer_s: std_logic_vector(10 downto 0) := (others => '0');
    signal reset_s: std_logic := '1';

    type space_packet_t is array (MAX_SPACE_PACKET_SIZE_OCTET - 1 downto 0) of std_logic_vector(7 downto 0);
    signal max_size_space_packet_s: space_packet_t := (others => (others => '0'));
    signal max_size_idle_space_packet_s: space_packet_t := (others => (others => '0'));

    -- data input process
    signal wr_ptr: integer := 0;
    
    -- validation process
    signal test_data_ptr: integer := 0;
    type test_data_state_t is (max_size_space_packet, max_size_idle_space_packet);
    signal test_data_state: test_data_state_t := max_size_space_packet;
    signal validate_data_state: test_data_state_t := max_size_space_packet;
begin

EUT: data_decoder port map (
    rdy_o => rdy_s,
    data_o => data_o_s,
    data_valid_o => data_valid_o_s,
    data_fully_read_o => data_fully_read_s,
    data_i => data_i_s,
    clk_i => clk_s,
    data_valid_i => data_valid_i_s,
    tm_frame_first_header_pointer_i => tm_frame_first_header_pointer_s,
    reset_i => reset_s
);

clk: process is
begin
    clk_s <= not clk_s;
    wait for CLK_PERIOD;
end process clk;


    max_size_space_packet_s(0) <= "00010000";
    max_size_space_packet_s(1) <= x"00";
    max_size_space_packet_s(2) <= x"00";
    max_size_space_packet_s(3) <= x"00";
    max_size_space_packet_s(4) <= x"f9"; -- 249 Data Octets
    max_size_space_packet_s(MAX_SPACE_PACKET_SIZE_OCTET - 1 downto 5) <= (others => x"00");

    max_size_idle_space_packet_s(0) <= "11110000";
    max_size_idle_space_packet_s(1) <= x"FF";
    max_size_idle_space_packet_s(2) <= x"00";
    max_size_idle_space_packet_s(3) <= x"00";
    max_size_idle_space_packet_s(4) <= x"f9"; -- 249 Data Octets
    max_size_idle_space_packet_s(MAX_SPACE_PACKET_SIZE_OCTET - 1 downto 5) <= (others => x"00");


data_input: process is
begin
    wait for CLK_PERIOD;
    if rdy_s = '1' then
        case test_data_state is
            when max_size_space_packet =>
                data_i_s <= max_size_space_packet_s(wr_ptr);
                data_valid_i_s <= '1';
                wr_ptr <= wr_ptr + 1;
                if wr_ptr = MAX_SPACE_PACKET_SIZE_OCTET - 1 then
                    wr_ptr <= 0;
                    test_data_state <= max_size_idle_space_packet;
                end if;
            when max_size_idle_space_packet =>
                data_i_s <= max_size_idle_space_packet_s(wr_ptr);
                data_valid_i_s <= '1';
                wr_ptr <= wr_ptr + 1;
                if wr_ptr = MAX_SPACE_PACKET_SIZE_OCTET - 1 then
                    wr_ptr <= 0;
                    test_data_state <= max_size_space_packet;
                end if;
        end case;
    else
        data_valid_i_s <= '0';
    end if;    
    wait for CLK_PERIOD;
end process data_input;

validate_output: process is
begin
    wait for CLK_PERIOD;
    case validate_data_state is
        when max_size_space_packet =>
            if data_valid_o_s = '1' then
                assert (data_o_s(7 downto 0) = max_size_space_packet_s(test_data_ptr + 0))
                report "output not matching input Space Packet index 0" severity failure;
                assert (data_o_s(15 downto 8) = max_size_space_packet_s(test_data_ptr + 1))
                report "output not matching input Space Packet index 1" severity failure;
                assert (data_o_s(23 downto 16) = max_size_space_packet_s(test_data_ptr + 2))
                report "output not matching input Space Packet index 2" severity failure;
                assert (data_o_s(31 downto 24) = max_size_space_packet_s(test_data_ptr + 3))
                report "output not matching input Space Packet index 3" severity failure;
                test_data_ptr <= test_data_ptr + 4;
                if test_data_ptr = MAX_SPACE_PACKET_SIZE_OCTET - 4 then
                    test_data_ptr <= 0;
                    validate_data_state <= max_size_space_packet;
                end if;
            end if;
        when others =>
            validate_data_state <= max_size_space_packet;
    end case;
    wait for CLK_PERIOD;
end process validate_output;


end Behavioral;
