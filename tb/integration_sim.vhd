----------------------------------------------------------------
-- File : integration_sim.vhd
-- Created : 07.05.2026
-- Author : Robin Eilers, Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : Testbench for the integration of 132 encoder > 131 encoder > 131 decoder > 132 decoder
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity integration_sim is

end entity integration_sim;

architecture behavioral of integration_sim is
    component system_integration_wrapper is
        port (
            ground_clk_i_1 : in std_logic;
            clk_i_0 : in std_logic;
            data_i_0 : in std_logic_vector ( 7 downto 0 );
            data_valid_i_0 : in std_logic;
            ready_o_0 : out std_logic;
            reset_i_0 : in std_logic;
            spacecraft_id_i_0 : in std_logic_vector ( 9 downto 0 );
            tm_data_field_vc1_o_0 : out std_logic_vector ( 31 downto 0 );
            tm_data_field_valid_vc1_o_0 : out std_logic;
            transfer_frame_version_number_i_0 : in std_logic_vector ( 1 downto 0 )   
        );
    end component system_integration_wrapper;

    signal tm_data_field_s: std_logic_vector(31 downto 0);
    signal tm_data_field_valid_s: std_logic;
    


    constant GND_CLK_PERIOD : time := 10 ns;
    constant CLK_PERIOD : time := 500 ns;

    signal clk_s: std_logic := '0';
    signal reset_s: std_logic := '0';

    signal transfer_frame_version_number_s: std_logic_vector(1 downto 0);
    signal spacecraft_id_s: std_logic_vector(9 downto 0);

    -- test signals
    signal test_input_data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal test_input_valid_s: std_logic := '0';
    signal test_input_ready_s: std_logic;
    
    -- ground
    signal ground_clk_s: std_logic := '0';

    -- automatic testbench
    constant WORDS_PER_FRAME: integer := 510;
    constant MAX_SPACE_PACKET_SIZE_OCTET: integer := 255;

    type space_packet_t is array (MAX_SPACE_PACKET_SIZE_OCTET - 1 downto 0) of std_logic_vector(7 downto 0);
    signal max_size_space_packet_s: space_packet_t := (others => (others => '0'));
    signal max_size_idle_space_packet_s: space_packet_t := (others => (others => '0'));
    
    signal output_word_counter_r: integer := 0;
    signal test_output_data_s: std_logic_vector(7 downto 0) := (others => '0');

    -- data input process
    signal wr_ptr: integer := 0;

    -- validation process
    signal test_data_ptr: integer := 0;
    type test_data_state_t is (max_size_space_packet, max_size_idle_space_packet);
    signal test_data_state: test_data_state_t := max_size_space_packet;
    signal validate_data_state: test_data_state_t := max_size_space_packet;

begin
    DBF: system_integration_wrapper port map (
        ground_clk_i_1 => ground_clk_s,
        data_i_0 => test_input_data_s,
        data_valid_i_0 => test_input_valid_s,
        clk_i_0 => clk_s,
        ready_o_0 => test_input_ready_s,
        reset_i_0 => reset_s,
        tm_data_field_vc1_o_0 => tm_data_field_s,
        tm_data_field_valid_vc1_o_0 => tm_data_field_valid_s,
        transfer_frame_version_number_i_0 => transfer_frame_version_number_s,
        spacecraft_id_i_0 => spacecraft_id_s
    );

    fill_packet: process begin
        max_size_space_packet_s(0) <= "00010000";
        max_size_space_packet_s(1) <= x"00";
        max_size_space_packet_s(2) <= x"00";
        max_size_space_packet_s(3) <= x"00";
        max_size_space_packet_s(4) <= x"f8"; -- 249 Data Octets
        max_size_space_packet_s(5) <= x"00";
        for i in 6 to MAX_SPACE_PACKET_SIZE_OCTET - 1 loop
            max_size_space_packet_s(i) <= std_logic_vector(to_unsigned(i, 8));
        end loop;
        wait;
    end process fill_packet;
    -- max_size_space_packet_s(MAX_SPACE_PACKET_SIZE_OCTET - 1 downto 5) <= (others => x"00");

    max_size_idle_space_packet_s(0) <= "11110000";
    max_size_idle_space_packet_s(1) <= x"FF";
    max_size_idle_space_packet_s(2) <= x"00";
    max_size_idle_space_packet_s(3) <= x"00";
    max_size_idle_space_packet_s(4) <= x"f8"; -- 249 Data Octets
    max_size_idle_space_packet_s(5) <= x"00";
    max_size_idle_space_packet_s(MAX_SPACE_PACKET_SIZE_OCTET - 1 downto 6) <= (others => x"00");

    
    general_settings: process begin
        reset_s <= '1';
        transfer_frame_version_number_s <= "00";
        spacecraft_id_s <= "0000000000";
        wait;
    end process general_settings;

    ground_clk: process begin
        ground_clk_s <= not ground_clk_s;
        wait for GND_CLK_PERIOD;
    end process ground_clk;

    clock: process begin
        clk_s <= not clk_s;
        wait for CLK_PERIOD;
    end process clock;

    data_input: process is
    begin
        --wait for CLK_PERIOD;
        if test_input_ready_s = '1' then
            case test_data_state is
                when max_size_space_packet =>
                    test_input_data_s <= max_size_space_packet_s(wr_ptr);
                    test_input_valid_s <= '1';
                    wr_ptr <= wr_ptr + 1;
                    if wr_ptr = MAX_SPACE_PACKET_SIZE_OCTET - 1 then
                        wr_ptr <= 0;
                        test_data_state <= max_size_idle_space_packet;
                    end if;
                when max_size_idle_space_packet =>
                    test_input_data_s <= max_size_idle_space_packet_s(wr_ptr);
                    test_input_valid_s <= '1';
                    wr_ptr <= wr_ptr + 1;
                    if wr_ptr = MAX_SPACE_PACKET_SIZE_OCTET - 1 then
                        wr_ptr <= 0;
                        test_data_state <= max_size_space_packet;
                    end if;
            end case;
        else
            test_input_valid_s <= '0';
        end if;    
        wait for 2 * CLK_PERIOD;
    end process data_input;

    validate_output: process is
    begin
        wait for GND_CLK_PERIOD;
        case validate_data_state is
            when max_size_space_packet =>
                if tm_data_field_valid_s = '1' then
                    assert (tm_data_field_s(7 downto 0) = max_size_space_packet_s((test_data_ptr + 0) mod MAX_SPACE_PACKET_SIZE_OCTET))
                    report "output not matching input Space Packet index 0" severity failure;
                    assert (tm_data_field_s(15 downto 8) = max_size_space_packet_s((test_data_ptr + 1) mod MAX_SPACE_PACKET_SIZE_OCTET))
                    report "output not matching input Space Packet index 1" severity failure;
                    assert (tm_data_field_s(23 downto 16) = max_size_space_packet_s((test_data_ptr + 2) mod MAX_SPACE_PACKET_SIZE_OCTET))
                    report "output not matching input Space Packet index 2" severity failure;
                    assert (tm_data_field_s(31 downto 24) = max_size_space_packet_s((test_data_ptr + 3) mod MAX_SPACE_PACKET_SIZE_OCTET))
                    report "output not matching input Space Packet index 3" severity failure;
                    test_data_ptr <= (test_data_ptr + 4) mod MAX_SPACE_PACKET_SIZE_OCTET;
                end if;
            when others =>
                validate_data_state <= max_size_space_packet;
        end case;
        wait for GND_CLK_PERIOD;
    end process validate_output;
end architecture behavioral;
