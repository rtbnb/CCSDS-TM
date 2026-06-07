----------------------------------------------------------------
-- File : viterbi_axi_adapter.vhd
-- Created : 07.06.2026
-- Author : Lukas Reil
-- Project Name : HW/SW Project TM
-- Description : An adapter module to buffer the correct AXI4-Stream behaviour of the Viterbi Decoder
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity viterbi_axi_adapter is

    port (
        clk_i : in std_logic;
        reset_i : in std_logic;

        -- Data input from Viterbi decoder
        s_axis_output_tvalid : in std_logic;
        s_axis_output_tdata  : in std_logic;
        s_axis_output_tlast  : in std_logic;
        s_axis_output_tready : out std_logic;

        -- Data output to AXI4-Stream interface
        m_axis_tdata : out std_logic;
        m_axis_tvalid : out std_logic;
        m_axis_tready : in std_logic;
        m_axis_tlast : out std_logic := '0'
    );
end entity viterbi_axi_adapter;


architecture behavioral of viterbi_axi_adapter is

    signal returned_ready_s : std_logic;
    signal fifo_full_s : std_logic;
    signal fifo_wr_en_s : std_logic;

begin

    s_axis_output_tready <= returned_ready_s;
    returned_ready_s <= not fifo_full_s;
    fifo_wr_en_s <= s_axis_output_tvalid and returned_ready_s;

    axi_stream_out_fifo : entity work.synchronization_fifo_axi_stream_out
        generic map (
            DATA_WIDTH => 1,
            DEPTH => 16
        )
        port map (
            wr_clk_i => clk_i,
            wr_en_i => fifo_wr_en_s,
            wr_data_i(0) => s_axis_output_tdata,
            full_o => fifo_full_s,

            m_axis_aclk => clk_i,
            m_axis_aresetn => reset_i,
            m_axis_tvalid => m_axis_tvalid,
            m_axis_tdata(0) => m_axis_tdata,
            m_axis_tready => m_axis_tready
        );


end architecture behavioral;