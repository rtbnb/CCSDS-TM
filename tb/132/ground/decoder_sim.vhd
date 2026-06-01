----------------------------------------------------------------
-- File : decoder_sim.vhd
-- Created : 24.04.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Top Ground Decoder Testbench
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder_sim is
end entity decoder_sim;

architecture behavioral of decoder_sim is
    component decoder_buffer_and_structure is
        generic (
            tm_frame_size_octet_g: integer := 2046
        );
        port (
            -- inputs
            data_i: std_logic_vector(7 downto 0);
            data_valid_i: std_logic;
            clk_i: std_logic;
            reset_i: std_logic;

            -- outputs
            tm_data_field_o: out std_logic_vector(31 downto 0);
            tm_data_field_valid_o: out std_logic
        );
    end component decoder_buffer_and_structure;

    constant MAX_SPACE_PACKET_SIZE_OCTET: integer := 256;
    constant REDUZED_SPACE_PACKET_SIZE_OCTET: integer := 248; -- to match tm frame data field size of 2040 octets with 8 full space packets of 256 octets and 1 last space packet of 248 octets
    constant CLK_PERIOD: time := 5 ns;

    signal data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal data_valid_s: std_logic := '0';
    signal clk_s: std_logic := '0';

    signal data_o_s: std_logic_vector(31 downto 0);
    signal data_valid_o_s: std_logic;
    signal data_fully_read_o_s: std_logic;
    signal tm_frame_first_header_pointer_s: std_logic_vector(10 downto 0) := (others => '0');
    signal reset_s: std_logic := '0';

    -- test data
    type space_packet_t is array (MAX_SPACE_PACKET_SIZE_OCTET - 1 downto 0) of std_logic_vector(7 downto 0);
    signal max_size_space_packet_s: space_packet_t := (others => (others => '0'));
    signal reduced_size_space_packet_s: space_packet_t := (others => (others => '0'));
    signal test_data_ptr: integer := 0;
    signal wr_ptr: integer := 0;
    signal output_octet_count_s: integer := 0;
    signal output_validate_done_s: boolean := false;
    signal expected_output_s: std_logic_vector(31 downto 0);
