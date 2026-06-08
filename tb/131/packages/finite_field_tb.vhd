----------------------------------------------------------------
-- File : finite_field_tb.vhd
-- Created : 17.11.2025
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : Testbench for Custom Package for finite field maths
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity finite_field_tb is
end entity finite_field_tb;

architecture behavioral of finite_field_tb is
    
begin

    finite_field_tb_process : process 
        variable return_val : finite_field_t := "00000000";
    begin
        return_val := gf_add("00001111","00001110");
        return_val := gf_mult("00001111","00001110");
        return_val := DUAL_TO_CONVENTIONAL(gf_to_int(return_val));
        return_val := CONVENTIONAL_TO_DUAL(gf_to_int(return_val));
    end process finite_field_tb_process;

end architecture behavioral;