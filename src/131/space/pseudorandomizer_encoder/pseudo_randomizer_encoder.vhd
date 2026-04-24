----------------------------------------------------------------
-- File : pseudo_randomizer_encoder.vhd
-- Created : 02.12.2025
-- Author : Hannah Lindner 
-- Project Name : HW/SW Project TM
-- Description : implementation of pseudo_randomizer encoder 
----------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;

entity pseudo_randomizer_encoder is
    port(
        -- input ports 
        clk_i           : in std_logic; 
        reset_i         : in std_logic;
        data_valid_i    : in std_logic; 
        encoder_done_i  : in std_logic; 
        data_i          : in std_logic_vector(7 downto 0);
        -- output ports 
        data_o          : out std_logic; 
        data_valid_o    : out std_logic 
    ); 
end entity pseudo_randomizer_encoder; 

architecture behav of pseudo_randomizer_encoder is

    signal reset_signal_s : std_logic := '0';
    signal randomized_data_s : std_logic := '0';
    signal randomized_data_valid : std_logic := '1';
    signal input_data_s : std_logic := '0';
    signal data_buffer_r : std_logic_vector (7 downto 0);
     
begin 

pseudo_randomization : entity work.pseudo_randomizer_component
port map (
        clk_i   => clk_i, 
        reset_i => reset_signal_s,
        data_i  => input_data_s,
        -- output ports  
        data_o  => randomized_data_valid,
        done_o  => randomized_data_s
);

buffer_input_data : process (clk_i, reset_i)
    variable data_count : integer range 0 to 8 := 0;
begin 

    if reset_i = '0' then
        -- external reset signal 
        reset_signal_s <= '0';
    elsif rising_edge(clk_i) then
        if data_valid_i = '0' and  encoder_done_i = '1' then
            data_buffer_r <= data_i; 
        end if;
    end if; 
    
end process buffer_input_data;


end architecture behav;