begin
    DBF: decoder_buffer_and_structure port map (
        tm_data_field_o => data_o_s,
        tm_data_field_valid_o => data_valid_o_s,
        data_i => data_s,
        clk_i => clk_s,
        data_valid_i => data_valid_s,
        reset_i => reset_s
    );

    -- test data generation
    max_size_space_packet_s(0) <= "00010000";
    max_size_space_packet_s(1) <= x"00";
    max_size_space_packet_s(2) <= x"00";
    max_size_space_packet_s(3) <= x"00";
    max_size_space_packet_s(4) <= x"f9"; -- 249 Data Octets
    max_size_space_packet_s(MAX_SPACE_PACKET_SIZE_OCTET - 1 downto 5) <= (others => x"00");

    reduced_size_space_packet_s(0) <= "00010000";
    reduced_size_space_packet_s(1) <= x"00";
    reduced_size_space_packet_s(2) <= x"00";
    reduced_size_space_packet_s(3) <= x"00";
    reduced_size_space_packet_s(4) <= x"f1"; -- 241 Data Octets
    reduced_size_space_packet_s(REDUZED_SPACE_PACKET_SIZE_OCTET - 1 downto 5) <= (others => x"00");

    clk: process
    begin
        clk_s <= not clk_s;
        wait for CLK_PERIOD;
    end process clk;

    data_input: process
    begin
        reset_s <= '1';
        wait for CLK_PERIOD;
        -- tf frame version number + spacraft id
        data_s <= "00000001";
        data_valid_s <= '1';
        wait for 2 * CLK_PERIOD;
        -- spacecraft id + vc id + ocf flag
        data_s <= "00000010";
        wait for 2 * CLK_PERIOD;
        -- master channel frame count
        data_s <= "00000011";
        wait for 2 * CLK_PERIOD;
        -- virtual channel frame count
        data_s <= "00000100";
        wait for 2 * CLK_PERIOD;
        -- tm data field
        data_s <= "00011000";
        wait for 2 *CLK_PERIOD;
        -- first header pointer
        data_s <= "00000000";
        wait for 2 *CLK_PERIOD;

        -- tm data field (2040 octets) space packets
        for j in 0 to 6 loop -- 7 full space packets of 256 octets each to fill the tm frame data field with 1792 octets
            for i in 0 to MAX_SPACE_PACKET_SIZE_OCTET - 1 loop
                data_s <= max_size_space_packet_s(wr_ptr);
                data_valid_s <= '1';
                wr_ptr <= wr_ptr + 1;
                if wr_ptr = MAX_SPACE_PACKET_SIZE_OCTET - 1 then
                    wr_ptr <= 0;
                end if;
                wait for 2 * CLK_PERIOD;
            end loop;
        end loop;
        
        -- last space packet with 248 octets total size to match tm frame data field size of 2040 octets
        -- packet version number + packet type + sec hdr flag + apid
        for i in 0 to REDUZED_SPACE_PACKET_SIZE_OCTET - 1 loop
            data_s <= reduced_size_space_packet_s(wr_ptr);
            data_valid_s <= '1';
            wr_ptr <= wr_ptr + 1;
            if wr_ptr = REDUZED_SPACE_PACKET_SIZE_OCTET - 1 then
                wr_ptr <= 0;
            end if;
            wait for 2 * CLK_PERIOD;
        end loop;
        data_valid_s <= '0';
        wait for CLK_PERIOD;

        report "Finished input data, waiting for output validation";

        while output_validate_done_s = false loop
            wait for CLK_PERIOD;
        end loop;

        -- Test Reset
        reset_s <= '1';
        wait for CLK_PERIOD;
        -- tf frame version number + spacraft id
        data_s <= "00000001";
        data_valid_s <= '1';
        wait for 2 * CLK_PERIOD;
        -- spacecraft id + vc id + ocf flag
        data_s <= "00000010";
        wait for 2 * CLK_PERIOD;
        -- master channel frame count
        data_s <= "00000011";
        wait for 2 * CLK_PERIOD;
        -- virtual channel frame count
        data_s <= "00000100";
        wait for 2 * CLK_PERIOD;
        -- tm data field
        data_s <= "00011000";
        wait for 2 *CLK_PERIOD;
        -- first header pointer
        data_s <= "00000000";
        wait for 2 *CLK_PERIOD;

        -- tm data field (2040 octets) space packets
        for j in 0 to 6 loop -- 7 full space packets of 256 octets each to fill the tm frame data field with 1792 octets
            for i in 0 to MAX_SPACE_PACKET_SIZE_OCTET - 1 loop
                data_s <= max_size_space_packet_s(wr_ptr);
                data_valid_s <= '1';
                wr_ptr <= wr_ptr + 1;
                if wr_ptr = MAX_SPACE_PACKET_SIZE_OCTET - 1 then
                    wr_ptr <= 0;
                end if;
                wait for 2 * CLK_PERIOD;
            end loop;
        end loop;

        report "Resetting system...";
        reset_s <= '0';
        wr_ptr <= 0;
        data_valid_s <= '0';
        wait for 2 * CLK_PERIOD * 10; -- wait 10 clock cycles after reset to check if the system is properly reseted

        reset_s <= '1';
        wait for CLK_PERIOD;
        -- tf frame version number + spacraft id
        data_s <= "00000001";
        data_valid_s <= '1';
        wait for 2 * CLK_PERIOD;
        -- spacecraft id + vc id + ocf flag
        data_s <= "00000010";
        wait for 2 * CLK_PERIOD;
        -- master channel frame count
        data_s <= "00000011";
        wait for 2 * CLK_PERIOD;
        -- virtual channel frame count
        data_s <= "00000100";
        wait for 2 * CLK_PERIOD;
        -- tm data field
        data_s <= "00011000";
        wait for 2 *CLK_PERIOD;
        -- first header pointer
        data_s <= "00000000";
        wait for 2 *CLK_PERIOD;

        -- tm data field (2040 octets) space packets
        for j in 0 to 6 loop -- 7 full space packets of 256 octets each to fill the tm frame data field with 1792 octets
            for i in 0 to MAX_SPACE_PACKET_SIZE_OCTET - 1 loop
                data_s <= max_size_space_packet_s(wr_ptr);
                data_valid_s <= '1';
                wr_ptr <= wr_ptr + 1;
                if wr_ptr = MAX_SPACE_PACKET_SIZE_OCTET - 1 then
                    wr_ptr <= 0;
                end if;
                wait for 2 * CLK_PERIOD;
            end loop;
        end loop;
        
        -- last space packet with 248 octets total size to match tm frame data field size of 2040 octets
        -- packet version number + packet type + sec hdr flag + apid
        for i in 0 to REDUZED_SPACE_PACKET_SIZE_OCTET - 1 loop
            data_s <= reduced_size_space_packet_s(wr_ptr);
            data_valid_s <= '1';
            wr_ptr <= wr_ptr + 1;
            if wr_ptr = REDUZED_SPACE_PACKET_SIZE_OCTET - 1 then
                wr_ptr <= 0;
            end if;
            wait for 2 * CLK_PERIOD;
        end loop;
        data_valid_s <= '0';
        wait;
    end process data_input;

    validate_output: process is
    begin
        --for i in 447 downto 0 loop -- 448 * 4 (word size 4 octets) = 1792 octets of full space packets, then the last 248 octets of the last space packet
        while output_octet_count_s < 448 * 4 loop
            wait for CLK_PERIOD;
            if data_valid_o_s = '1' then
                output_octet_count_s <= output_octet_count_s + 4;
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
                end if;
            end if;
            wait for CLK_PERIOD;
        end loop;
        --for i in 61 downto 0 loop -- 62 * 4 (word size 4 octets) = 248 octets of the last space packet
        while output_octet_count_s < 448 * 4 + REDUZED_SPACE_PACKET_SIZE_OCTET loop
            wait for CLK_PERIOD;
            if data_valid_o_s = '1' then
                output_octet_count_s <= output_octet_count_s + 4;
                assert (data_o_s(7 downto 0) = reduced_size_space_packet_s(test_data_ptr + 0))
                report "output not matching input Space Packet index 0" severity failure;
                assert (data_o_s(15 downto 8) = reduced_size_space_packet_s(test_data_ptr + 1))
                report "output not matching input Space Packet index 1" severity failure;
                assert (data_o_s(23 downto 16) = reduced_size_space_packet_s(test_data_ptr + 2))
                report "output not matching input Space Packet index 2" severity failure;
                assert (data_o_s(31 downto 24) = reduced_size_space_packet_s(test_data_ptr + 3))
                report "output not matching input Space Packet index 3" severity failure;
                test_data_ptr <= test_data_ptr + 4;
                if test_data_ptr = REDUZED_SPACE_PACKET_SIZE_OCTET - 4 then
                    test_data_ptr <= 0;
                end if;
            end if;
            wait for CLK_PERIOD;
        end loop;
        output_octet_count_s <= 0;
        wait for 2 * CLK_PERIOD;
        report "Validate Output successful";
        output_validate_done_s <= true;

        -- reset test
        --for i in 447 downto 0 loop -- 448 * 4 (word size 4 octets) = 1792 octets of full space packets, then the last 248 octets of the last space packet
        while (output_octet_count_s < 448 * 4) and (reset_s = '1') loop
            wait for CLK_PERIOD;
            if data_valid_o_s = '1' then
                output_octet_count_s <= output_octet_count_s + 4;
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
                end if;
            end if;
            wait for CLK_PERIOD;
        end loop;
        --for i in 61 downto 0 loop -- 62 * 4 (word size 4 octets) = 248 octets of the last space packet
        while (output_octet_count_s < 448 * 4 + REDUZED_SPACE_PACKET_SIZE_OCTET) and (reset_s = '1') loop
            wait for CLK_PERIOD;
            if data_valid_o_s = '1' then
                output_octet_count_s <= output_octet_count_s + 4;
                assert (data_o_s(7 downto 0) = reduced_size_space_packet_s(test_data_ptr + 0))
                report "output not matching input Space Packet index 0" severity failure;
                assert (data_o_s(15 downto 8) = reduced_size_space_packet_s(test_data_ptr + 1))
                report "output not matching input Space Packet index 1" severity failure;
                assert (data_o_s(23 downto 16) = reduced_size_space_packet_s(test_data_ptr + 2))
                report "output not matching input Space Packet index 2" severity failure;
                assert (data_o_s(31 downto 24) = reduced_size_space_packet_s(test_data_ptr + 3))
                report "output not matching input Space Packet index 3" severity failure;
                test_data_ptr <= test_data_ptr + 4;
                if test_data_ptr = REDUZED_SPACE_PACKET_SIZE_OCTET - 4 then
                    test_data_ptr <= 0;
                end if;
            end if;
            wait for CLK_PERIOD;
        end loop;

        -- system reseted
        report "System Reseted";
        output_octet_count_s <= 0;
        test_data_ptr <= 0;
        while (output_octet_count_s < 448 * 4) loop
            wait for CLK_PERIOD;
            if data_valid_o_s = '1' then
                output_octet_count_s <= output_octet_count_s + 4;
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
                end if;
            end if;
            wait for CLK_PERIOD;
        end loop;
        --for i in 61 downto 0 loop -- 62 * 4 (word size 4 octets) = 248 octets of the last space packet
        while (output_octet_count_s < 448 * 4 + REDUZED_SPACE_PACKET_SIZE_OCTET) loop
            wait for CLK_PERIOD;
            if data_valid_o_s = '1' then
                output_octet_count_s <= output_octet_count_s + 4;
                assert (data_o_s(7 downto 0) = reduced_size_space_packet_s(test_data_ptr + 0))
                report "output not matching input Space Packet index 0" severity failure;
                assert (data_o_s(15 downto 8) = reduced_size_space_packet_s(test_data_ptr + 1))
                report "output not matching input Space Packet index 1" severity failure;
                assert (data_o_s(23 downto 16) = reduced_size_space_packet_s(test_data_ptr + 2))
                report "output not matching input Space Packet index 2" severity failure;
                assert (data_o_s(31 downto 24) = reduced_size_space_packet_s(test_data_ptr + 3))
                report "output not matching input Space Packet index 3" severity failure;
                test_data_ptr <= test_data_ptr + 4;
                if test_data_ptr = REDUZED_SPACE_PACKET_SIZE_OCTET - 4 then
                    test_data_ptr <= 0;
                end if;
            end if;
            wait for CLK_PERIOD;
        end loop;

        report "Validate Reset Output successful";
        wait;
    end process validate_output;
    
    expected_output_s <= 
        max_size_space_packet_s(test_data_ptr + 3) & max_size_space_packet_s(test_data_ptr + 2) & max_size_space_packet_s(test_data_ptr + 1) & max_size_space_packet_s(test_data_ptr) when output_octet_count_s < 448 * 4 else
        reduced_size_space_packet_s(test_data_ptr + 3) & reduced_size_space_packet_s(test_data_ptr + 2) & reduced_size_space_packet_s(test_data_ptr + 1) & reduced_size_space_packet_s(test_data_ptr);

end architecture behavioral;