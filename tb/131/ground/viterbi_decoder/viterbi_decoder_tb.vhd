
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
            K : integer := 7; -- Constraint length
            G1 : integer := 8#171#; -- Generator polynomial G1 (octal)
            G2 : integer := 8#133#; -- Generator polynomial G2 (octal)
            INVERT_MASK : std_logic_vector(1 downto 0) := "10" -- Mask to invert output bits, '1' means invert. CCSDS standard uses "01" to invert the second output bit.
        );
        port (
            clk_i               : in  std_logic;
            reset_i             : in  std_logic;

            s_axis_tdata        : in std_logic_vector(0 downto 0);
            s_axis_tvalid       : in std_logic;
            s_axis_tready       : out std_logic;

            m_axis_tdata        : out std_logic_vector(0 downto 0);
            m_axis_tvalid       : out std_logic;
            m_axis_tready       : in std_logic
        );
    end component convolutional_encoder;
    
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    
    signal data_i : std_logic := '0';
    signal valid_i : std_logic := '0';
    signal ready_i : std_logic := '1';
    
    signal data_o : std_logic;
    signal valid_o : std_logic;
    signal ready_o : std_logic := '1';

    constant CLK_PERIOD : time := 10ns;

    signal conv_axis_tdata  : std_logic;
    signal conv_axis_tvalid : std_logic;
    signal conv_axis_tready : std_logic;

begin

    dut : viterbi_decoder
        port map (
            clk_i => clk,
            reset_i => reset,
            convolutional_data_tdata => conv_axis_tdata,
            convolutional_data_tvalid => conv_axis_tvalid,
            convolutional_data_tready => conv_axis_tready,
            decoded_data_tdata => data_o,
            decoded_data_tvalid => valid_o,
            decoded_data_tready => ready_o,
            decoded_data_tlast => open
        );

    conv_encoder : convolutional_encoder
        generic map (
            K => 7,
            G1 => 8#171#,
            G2 => 8#133#,
            INVERT_MASK => "10"
        )
        port map (
            clk_i => clk,
            reset_i => reset,
            s_axis_tdata(0) => data_i,
            s_axis_tvalid => valid_i,
            s_axis_tready => ready_i,
            m_axis_tdata(0) => conv_axis_tdata,
            m_axis_tvalid => conv_axis_tvalid,
            m_axis_tready => conv_axis_tready 
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

        data_i <= '1';
        wait for clk_period * 10; -- No output expected since data_ieady_r is '0'

        valid_i <= '1';
        wait for clk_period;
        valid_i <= '0';
        wait for clk_period;
        data_i <= '0';
        valid_i <= '1';
        wait for clk_period;
        valid_i <= '0';
        wait for clk_period;
        data_i <= '0';
        valid_i <= '1';
        wait for clk_period;
        valid_i <= '0';
        wait for clk_period;
        data_i <= '1';
        valid_i <= '1';
        wait for clk_period;
        valid_i <= '0';
        for i in 0 to 8 loop
            wait for clk_period;
            valid_i <= '1';
            wait for clk_period;
            valid_i <= '0';
        end loop;
        wait for clk_period * 2 * 8;

        for i in 0 to 1000 loop
            data_i <= not data_i; -- Alternate between '0' and '1'
            valid_i <= '1';
            wait for clk_period;
            valid_i <= '0';
            wait for clk_period;
        end loop;
        valid_i <= '0';
        wait;


    end process stimulus;
    
    

end architecture behavioral;
