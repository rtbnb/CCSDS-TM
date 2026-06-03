----------------------------------------------------------------
-- File         : asm_encoder.vhd
-- Created      : 26.03.2026
-- Author       : Hannah Lindner 
-- Project Name : HW/SW Project TM
-- Description  : component to add asm stream after pseudo randomization,
-- ASM Pattern  : 0x1ACFFC1D
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity asm_encoder is
    generic(
        clock_divider_g : integer := 1
        );
    port (
        -- input 
        clk_i           : in std_logic; 
        reset_i         : in std_logic;
        data_i          : in std_logic;
        encoder_done_i  : in std_logic; 
        data_valid_i    : in std_logic;  
        -- output  
        data_o          : out std_logic;
        data_valid_o    : out std_logic
    ); 
end asm_encoder;

architecture behavioral of asm_encoder is

constant ASM_PATTERN    : std_logic_vector(31 downto 0) := x"1ACFFC1D";
signal counter_r        : integer range 0 to 32 := 0;

begin

P1: process(clk_i,reset_i)
    variable clock_counter_r    : integer := 0; -- variable for clock division
   
begin 
    if reset_i = '0' then 
        -- reset all variables and signals 
        counter_r       <= 0;
        data_o          <= '0';
        data_valid_o    <= '0';
        clock_counter_r := 0;
        
    elsif rising_edge(clk_i) then
        -- increase clock counter 
        clock_counter_r := clock_counter_r + 1; 
        --data_valid_o <= '0'; -- reset clock
        if clock_counter_r = clock_divider_g then 
            -- check if input data is valid 
                if encoder_done_i = '1' and counter_r < 32 then 
                    -- include asm if pseudorandomizer done
                    data_o <= ASM_PATTERN(31-counter_r);
                    counter_r <= counter_r + 1;
                    data_valid_o <= '1';
                else
                    if data_valid_i = '1' then 
                        -- otherwise forward data 
                        counter_r <= 0; 
                        data_o <= data_i; 
                        data_valid_o <= '1';
                    end if; 
                end if; 
        clock_counter_r := 0; -- reset clock counter 
        end if;
    end if;
end process P1; 

end behavioral;
