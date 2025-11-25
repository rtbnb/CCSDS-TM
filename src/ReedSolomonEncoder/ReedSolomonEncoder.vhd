-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- File : ReedSolomonEncoder.vhd
-- Created : 18.11.2025
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : R/S Encoder (255,223)
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_encoder is
    port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        input_byte_i : in std_logic_vector (7 downto 0);

        output_byte_o : out std_logic_vector (7 downto 0);
        encoder_done_flag_o : out std_logic := '0'
        
    );
end entity;

architecture behavioral of reed_solomon_encoder is
    type finite_field_array_t      is array (0 to 31) of finite_field_t;

    signal clock_devider_count_r : integer range 0 to 258;
    signal rising_edge_count_r : integer range 0 to 15;
    
    signal finite_field_regs_r : finite_field_array_t := (others => "00000000");
    signal rs_generator_poly_s : finite_field_array_t := (x"01",x"5B",x"7F",x"56",
                                                        x"10",x"1E",x"0D",x"EB",
                                                        x"61",x"A5",x"08",x"2A",
                                                        x"36",x"56",x"AB",x"20",
                                                        x"71",x"20",x"AB",x"56",
                                                        x"36",x"2A",x"08",x"A5",
                                                        x"61",x"EB",x"0D",x"1E",
                                                        x"10",x"56",x"7F",x"5B"); -- Coefs directly from the CCSDS Standard
    
    constant MAX_ERROR_COUNT : INTEGER := 16; -- Number of Errors to be correcable
    constant ASM_BYTE_LENGHT : INTEGER := 4; -- A ASM is 32-Bit in lenght 
    constant MESSAGE_LENGHT : INTEGER := 255; -- Lenght of a R/S Code block where 223 data is user data and 2*16 is Parity check symbols
    constant CLOCK_DIVISION : INTEGER := 15; -- Number of Cycles to be waited after a R/S Symbol - 1 (e.g. 16-1 = 15) (To syncronize with lower layers);
    
    
begin
    reed_solomon_encoder : process (clk_i)
        variable input_addition : finite_field_t;
    begin
        if reset_i = '0' then
            clock_devider_count_r <= 0;
            rising_edge_count_r <= 0;
            encoder_done_flag_o <= '1';
            output_byte_o <= "00000000";

            -- TODO: reset internal variables
            finite_field_regs_r <= (others => "00000000");
        elsif rising_edge(clk_i) then

            -- A byte shall be computed every 16 Clk cylces (To leave time for CC and RNG)
            if rising_edge_count_r = CLOCK_DIVISION then
                rising_edge_count_r <= 0;

                -- Reset clk devicer count after 259 Cycles (of by one thats why 258)
                if clock_devider_count_r = MESSAGE_LENGHT+ASM_BYTE_LENGHT-1 then
                    clock_devider_count_r <= 0; 
                    encoder_done_flag_o <= '0';
                else
                    -- leave space for ASM (4 Bytes)
                    if clock_devider_count_r >= MESSAGE_LENGHT then
                        -- Encoder Done Flag, wait for 32 Bit for ASM data    
                        encoder_done_flag_o <= '1';
                        output_byte_o <= "00000000";
                    -- Normal encoder logic
                    else
                        -- Send out 223 bytes of user data
                        if clock_devider_count_r < MESSAGE_LENGHT-2*MAX_ERROR_COUNT then
                            -- Encoder Message Logic
                            input_addition:= finite_field_regs_r(MAX_ERROR_COUNT*2-1);
                            input_addition:= gf_add(
                                DUAL_TO_CONVENTIONAL(to_integer(unsigned(input_byte_i))),
                                finite_field_regs_r(MAX_ERROR_COUNT*2-1)
                            );
                            
                            output_byte_o <= input_byte_i;
                        else
                            -- Adding Parity sympols and zeroing the input value
                            input_addition := "00000000";
                            
                            -- Output paritiy check sympols
                            output_byte_o <= CONVENTIONAL_TO_DUAL(
                                gf_to_int(finite_field_regs_r(MAX_ERROR_COUNT*2-1))
                                );
                        end if;

                            -- Calculate the new Values for the registers
                            loop_register_updating : for register_index in 0 to finite_field_regs_r'length-1 loop
                                if register_index = 0 then

                                    -- There is now -1th element of the register so no addition (or a addition by zero)
                                    finite_field_regs_r(register_index) <= gf_mult(rs_generator_poly_s(register_index), input_addition);
                                else
                                    -- This is the full calculation r_k(i+1) = r_(k-1)(i) + g_k * in
                                    finite_field_regs_r(register_index) <=  gf_add(
                                            gf_mult(rs_generator_poly_s(register_index), input_addition), 
                                            finite_field_regs_r(register_index-1));
                                end if;
                            end loop loop_register_updating;


                    end if; 
                    clock_devider_count_r <= clock_devider_count_r + 1;
                end if;
            else
                rising_edge_count_r <= rising_edge_count_r + 1;
            end if;
        end if;
        
    end process reed_solomon_encoder;
    

end architecture behavioral;