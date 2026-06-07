----------------------------------------------------------------
-- File : synchronization_fifo_axi_stream_integration.vhd
-- Created : 17.05.2025
-- Author : Lukas Reil 
-- Project Name : HW/SW Project TM
-- Description : Integration of the synchronization FIFOs with AXI Stream as input and output interface.
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity synchronization_fifo_axi_stream_integration is
    generic (
        DATA_WIDTH : integer := 8;
        DEPTH      : integer := 16
    );
    port(
        internal_clk_i : in std_logic;
        internal_rst_i : in std_logic;

        -- Input Interface
        wr_clk_i   : in  std_logic;
        wr_en_i    : in  std_logic;
        wr_data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        full_o     : out std_logic;

        -- Output Interface
        rd_clk_i   : in  std_logic;
        rd_en_i    : in  std_logic;
        rd_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        empty_o    : out std_logic
        
    );
end entity synchronization_fifo_axi_stream_integration;

architecture connectivity of synchronization_fifo_axi_stream_integration is

    signal axis_0_tvalid : std_logic;
    signal axis_0_tdata : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal axis_0_tready : std_logic;

    signal axis_1_tvalid : std_logic;
    signal axis_1_tdata : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal axis_1_tready : std_logic;


begin

    fifo_0 : entity work.synchronization_fifo_axi_stream_out
        port map (
            reset_i   => internal_rst_i,
            wr_clk_i => wr_clk_i,
            wr_en_i => wr_en_i,
            wr_data_i => wr_data_i,
            full_o => full_o,
            m_axis_aclk => internal_clk_i,
            m_axis_tvalid => axis_0_tvalid,
            m_axis_tdata => axis_0_tdata,
            m_axis_tready => axis_0_tready
        );
    
    fifo_1 : entity work.synchronization_fifo_axi_stream
        port map (
            reset_i => internal_rst_i,
            s_axis_aclk => internal_clk_i,
            s_axis_tvalid => axis_0_tvalid,
            s_axis_tdata => axis_0_tdata,
            s_axis_tready => axis_0_tready,
            m_axis_aclk => internal_clk_i,
            m_axis_tvalid => axis_1_tvalid,
            m_axis_tdata => axis_1_tdata,
            m_axis_tready => axis_1_tready
        );
    
    fifo_2 : entity work.synchronization_fifo_axi_stream_in
        port map (
            reset_i => internal_rst_i,
            s_axis_aclk => internal_clk_i,
            s_axis_tvalid => axis_1_tvalid,
            s_axis_tdata => axis_1_tdata,
            s_axis_tready => axis_1_tready,
            rd_clk_i => rd_clk_i,
            rd_en_i => rd_en_i,
            rd_data_o => rd_data_o,
            empty_o => empty_o
        );


end architecture connectivity;
