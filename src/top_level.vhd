----------------------------------------------------------------
-- File : top_level.vhd
-- Created : 05.06.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Integration Top Level
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
    port (
        -- outputs
        ready_o: out std_logic := '0';
        tm_data_field_valid_vc1_o: out std_logic := '0';
        tm_data_field_vc1_o: out std_logic_vector(31 downto 0) := (others => '0');
        vc1_m_axi_tvalid: out std_logic := '0'; 
        vc1_m_axi_tready: in std_logic;
        vc1_m_axi_tdata: out std_logic_vector(31 downto 0) := x"00000000";
        vc1_m_axi_tlast: out std_logic := '0';

        -- inputs
        clk_i: in std_logic;
        reset_i: in std_logic;
        ground_clk_i: in std_logic;

        -- vch0 inputs
        vch0_s_axis_tdata        : in std_logic_vector(7 downto 0);
        vch0_s_axis_tvalid       : in std_logic;
        vch0_s_axis_tready       : out std_logic;

        -- vch1 inputs
        vch1_s_axis_tdata        : in std_logic_vector(7 downto 0);
        vch1_s_axis_tvalid       : in std_logic;
        vch1_s_axis_tready       : out std_logic
    );
end entity top_level;

architecture behavioral of top_level is
    component top_level_space_132 is
        port (
            space_clk_i: std_logic;
            reset_i: std_logic;

            -- virtual channel 0 input interface
            vch0_s_axis_tdata        : in std_logic_vector(7 downto 0);
            vch0_s_axis_tvalid       : in std_logic;
            vch0_s_axis_tready       : out std_logic;        

            -- virtual channel 1 input interface
            vch1_s_axis_tdata        : in std_logic_vector(7 downto 0);
            vch1_s_axis_tvalid       : in std_logic;
            vch1_s_axis_tready       : out std_logic;

            -- output interface
            m_axis_tvalid : out std_logic;
            m_axis_tdata  : out std_logic_vector(7 downto 0);
            m_axis_tready : in  std_logic;
            m_axis_tlast : out std_logic
        );
    end component top_level_space_132;

    component synchronization_fifo is
        generic (
            data_width_g: integer := 8;
            depth_g: integer := 16
        );
        port (
            wr_clk_i: in std_logic;
            wr_en_i: in std_logic;
            wr_data_i: in std_logic_vector(data_width_g - 1 downto 0);
            full_o: out std_logic;
            rd_clk_i: in std_logic;
            rd_en_i: in std_logic;
            rd_data_o: out std_logic_vector(data_width_g - 1 downto 0);
            empty_o: out std_logic
        );
    end component synchronization_fifo;

    component ccsds_131_space is
        port (
            clk_i: in std_logic;
            reset_i: in std_logic;
            input_byte_i: in std_logic_vector(7 downto 0);
            fifo_empty_i: in std_logic;
            read_data_fifo_o: out std_logic;
            data_o: out std_logic;
            data_valid_o: out std_logic
        );
    end component ccsds_131_space;

    component ccsds_131_ground is
        port (
            clk_i: in std_logic;
            reset_i: in std_logic;
            data_i: in std_logic;
            data_valid_i: in std_logic;
            output_byte_o: out std_logic_vector(7 downto 0);
            data_valid_o: out std_logic;
            decoder_failure_o: out std_logic
        );
    end component ccsds_131_ground;

    component top_level_ground_132 is
        port (
            data_i: in std_logic_vector(7 downto 0);
            gnd_clk_i: in std_logic;
            reset_i: in std_logic;
            fifo_empty_i: in std_logic;
            rdy_o: out std_logic := '0';
            vc1_m_axi_tvalid    : out std_logic := '0';
            vc1_m_axi_tready    : in std_logic;
            vc1_m_axi_tdata     : out std_logic_vector(31 downto 0) := x"00000000";
            vc1_m_axi_tlast     : out std_logic := '0'
        );
    end component top_level_ground_132;

    signal transfer_frame_data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal transfer_frame_output_enable_s: std_logic := '0';
    signal transfer_frame_output_full_s: std_logic := '0';

    signal fifo_131_space_empty_s: std_logic := '1';
    signal fifo_131_space_rd_data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal ccsds_131_space_read_fifo_s: std_logic := '0';
    signal ccsds_131_space_data_s: std_logic := '0';
    signal ccsds_131_space_valid_s: std_logic := '0';

    signal fifo_131_ground_empty_s: std_logic := '1';
    signal fifo_131_ground_rd_data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal fifo_131_ground_rd_en_s: std_logic := '0';
    signal ccsds_131_ground_data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal ccsds_131_ground_valid_s: std_logic := '0';

    signal ccsds_132_m_axis_tvalid: std_logic;
    signal ccsds_132_m_axis_tdata: std_logic_vector(7 downto 0);
    signal ccsds_132_m_axis_tready: std_logic;
    signal ccsds_132_m_axis_tlast: std_logic;

