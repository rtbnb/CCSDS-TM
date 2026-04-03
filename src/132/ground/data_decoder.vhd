----------------------------------------------------------------
-- File : data_encoder.vhd
-- Created : 03.04.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Data Decoder
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_decoder is
    port (
        is_sec_header_i: in std_logic;
        sec_header_len_i: in std_logic_vector(5 downto 0);

        -- outputs
        data_o: out std_logic_vector(7 downto 0);
        data_clk_o: out std_logic;
        date_fully_read_o: out std_logic;
    );
end entity data_decoder