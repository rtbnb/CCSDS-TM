----------------------------------------------------------------
-- File : fecf_encoder.vhd
-- Created : 26.05.2026
-- Author : Robin Eilers
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 FECF Encoder
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fecf_encoder is
	Port(
        clk_i: in std_logic;
        en_i: in std_logic;
        reset_i: in std_logic;
        data_i: in std_logic_vector(7 downto 0);
        
        fecf_o: out std_logic_vector(15 downto 0)
	);
end entity fecf_encoder;

architecture behavioral of fecf_encoder is
begin
    fecf_o <= (others => '0');
end architecture behavioral;
