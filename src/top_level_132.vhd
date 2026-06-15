----------------------------------------------------------------
-- File : top_level_132.vhd
-- Created : 05.06.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Integration Top Level
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level_132 is
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
end entity top_level_132;

architecture behavioral of top_level_132 is
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

    component synchronization_fifo_axi_stream is
        generic (
            DATA_WIDTH : integer := 8;
            DEPTH      : integer := 16
        );
        port (
            -- Input Interface
            s_axis_aclk : in  std_logic;
            s_axis_aresetn : in  std_logic;
            s_axis_tvalid : in  std_logic;
            s_axis_tdata  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            s_axis_tready : out std_logic;

            -- Output Interface
            m_axis_aclk : in  std_logic;
            m_axis_aresetn : in  std_logic;
            m_axis_tvalid : out std_logic;
            m_axis_tdata  : out std_logic_vector(DATA_WIDTH-1 downto 0);
            m_axis_tready : in  std_logic
        );
    end component synchronization_fifo_axi_stream;

    signal gnd_fifo_m_axis_tdata_s: std_logic_vector(7 downto 0) := (others => '0');
    signal gnd_fifo_m_axis_tvalid_s: std_logic := '0';
    signal gnd_fifo_s_axis_tlast_s: std_logic;

    component top_level_ground_132 is
        port (
            s_axi_tdata: in std_logic_vector(7 downto 0);
            s_axi_tvalid: in std_logic;
            s_axi_tready: out std_logic;
            s_axi_tlast: in std_logic;
            gnd_clk_i: in std_logic;
            reset_i: in std_logic;
            vc1_m_axi_tvalid    : out std_logic := '0';
            vc1_m_axi_tready    : in std_logic;
            vc1_m_axi_tdata     : out std_logic_vector(31 downto 0) := x"00000000";
            vc1_m_axi_tlast     : out std_logic := '0'
        );
    end component top_level_ground_132;
    signal gnd_132_s_axis_t_ready_s: std_logic;

    signal transfer_frame_data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal transfer_frame_output_enable_s: std_logic := '0';
    signal transfer_frame_output_full_s: std_logic := '0';

    signal ccsds_132_m_axis_tvalid: std_logic;
    signal ccsds_132_m_axis_tdata: std_logic_vector(7 downto 0);
    signal ccsds_132_m_axis_tready: std_logic;
    signal ccsds_132_m_axis_tlast: std_logic;

    signal fifo_132_ground_empty_s: std_logic := '1';
    signal fifo_132_ground_rd_data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal fifo_132_ground_rd_en_s: std_logic := '0';

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

    fifo_132_inst: synchronization_fifo_axi_stream port map (
        s_axis_aclk => clk_i,
        s_axis_aresetn => reset_i,
        s_axis_tvalid => ccsds_132_m_axis_tvalid,
        s_axis_tdata => ccsds_132_m_axis_tdata,
        s_axis_tready => ccsds_132_m_axis_tready,
        m_axis_aclk => ground_clk_i,
        m_axis_aresetn => reset_i,
        m_axis_tvalid => gnd_fifo_m_axis_tvalid_s,
        m_axis_tdata => gnd_fifo_m_axis_tdata_s,
        m_axis_tready => gnd_132_s_axis_t_ready_s
    );

    top_level_ground_132_inst: top_level_ground_132 port map (
        s_axi_tdata => gnd_fifo_m_axis_tdata_s,
        s_axi_tvalid => gnd_fifo_m_axis_tvalid_s,
        s_axi_tready => gnd_132_s_axis_t_ready_s,
        s_axi_tlast => gnd_fifo_s_axis_tlast_s,
        gnd_clk_i => ground_clk_i,
        reset_i => reset_i,
        vc1_m_axi_tvalid => vc1_m_axi_tvalid,
        vc1_m_axi_tready => vc1_m_axi_tready,
        vc1_m_axi_tdata => vc1_m_axi_tdata,
        vc1_m_axi_tlast => vc1_m_axi_tlast
    );

end architecture behavioral;
