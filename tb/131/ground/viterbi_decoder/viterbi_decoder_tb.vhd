
---------------------------------------------------------------
-- File : viterbi_decoder_tb.vhd
-- Created : 16.05.2026
-- Author : Lukas Reil
-- Project Name : HW/SW Project TM
-- Description : A testbench for the Viterbi decoder.
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


entity viterbi_decoder_tb is
--  Port ( );
end entity viterbi_decoder_tb;

architecture behavioral of viterbi_decoder_tb is

    component viterbi_decoder is
        port (
            clk_i : in std_logic;
            reset_i : in std_logic;

            -- Convolutional encoded data input
            convolutional_data_tdata : in std_logic;
            convolutional_data_tvalid : in std_logic;
            convolutional_data_tready : out std_logic;

            -- Data output from Viterbi decoder
            decoded_data_tdata : out std_logic;
            decoded_data_tvalid : out std_logic;
            decoded_data_tready : in std_logic;
            decoded_data_tlast : out std_logic
        );
    end component viterbi_decoder;

    component convolutional_encoder is
        generic (
            -- Standard convolutional code as per CCSDS 131.0-B-5
            K_g : integer := 7; -- Constraint length
            G1_g : integer := 8#171#; -- Generator polynomial G1 (octal)
            G2_g : integer := 8#133#; -- Generator polynomial G2 (octal)
            INVERT_MASK_g : std_logic_vector(1 downto 0) := "10" -- Mask to invert output bits, '1' means invert. CCSDS standard uses "01" to invert the second output bit.
        );
        port (
            clk_i               : in  std_logic;
            reset_i             : in  std_logic;
            data_in_i           : in  std_logic;
            data_in_ready_i     : in  std_logic;
            data_out_o          : out std_logic;
            data_out_ready_o    : out std_logic
        );
    end component convolutional_encoder;
    
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    
    signal data_i : std_logic := '0';
    signal valid_i : std_logic := '0';
    signal ready_i : std_logic := '1';
    
    signal data_o : std_logic;
    signal valid_o : std_logic;
    signal full_o : std_logic;

    constant CLK_PERIOD : time := 10ns;

begin
    dut : design_1_wrapper
        port map(
            clk => clk,
            reset => reset,
            data_i => data_i,
            valid_i => valid_i,
            ready_i => ready_i,
            data_o => data_o,
            valid_o => valid_o,
            full_o => full_o
        );
    
    clk <= not clk after CLK_PERIOD / 2;
    
    resetter : process
    begin
        wait for CLK_PERIOD * 2;
        reset <= '1';
        wait for CLK_PERIOD * 2;
        reset <= '0';
        wait for CLK_PERIOD * 2;
        reset <= '1';
        wait;
    end process resetter;
    
    stimulus : process
    begin
        wait for CLK_PERIOD * 10;
        valid_i <= '1';
        
        data_i <= '1';
        wait for 2 * CLK_PERIOD;
        data_i <= '0';
        wait for 2 * CLK_PERIOD;
        data_i <= '0';
        wait for 2 * CLK_PERIOD;
        data_i <= '1';
        wait for 2 * CLK_PERIOD;
        
        data_i <= '0';
        wait for 2 * CLK_PERIOD;
        data_i <= '1';
        wait for 2 * CLK_PERIOD;
        data_i <= '0';
        wait for 2 * CLK_PERIOD;
        data_i <= '1';
        wait for 2 * CLK_PERIOD;
        data_i <= '1';
        wait for 2 * CLK_PERIOD;
        data_i <= '0';
        wait for 2 * CLK_PERIOD;
        data_i <= '0';
        wait for 2 * CLK_PERIOD;
        data_i <= '1';
        wait for 2 * CLK_PERIOD;
        data_i <= '0';
        wait for 2 * CLK_PERIOD;
        data_i <= '0';
        wait for 2 * CLK_PERIOD;
        data_i <= '0';
        wait for 2 * CLK_PERIOD;
        data_i <= '1';
        wait for 2 * CLK_PERIOD;
        data_i <= '0';
        wait for 2 * CLK_PERIOD;
        data_i <= '1';
        wait for 2 * CLK_PERIOD;
        data_i <= '1';
        wait for 2 * CLK_PERIOD;
        
        for i in 0 to 1000 loop
            data_i <= '1';
            wait for 2 * CLK_PERIOD;
            data_i <= '0';
            wait for 2 * CLK_PERIOD;
        end loop;            
        wait;
        
    end process stimulus;
    
    

end architecture behavioral;
