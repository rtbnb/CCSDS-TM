----------------------------------------------------------------
-- File         : asm_decoder.vhd
-- Created      : 24.04.2025
-- Author       : Hannah Lindner 
-- Project Name : HW/SW Project TM
-- Description  : ASM Pattern decoder, removes asm pattern from bitstream
----------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity asm_decoder is
    generic(
        clock_divider_g : integer := 1
        );
    port ( 
    -- input ports 
    clk_i       : in std_logic; 
    reset_i     : in std_logic; 
    data_i      : in std_logic; 
    data_valid_i: in std_logic;
    -- output ports 
    data_o          : out std_logic;
    data_valid_o    : out std_logic;
    decoder_done_o  : out std_logic 
    );
end asm_decoder;

architecture behavioral of asm_decoder is
    signal shift_register_r : std_logic_vector(31 downto 0) := (others => '0'); 
    constant ASM_PATTERN    : std_logic_vector(31 downto 0) := x"1ACFFC1D"; 
    signal counter_r        : integer range 0 to 32 := 0;
    signal register_full_r  : integer range 0 to 33 := 0;
    signal asm_detected_r   : std_logic := '0'; 

begin

check_for_asm: process(clk_i, reset_i)
    variable clock_counter_r    : integer := 0; -- variable for clock division
begin 
    if reset_i = '0' then 
        -- reset all variables and signals 
        data_o              <= 'U';
        data_valid_o        <= '0';
        decoder_done_o      <= '0';
        register_full_r     <= 0;
        asm_detected_r      <= '0';
        counter_r           <= 0;
        shift_register_r    <= (others => '0');
        
    elsif rising_edge(clk_i)then 
        clock_counter_r := clock_counter_r + 1; -- increase clock counter  
        data_valid_o <= '0';
        if clock_counter_r = clock_divider_g then
            clock_counter_r := 0; -- reset clock counter 
            if data_valid_i = '1' then 
                -- shift register 
                register_full_r <= register_full_r + 1; 
                data_o <= shift_register_r(31);
                shift_register_r <= shift_register_r(30 downto 0) & data_i;
                if register_full_r = 32 then 
                -- only work if shift register is full 
                    register_full_r <= 32;
                    -- check if asm patter detected 
                    if asm_detected_r = '0' then 
                        if shift_register_r = ASM_PATTERN then
                            asm_detected_r <= '1'; 
                            data_valid_o <= '0';
                            decoder_done_o <= '1';
                            data_o <= 'U';
                        else 
                            data_valid_o <= '1';
                            decoder_done_o <= '0';
                        end if; 
                    elsif asm_detected_r = '1' then 
                    -- if asm pattern was already detected, delay data valid flag for 32 cycles 
                        if counter_r = 30 then 
                            counter_r <= 0; 
                            asm_detected_r <= '0'; 
                            data_o <= 'U';
                        else
                            counter_r <= counter_r + 1; 
                            asm_detected_r <= '1'; 
                            data_valid_o <= '0';
                            data_o <= 'U';
                        end if; 
                    end if; -- asm detection
                end if; -- register full check 
            end if; -- data valid check
        end if; -- clock divider 
    end if; -- reset logic
end process; 


end behavioral;
