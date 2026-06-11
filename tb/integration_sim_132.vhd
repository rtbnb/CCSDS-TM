----------------------------------------------------------------
-- File : integration_sim_132.vhd
-- Created : 07.05.2026
-- Author : Robin Eilers, Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : Testbench for the integration of 132 encoder > synch fifo > 132 decoder
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity integration_sim_132 is

end entity integration_sim_132;

architecture behavioral of integration_sim_132 is
    component top_level_132 is
        port (
            -- outputs
            ready_o: out std_logic := '0';
            tm_data_field_valid_vc1_o: out std_logic := '0';
            tm_data_field_vc1_o: out std_logic_vector(31 downto 0) := (others => '0');
            vc1_m_axi_tvalid: out std_logic := '0'; 
            vc1_m_axi_tready: in std_logic;
            vc1_m_axi_tdata: out std_logic_vector(31 downto 0) := x"00000000";
            vc1_m_axi_tlast: out std_logic := '0';

            -- inputs
            clk_i: in std_logic;
            reset_i: in std_logic;
            ground_clk_i: in std_logic;

            -- vch0 inputs
            vch0_s_axis_tdata        : in std_logic_vector(7 downto 0);
            vch0_s_axis_tvalid       : in std_logic;
            vch0_s_axis_tready       : out std_logic;

            -- vch1 inputs
            vch1_s_axis_tdata        : in std_logic_vector(7 downto 0);
            vch1_s_axis_tvalid       : in std_logic;
            vch1_s_axis_tready       : out std_logic
        );
    end component top_level_132;

    signal vc1_m_axi_tvalid_s: std_logic := '0';
    signal vc1_m_axi_tready_s: std_logic := '1';
    signal vc1_m_axi_tdata_s: std_logic_vector(31 downto 0) := x"00000000";
    signal vc1_m_axi_tlast_s: std_logic := '0';
    
    constant GND_CLK_PERIOD : time := 10 ns;
    constant CLK_PERIOD : time := 500 ns;

    signal clk_s: std_logic := '0';
    signal reset_s: std_logic := '0';

    -- test signals
    signal test_vch0_input_data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal test_vch0_input_valid_s: std_logic := '0';
    signal test_vch0_input_ready_s: std_logic;
    
    signal test_vch1_input_data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal test_vch1_input_valid_s: std_logic := '0';
    signal test_vch1_input_ready_s: std_logic;        

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
    DBF: top_level_132 port map (
        vc1_m_axi_tvalid => vc1_m_axi_tvalid_s, 
        vc1_m_axi_tready => vc1_m_axi_tready_s,
        vc1_m_axi_tdata => vc1_m_axi_tdata_s,
        vc1_m_axi_tlast => vc1_m_axi_tlast_s,
        clk_i => clk_s,
        ground_clk_i => ground_clk_s,
        reset_i => reset_s,
        vch0_s_axis_tdata => test_vch0_input_data_s,
        vch0_s_axis_tvalid => test_vch0_input_valid_s,
        vch0_s_axis_tready => test_vch0_input_ready_s,
        vch1_s_axis_tdata => test_vch1_input_data_s,
        vch1_s_axis_tvalid => test_vch1_input_valid_s,
        vch1_s_axis_tready => test_vch1_input_ready_s
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
        if test_vch0_input_ready_s = '1' then
            case test_data_state is
                when max_size_space_packet =>
                    test_vch0_input_data_s <= max_size_space_packet_s(wr_ptr);
                    test_vch0_input_valid_s <= '1';
                    wr_ptr <= wr_ptr + 1;
                    if wr_ptr = MAX_SPACE_PACKET_SIZE_OCTET - 1 then
                        wr_ptr <= 0;
                        test_data_state <= max_size_idle_space_packet;
                    end if;
                when max_size_idle_space_packet =>
                    test_vch0_input_data_s <= max_size_idle_space_packet_s(wr_ptr);
                    test_vch0_input_valid_s <= '1';
                    wr_ptr <= wr_ptr + 1;
                    if wr_ptr = MAX_SPACE_PACKET_SIZE_OCTET - 1 then
                        wr_ptr <= 0;
                        test_data_state <= max_size_space_packet;
                    end if;
            end case;
        else
            test_vch0_input_valid_s <= '0';
        end if;    
        wait for 2 * CLK_PERIOD;
    end process data_input;

    --validate_output: process is
    --begin
    --    wait for GND_CLK_PERIOD;
    --    case validate_data_state is
    --        when max_size_space_packet =>
    --            if vc1_m_axi_tvalid_s = '1' then
    --                assert (vc1_m_axi_tdata_s(7 downto 0) = max_size_space_packet_s((test_data_ptr + 0) mod MAX_SPACE_PACKET_SIZE_OCTET))
    --                report "output not matching input Space Packet index 0" severity failure;
    --                assert (vc1_m_axi_tdata_s(15 downto 8) = max_size_space_packet_s((test_data_ptr + 1) mod MAX_SPACE_PACKET_SIZE_OCTET))
    --                report "output not matching input Space Packet index 1" severity failure;
    --                assert (vc1_m_axi_tdata_s(23 downto 16) = max_size_space_packet_s((test_data_ptr + 2) mod MAX_SPACE_PACKET_SIZE_OCTET))
    --                report "output not matching input Space Packet index 2" severity failure;
    --                assert (vc1_m_axi_tdata_s(31 downto 24) = max_size_space_packet_s((test_data_ptr + 3) mod MAX_SPACE_PACKET_SIZE_OCTET))
    --                report "output not matching input Space Packet index 3" severity failure;
    --                test_data_ptr <= (test_data_ptr + 4) mod MAX_SPACE_PACKET_SIZE_OCTET;
    --            end if;
    --        when others =>
    --            validate_data_state <= max_size_space_packet;
    --    end case;
    --    wait for GND_CLK_PERIOD;
    --end process validate_output;
end architecture behavioral;
