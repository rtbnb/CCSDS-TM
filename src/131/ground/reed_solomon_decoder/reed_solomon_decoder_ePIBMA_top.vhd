----------------------------------------------------------------
-- File : reed_solomon_decoder_epibma_top.vhd
-- Created : 05.05.2026
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : The top for the systolic Enhanced Parallel Inversionless B-M Algorithm (ePIBMA) archiecture of the R/R decoder
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_decoder_epibma_top is
    generic(
        max_number_of_errors_g : integer := 16
    );
    port (
        clk_i               : in  std_logic;
        reset_i             : in  std_logic;
        new_poly_i          : in std_logic
    );
end entity reed_solomon_decoder_epibma_top;
