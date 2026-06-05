----------------------------------------------------------------
-- File : reed_solomon_decoder_axi_stream.vhd
-- Created : 02.06.2026
-- Author : Matthias Fuchs
-- Project Name : HW/SW Project TM
-- Description : Axi stream apadter to interface between rest of CCSDS 131 and R/S Decoder
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.finite_field.all;

entity reed_solomon_decoder_axi_stream is
    port (
        clk_i               : in  std_logic;
        reset_i             : in  std_logic;
        
        rs_input_byte_o     : out std_logic_vector (7 downto 0);
        rs_data_valid_in_o  : out std_logic := '0';
        rs_asm_done_o       : out std_logic;
        
        rs_data_valid_out_i : in std_logic;
        rs_output_byte_i    : in std_logic_vector (7 downto 0);
        
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
end entity reed_solomon_decoder_axi_stream;

architecture behavioral of reed_solomon_decoder_axi_stream is

    signal s_axi_datavalid_s : std_logic := '0';
    signal m_axi_datavalid_s : std_logic := '0';
    
    signal m_tvalid_s : std_logic := '0';
    signal s_tready_s : std_logic := '1';
    
    signal asm_done_r: std_logic := '0';
    signal output_from_fifo_r : std_logic := '1';
    signal fifo_data_valid_r   : std_logic := '0';

begin

    -- asynchronous assignments 
    s_axi_datavalid_s     <= s_tready_s and s_axi_tvalid;
    m_axi_datavalid_s     <= m_axi_tready and m_tvalid_s;
    
    m_axi_tvalid        <= m_tvalid_s;
    s_axi_tready        <= s_tready_s;
    
    
    axi_strem_apater: process(reset_i, clk_i)
    begin
        if reset_i ='0' then 
            -- reset signals 
            m_tvalid_s    <= '0';
            s_tready_s <= '1';
            m_axi_tdata <= x"00";
            m_axi_tlast     <= '0';
            asm_done_r <= '1';
            fifo_data_valid_r <= '0';
    
        elsif rising_edge(clk_i) then 
          rs_asm_done_o <= asm_done_r;
          asm_done_r <= '0';
          fifo_data_valid_r <= fifo_data_valid_r or rs_data_valid_out_i;
          --rs_data_valid_in_o <= '0';
    
          --s_tready_s    <=  m_axi_tready;
    
          -- reset data valid flags 
            if m_axi_datavalid_s = '1' then
                m_tvalid_s        <= '0';
                m_axi_tlast     <= '0';
                s_tready_s        <= '1';
                rs_data_valid_in_o <= '0';
            elsif output_from_fifo_r = '0' then
                m_tvalid_s        <= '0';
                s_tready_s        <= '1';
                output_from_fifo_r <= '1';
                rs_data_valid_in_o <= '0';

            elsif s_axi_datavalid_s = '1' then
                -- output data if rs is valid
                if  fifo_data_valid_r = '1' then
                    fifo_data_valid_r <= '0';
                    m_axi_tdata <= rs_output_byte_i;
                    m_tvalid_s        <= '1';
                    output_from_fifo_r <= '1';

                else
                    m_tvalid_s        <= '0';
                    output_from_fifo_r <= '0';

                end if;
                
                -- input data into rs
                rs_input_byte_o <= s_axi_tdata;
                rs_data_valid_in_o <= '1';
                
                
                -- check for tlast thus checking if asm was found by ASM decoder
                if s_axi_tlast ='1' then
                    asm_done_r <= '1';
                end if;
                
                m_axi_tlast     <= '0';
                s_tready_s        <= '0';
            end if;
    
        end if; -- rising edge 
    end process axi_strem_apater; -- main process

end architecture behavioral;