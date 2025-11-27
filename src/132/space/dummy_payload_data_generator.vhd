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
	port(
        clk_i: in std_logic;
        data_frequency_divider_i: in std_logic_vector(3 downto 0);
        data_out_clk_o: out std_logic;
        data_out_o: out std_logic_vector(31 downto 0)
	);
end entity dummy_payload_data_generator;

architecture behavioral of dummy_payload_data_generator is
    constant MAX_DUMMY_PAYLOAD_VALUE: std_logic_vector := X"AFFE"; --Maximum Dummy Payload Value. Can be set to anything as long as it stays under the 16bit max value
    
    signal out_clk_r: std_logic := '0';
    signal counter_r: std_logic_vector(3 downto 0) := "0000";
    signal data_sig_r: std_logic_vector(15 downto 0) := X"0000";
begin
    
    with unsigned(counter_r) = "0000" select
        out_clk_r <=    clk_i when true,
                        '0' when others;

    data_out_clk_o <= out_clk_r;

    dummy_payload_data_clock_generator : process(clk_i) is
        variable updated_counter_s: std_logic_vector(3 downto 0) := "0000";
    begin
        if falling_edge(clk_i) then
            updated_counter_s := std_logic_vector(unsigned(counter_r) + 1);

            if unsigned(updated_counter_s) < unsigned(data_frequency_divider_i) then
                counter_r <= updated_counter_s;
            else
                counter_r <= "0000";
            end if;
        end if;
    end process dummy_payload_data_clock_generator;
    
    dummy_payload_data_generator : process(clk_i, out_clk_r) is
        variable temp_data_s: std_logic_vector(15 downto 0);
    begin
        if falling_edge(clk_i) and out_clk_r = '1' then
            data_out_o(15 downto 0) <= data_sig_r;
            data_out_o(31 downto 16) <= not data_sig_r;

            temp_data_s := std_logic_vector(unsigned(data_sig_r) + 1);

            if temp_data_s < MAX_DUMMY_PAYLOAD_VALUE then
                data_sig_r <= temp_data_s;
            else
                data_sig_r <= X"0000";        
            end if;
        end if;

    end process dummy_payload_data_generator;


end architecture behavioral;
