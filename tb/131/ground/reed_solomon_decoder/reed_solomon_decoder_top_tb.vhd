----------------------------------------------------------------
-- File : reed_solomon_decoder_top_tb.vhd
-- Created : 20.05.2026
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : Testbench full R/S Decoder 
----------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_decoder_top_tb is
end entity reed_solomon_decoder_top_tb;

architecture behavioral of reed_solomon_decoder_top_tb is
    component reed_solomon_decoder_top is
    port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        input_byte_i : in std_logic_vector (7 downto 0);
        data_valid_i : in std_logic := '0';
        asm_done_i : in std_logic;

        data_valid_o : out std_logic;
        output_byte_o : out std_logic_vector (7 downto 0);
		reed_solomon_failure_o : out std_logic
    );
    end component;

    signal        clk_r                   : std_logic := '0';
    signal        reset_r                 : std_logic := '1';
    signal        asm_done_r              : std_logic := '1';
    signal        data_r                  : finite_field_t;
    signal        data_valid_r            : std_logic;
    
    signal        data_valid_o            : std_logic;
    signal        output_byte_r           : std_logic_vector (7 downto 0);        
    
    signal        input_value_r           : Integer range 0 to 300 := 1;
    
begin

    dut : reed_solomon_decoder_top
    port map (
      clk_i         => clk_r,
      reset_i       => reset_r,
      asm_done_i    => asm_done_r, 
      input_byte_i => data_r,
      data_valid_i => data_valid_r,
      data_valid_o => data_valid_o,
      output_byte_o => output_byte_r
    );
           
    clk_r <= not clk_r after 5 ns;
    
    data_valid_stimuli: process
    begin
        if asm_done_r = '0' then
            input_value_r <= input_value_r +1;
            data_r <=std_logic_vector(TO_UNSIGNED(input_value_r,8));
            
            data_valid_r <='1';
            wait for 10 ns;
            data_valid_r <='0';
            wait for 40 ns;
            
            if input_value_r = 255 then
                input_value_r <= 1;
            end if;
        else
            wait for 10 ns;
        end if;
    end process data_valid_stimuli;
    
    stimuli: process
    begin
        asm_done_r <= '1';
        wait for 100 ns;
        asm_done_r <= '0';
        wait for 12780 ns;
        
        
    end process stimuli;

    

end architecture;