begin

    top_level_space_132_inst: top_level_space_132 port map(
        space_clk_i => clk_i,
        reset_i => reset_i,
        vch0_s_axis_tdata => vch0_s_axis_tdata,
        vch0_s_axis_tvalid => vch0_s_axis_tvalid,
        vch0_s_axis_tready => vch0_s_axis_tready,   
        vch1_s_axis_tdata => vch1_s_axis_tdata,
        vch1_s_axis_tvalid => vch1_s_axis_tvalid,
        vch1_s_axis_tready => vch1_s_axis_tready,
        m_axis_tvalid => ccsds_132_m_axis_tvalid,
        m_axis_tdata => ccsds_132_m_axis_tdata,
        m_axis_tready => ccsds_132_m_axis_tready,
        m_axis_tlast => ccsds_132_m_axis_tlast      
    );

    fifo_131_space_inst: synchronization_fifo port map (
        wr_clk_i => clk_i,
        wr_en_i => transfer_frame_output_enable_s,
        wr_data_i => transfer_frame_data_s,
        full_o => transfer_frame_output_full_s,
        rd_clk_i => clk_i,
        rd_en_i => ccsds_131_space_read_fifo_s,
        rd_data_o => fifo_131_space_rd_data_s,
        empty_o => fifo_131_space_empty_s
    );

    ccsds_131_space_inst: ccsds_131_space port map (
        clk_i => clk_i,
        reset_i => reset_i,
        input_byte_i => fifo_131_space_rd_data_s,
        fifo_empty_i => fifo_131_space_empty_s,
        read_data_fifo_o => ccsds_131_space_read_fifo_s,
        data_o => ccsds_131_space_data_s,
        data_valid_o => ccsds_131_space_valid_s
    );

    ccsds_131_ground_inst: ccsds_131_ground port map (
        clk_i => ground_clk_i,
        reset_i => reset_i,
        data_i => ccsds_131_space_data_s,
        data_valid_i => ccsds_131_space_valid_s,
        output_byte_o => ccsds_131_ground_data_s,
        data_valid_o => ccsds_131_ground_valid_s,
        decoder_failure_o => open
    );

    fifo_131_ground_inst: synchronization_fifo port map (
        wr_clk_i => ground_clk_i,
        wr_en_i => ccsds_131_ground_valid_s,
        wr_data_i => ccsds_131_ground_data_s,
        full_o => open,
        rd_clk_i => ground_clk_i,
        rd_en_i => fifo_131_ground_rd_en_s,
        rd_data_o => fifo_131_ground_rd_data_s,
        empty_o => fifo_131_ground_empty_s
    );

    top_level_ground_132_inst: top_level_ground_132 port map (
        data_i => fifo_131_ground_rd_data_s,
        gnd_clk_i => ground_clk_i,
        reset_i => reset_i,
        fifo_empty_i => fifo_131_ground_empty_s,
        rdy_o => fifo_131_ground_rd_en_s,
        vc1_m_axi_tvalid => vc1_m_axi_tvalid,
        vc1_m_axi_tready => vc1_m_axi_tready,
        vc1_m_axi_tdata => vc1_m_axi_tdata,
        vc1_m_axi_tlast => vc1_m_axi_tlast
    );

end architecture behavioral;
