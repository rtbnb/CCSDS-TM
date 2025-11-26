----------------------------------------------------------------
-- File : dummy_payload_data_generator.vhd
-- Created : 26.11.2025
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : Dummy Payload Data Generator
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dummy_payload_data_generator is
	Port(
        clk_i: in std_logic;
        data_freqency_divider_i: in std_logic_vector(3 downto 0);
        data_out_clk_o: out std_logic;
        data_out_o: out std_logic_vector(31 downto 0)
	);
end entity dummy_payload_data_generator;

architecture behavioral of dummy_payload_data_generator is
    signal out_clk_r: std_logic := '0';
    signal counter_r: std_logic_vector(3 downto 0) := "0000";
    signal data_sig_r: std_logic_vector(15 downto 0) := X"0000";

    constant MAX_DUMMY_PAYLOAD_VALUE: std_logic_vector := X"AFFE"; --Maximum Dummy Payload Value. Can be set to anything as long as it stays under the 16bit max value
begin
    data_out_clk_o <= out_clk_r and clk_i;

    dummy_payload_clock_generator : process(clk_i) is
    begin
        if rising_edge(clk_i) then
            if (unsigned(counter_r) + 1 < unsigned(data_freqency_divider_i)) then
                counter_r <= std_logic_vector(unsigned(counter_r) + 1);

                if out_clk_r <= '1' then
                    out_clk_r <= '0';
                end if;
            else
                counter_r <= "0000";
                out_clk_r <= '1';
            end if;
        end if;
    end process dummy_payload_clock_generator;

    dummy_payload_data_generator : process(clk_i, out_clk_r) is
        variable temp_data_s: std_logic_vector(15 downto 0);
    begin
        if falling_edge(clk_i) and out_clk_r = '1' then
            temp_data_s := std_logic_vector(unsigned(data_sig_r) + 1);
            data_out_o(15 downto 0) <= temp_data_s;
            data_out_o(31 downto 16) <= not temp_data_s;

            if temp_data_s < MAX_DUMMY_PAYLOAD_VALUE then
                data_sig_r <= temp_data_s;
            else
                data_sig_r <= X"0000";        
            end if;
        end if;

    end process dummy_payload_data_generator;


end architecture behavioral;
