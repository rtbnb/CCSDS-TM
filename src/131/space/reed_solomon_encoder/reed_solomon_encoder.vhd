----------------------------------------------------------------
-- File : reed_solomon_encoder.vhd
-- Created : 18.11.2025
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : R/S Encoder (255,223)
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_encoder is
    generic (
        USE_DUAL_BASIS : boolean := false -- Use dual basis vs normal basis represnetation see CCSDS 131.0-B-5 4.3.9 for more details
    );
    port (
        clk_i   : in std_logic;
        reset_i : in std_logic;
        
        -- axi inputs 
        s_axi_tvalid    : in std_logic; 
        s_axi_tready    : out std_logic;
        s_axi_tdata     : in std_logic_vector(7 downto 0);
        s_axi_tlast     : in std_logic;

        -- axi outputs
        m_axi_tvalid    : out std_logic; 
        m_axi_tready    : in std_logic;
        m_axi_tdata     : out std_logic_vector(7 downto 0);
        m_axi_tlast     : out std_logic
    
    );
end entity reed_solomon_encoder;

architecture behavioral of reed_solomon_encoder is
    type finite_field_array_t      is array (0 to 31) of finite_field_t;
    
    constant MAX_ERROR_COUNT : INTEGER := 16; -- Number of Errors to be correcable
    constant MESSAGE_LENGHT : INTEGER := 255; -- Lenght of a R/S Code block where 223 data is user data and 2*16 is Parity check symbols

    signal clock_devider_count_r : integer range 0 to MESSAGE_LENGHT := 0;
    signal reed_solomon_passthrough_r : std_logic := '1';
    
    signal finite_field_regs_r : finite_field_array_t := (others => "00000000");
    signal rs_generator_poly_s : finite_field_array_t := (x"01",x"5B",x"7F",x"56",
                                                        x"10",x"1E",x"0D",x"EB",
                                                        x"61",x"A5",x"08",x"2A",
                                                        x"36",x"56",x"AB",x"20",
                                                        x"71",x"20",x"AB",x"56",
                                                        x"36",x"2A",x"08",x"A5",
                                                        x"61",x"EB",x"0D",x"1E",
                                                        x"10",x"56",x"7F",x"5B"); -- Coefs directly from the CCSDS Standard
    signal s_axi_datavalid_s: std_logic := '0';
    signal m_axi_datavalid_s : std_logic := '0';
    
    signal m_tvalid_s : std_logic := '0';
    signal s_tready_s : std_logic := '0';
        
begin

    -- asynchronous assignments 
    s_axi_datavalid_s     <= s_tready_s and s_axi_tvalid;
    m_axi_datavalid_s     <= m_axi_tready and m_tvalid_s;
    
    m_axi_tvalid        <= m_tvalid_s;
    s_axi_tready        <= s_tready_s;
    

    reed_solomon_encoder : process (clk_i)
        variable input_addition : finite_field_t;
    begin
        if reset_i = '0' then
            clock_devider_count_r <= 0;
            finite_field_regs_r <= (others => "00000000");
            
            m_axi_tlast <= '0';
            m_axi_tdata <= x"00";
            reed_solomon_passthrough_r <= '1';
            
            m_tvalid_s    <= '0';
            s_tready_s    <= '0';
        elsif rising_edge(clk_i) then
        
            s_tready_s    <=  m_axi_tready;

              -- reset data valid flags 
            if m_axi_datavalid_s = '1' then
                 m_tvalid_s        <= '0';
                 m_axi_tlast     <= '0';
                 
                 if reed_solomon_passthrough_r = '1' then
                    s_tready_s        <= m_axi_tready;
                 else
                    s_tready_s        <= '0';
                 end if;
                 
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
                 
            elsif m_axi_tready = '1' and reed_solomon_passthrough_r = '0' then
                -- Adding Parity sympols and zeroing the input value
                input_addition := "00000000";
                
                -- Output paritiy check sympols
                if USE_DUAL_BASIS = true then
                    m_axi_tdata <= CONVENTIONAL_TO_DUAL(
                        gf_to_int(finite_field_regs_r(MAX_ERROR_COUNT*2-1))
                    );
                else
                    m_axi_tdata <= finite_field_regs_r(MAX_ERROR_COUNT*2-1);                     
                end if;
                  
                m_tvalid_s        <= '1';
                m_axi_tlast     <= '0';
                s_tready_s        <= '0';
                
                clock_devider_count_r <= clock_devider_count_r + 1;
                
                if clock_devider_count_r >= MESSAGE_LENGHT-1 then
                    reed_solomon_passthrough_r <= '1';
                    clock_devider_count_r <= 0;
                    m_axi_tlast     <= '1';
                    --s_tready_s      <= '1';
                end if;
    
            elsif s_axi_datavalid_s = '1' then
            
                -- Encoder Message Logic
                input_addition:= s_axi_tdata;
                                
                if USE_DUAL_BASIS = true then
                    input_addition:= DUAL_TO_CONVENTIONAL(to_integer(unsigned(input_addition)));             
                end if;
                
                input_addition:= gf_add(input_addition,finite_field_regs_r(MAX_ERROR_COUNT*2-1));
                
                m_axi_tdata <= s_axi_tdata;
                
                clock_devider_count_r <= clock_devider_count_r + 1;
                
                if clock_devider_count_r < MESSAGE_LENGHT-2*MAX_ERROR_COUNT-1 then
                    reed_solomon_passthrough_r <= '1';
                else
                    reed_solomon_passthrough_r <= '0';
                end if;
            
                 m_tvalid_s        <= '1';
                 m_axi_tlast     <= '0';
                 
                 s_tready_s        <= '0';
            end if;
        end if;
        
    end process reed_solomon_encoder;
    

end architecture behavioral;