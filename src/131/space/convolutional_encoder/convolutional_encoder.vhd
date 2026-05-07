----------------------------------------------------------------
-- File : convolutional_encoder.vhd
-- Created : 06.05.2026
-- Author : Lukas Reil
-- Project Name : HW/SW Project TM
-- Description : A convolutional encoder module. It uses a configurable length and generator polynomials G1 and G2. The output data rate is 2x the input data rate.
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity convolutional_encoder is
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
end entity convolutional_encoder;

architecture behavioral of convolutional_encoder is
    signal shift_register_r : std_logic_vector(K_g-1 downto 0) := (others => '0');
    signal output_bit_select_r : std_logic := '0'; -- '0' for first output bit, '1' for second output bit

    signal output_bit_1_s : std_logic := '0';
    signal output_bit_2_s : std_logic := '0';


    function calculate_parity_bit(
        shift_reg : std_logic_vector(K_g-1 downto 0);
        g : integer
    ) return std_logic is
        
        variable parity_bit : std_logic := '0';
        variable g_vector : std_logic_vector(K_g-1 downto 0);
    begin
        g_vector := std_logic_vector(to_unsigned(g, K_g));
        for i in 0 to K_g-1 loop
            if g_vector(i) = '1' then
                parity_bit := parity_bit xor shift_reg(i);
            end if;
        end loop;
        return parity_bit;
    end function calculate_parity_bit;

begin


    main_process : process(clk_i, reset_i)
    begin
        if reset_i = '0' then
            shift_register_r <= (others => '0');
            output_bit_select_r <= '0';
            data_out_ready_o <= '0';
        elsif rising_edge(clk_i) then
            -- Only process input every second clock cycle
            output_bit_select_r <= not output_bit_select_r;
            if output_bit_select_r = '1' then 
                if data_in_ready_i = '1' then
                    shift_register_r <= data_in_i & shift_register_r(K_g-1 downto 1);
                    data_out_ready_o <= '1';
                else
                    data_out_ready_o <= '0';
                end if;
            end if;
        end if;
    end process main_process;

    output_bit_1_s <= calculate_parity_bit(shift_register_r, G1_g) xor INVERT_MASK_g(0);
    output_bit_2_s <= calculate_parity_bit(shift_register_r, G2_g) xor INVERT_MASK_g(1);
    
    data_out_o <= output_bit_1_s when output_bit_select_r = '0' else output_bit_2_s;

end architecture behavioral;
