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
        data_valid_i: in std_logic;
        clk_i: in std_logic;
        reset_i: in std_logic;
        data_i: in std_logic_vector(7 downto 0);
        transfer_frame_version_number_i: in std_logic_vector(1 downto 0);
        spacecraft_id_i: in std_logic_vector(9 downto 0);
        ground_clk_i: in std_logic
    );
end entity top_level;

architecture behavioral of top_level is
    component virtual_channel_buffer is
        port (
            clk_i: in std_logic;
            reset_i: in std_logic;
            data_i: in std_logic_vector(7 downto 0);
            data_valid_i: in std_logic;
            ready_o: out std_logic;
            frame_ready_o: out std_logic;
            data_out_en_i: in std_logic;
            data_o: out std_logic_vector(7 downto 0) := (others => '0');
            virtual_channel_frame_count_o: out std_logic_vector(7 downto 0)
        );
    end component virtual_channel_buffer;

    component transfer_frame_encoder is
        port (
            clk_i: in std_logic;
            reset_i: in std_logic;
            transfer_frame_version_number_i: in std_logic_vector(1 downto 0);
            spacecraft_id_i: in std_logic_vector(9 downto 0);
            out_en_o: out std_logic;
            data_o: out std_logic_vector(7 downto 0);
            out_full_i: in std_logic;
            vch0_frame_ready_i: in std_logic;
            vch0_data_en_o: out std_logic := '0';
            vch0_data_i: in std_logic_vector(7 downto 0);
            vch0_virtual_channel_frame_count_i: in std_logic_vector(7 downto 0)
        );
    end component transfer_frame_encoder;

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

    signal virtual_channel_data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal virtual_channel_frame_ready_s: std_logic := '0';
    signal virtual_channel_frame_count_s: std_logic_vector(7 downto 0) := (others => '0');
    signal virtual_channel_data_en_s: std_logic := '0';

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

begin

    virtual_channel_buffer_inst: virtual_channel_buffer port map (
        clk_i => clk_i,
        reset_i => reset_i,
        data_i => data_i,
        data_valid_i => data_valid_i,
        ready_o => ready_o,
        frame_ready_o => virtual_channel_frame_ready_s,
        data_out_en_i => virtual_channel_data_en_s,
        data_o => virtual_channel_data_s,
        virtual_channel_frame_count_o => virtual_channel_frame_count_s
    );

    transfer_frame_encoder_inst: transfer_frame_encoder port map (
        clk_i => clk_i,
        reset_i => reset_i,
        transfer_frame_version_number_i => transfer_frame_version_number_i,
        spacecraft_id_i => spacecraft_id_i,
        out_en_o => transfer_frame_output_enable_s,
        data_o => transfer_frame_data_s,
        out_full_i => transfer_frame_output_full_s,
        vch0_frame_ready_i => virtual_channel_frame_ready_s,
        vch0_data_en_o => virtual_channel_data_en_s,
        vch0_data_i => virtual_channel_data_s,
        vch0_virtual_channel_frame_count_i => virtual_channel_frame_count_s
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
