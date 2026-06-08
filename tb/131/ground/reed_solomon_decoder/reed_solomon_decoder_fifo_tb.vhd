----------------------------------------------------------------
-- File : reed_solomon_decoder_fifo_tb.vhd
-- Created : 28.11.2025
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : Testbench R/S Decoder stub for MVP, just implements the FIFO for error correction
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reed_solomon_decoder_fifo_tb is
end entity reed_solomon_decoder_fifo_tb;

architecture behavioral of reed_solomon_decoder_fifo_tb is
    component reed_solomon_decoder_fifo is
    port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        input_byte_i : in std_logic_vector (7 downto 0);
        data_valid_i : in std_logic := '0';

        data_valid_o : out std_logic;
        output_byte_o : out std_logic_vector (7 downto 0)
    );
  end component;

    signal clk_r   :  std_logic := '1';
    signal reset_r :  std_logic;
    signal input_byte_r :  std_logic_vector (7 downto 0);
    signal data_valid_i_r :  std_logic := '0';

    signal data_valid_o_r :  std_logic;
    signal output_byte_r :  std_logic_vector (7 downto 0);

begin

    dut : reed_solomon_decoder_fifo
    port map (
      clk_i       => clk_r,
      reset_i     => reset_r,
      input_byte_i=> input_byte_r,
      data_valid_i => data_valid_i_r,

      data_valid_o  => data_valid_o_r,
      output_byte_o => output_byte_r
    );

    clk_r <= not clk_r after 5 ns;
    reset_r <= '1';
    data_valid_i_r <= '1';

    stimul : process 
      variable dataIn : integer := 0;
    
    begin

        dataIn:= dataIn + 1;
        input_byte_r <= STD_LOGIC_VECTOR(TO_UNSIGNED(dataIn,8));
        wait for 10 ns;
    
        
    end process stimul;

    

end architecture;