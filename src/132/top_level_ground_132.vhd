----------------------------------------------------------------
-- File : top_level_ground_132.vhd
-- Created : 04.06.2026
-- Author : Nico Tunkowski
-- Project Name : HW/SW Project TM
-- Description : CCSDS-132.0-B-3 Top Level Decoder Entity
-- License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level_ground_132 is
    port (
        -- inputs
        data_i: std_logic_vector(7 downto 0); -- to 131 decoder
        gnd_clk_i: std_logic;
        reset_i: std_logic;
        fifo_empty_i: std_logic;

        -- outputs
        rdy_o: out std_logic := '0';
        -- every virtual channel needs its own output
        tm_data_field_vc1_o: out std_logic_vector(31 downto 0);
        tm_data_field_valid_vc1_o: out std_logic
    );
end entity top_level_ground_132;

architecture behavioral of top_level_ground_132 is

    constant TM_FRAME_DATA_FIELD_SIZE_OCTET: integer := 2040;

    -- data buffer and structure
    signal space_packet_data_s: std_logic_vector(7 downto 0);
    signal space_packet_data_valid_s: std_logic := '0';
    signal master_channel_id_s: std_logic_vector(11 downto 0);
    signal virtual_channel_id_s: std_logic_vector(2 downto 0);
    signal tm_frame_first_header_pointer_s: std_logic_vector(10 downto 0);
    signal new_frame_s: std_logic := '0';

    component decoder_buffer_and_structure is
        generic (
            TM_FRAME_SIZE_OCTET: integer := 2046;
            FECF_ENB: boolean := false
        );
        port (
            -- inputs
            data_i: std_logic_vector(7 downto 0);
            clk_i: std_logic;
            reset_i: std_logic;
            fifo_empty_i: std_logic;
            master_channel_demux_rdy_i: std_logic;

            -- outputs
            tm_frame_first_header_pointer_o: out std_logic_vector(10 downto 0);
            new_frame_o: out std_logic;
            master_channel_id_o: out std_logic_vector(11 downto 0);
            virtual_channel_id_o: out std_logic_vector(2 downto 0);
            
            space_packet_data_o: out std_logic_vector(7 downto 0);
            space_packet_data_valid_o: out std_logic;
            rdy_o: out std_logic := '0'
        );
    end component decoder_buffer_and_structure;

    -- master channel demultiplexer
    signal mc1_data_s: std_logic_vector(7 downto 0) := (others => '0');
    signal mc1_data_valid_s: std_logic := '0';
    signal mc_rdy_s: std_logic;
    signal mc1_virtual_channel_id_s: std_logic_vector(2 downto 0);
    signal mc1_new_frame_s: std_logic;
    signal mc1_first_header_pointer_s: std_logic_vector(10 downto 0);

    component master_channel_demultiplexer is
        generic (
            -- create this generic for every master channel
            MASTER_CHANNEL_1_ID: std_logic_vector(11 downto 0)
        );
        port (
            -- inputs
            data_i: in std_logic_vector(7 downto 0);
            clk_i: in std_logic;
            data_valid_i: in std_logic;
            reset_i: in std_logic;
            rdy_vc1_i: in std_logic;

            master_channel_id_i: in std_logic_vector(11 downto 0);

            virtual_channel_id_i: in std_logic_vector(2 downto 0);
            new_frame_i: in std_logic;
            first_header_pointer_i: in std_logic_vector(10 downto 0);

            -- outputs
            -- create these outputs for every master channel
            data_mc1_o: out std_logic_vector(7 downto 0);
            data_valid_mc1_o: out std_logic;
            virtual_channel_id_mc1_o: out std_logic_vector(2 downto 0);
            new_frame_mc1_o: out std_logic;
            first_header_pointer_mc1_o: out std_logic_vector(10 downto 0);
            rdy_o: out std_logic
        );

    end component master_channel_demultiplexer;

    -- virtual channel demultiplexer (master channel 1)
    signal vc1_rdy_s: std_logic := '0';
    signal data_vc1_s: std_logic_vector(7 downto 0);
    signal data_valid_vc1_s: std_logic := '0';
    signal new_frame_vc1_s: std_logic := '0';
    signal first_header_pointer_vc1_s: std_logic_vector(10 downto 0);

    component virtual_channel_demultiplexer is
        generic (
            -- create this generic for every virtual channel
            VIRTUAL_CHANNEL_1_ID: std_logic_vector(2 downto 0)
        );
        port (
            -- inputs
            data_i: in std_logic_vector(7 downto 0);
            clk_i: in std_logic;
            data_valid_i: in std_logic;
            reset_i: in std_logic;

            virtual_channel_id_i: in std_logic_vector(2 downto 0);
            new_frame_i: in std_logic;
            first_header_pointer_i: in std_logic_vector(10 downto 0);

            -- data decoder ready input
            rdy_vc1_i: in std_logic;

            -- outputs
            -- create these outputs for every virtual channel
            data_vc_1_o: out std_logic_vector(7 downto 0);
            data_valid_vc_1_o: out std_logic;
            new_frame_vc1_o: out std_logic;
            first_header_pointer_vc1_o: out std_logic_vector(10 downto 0);

            rdy_o: out std_logic
        );
    end component virtual_channel_demultiplexer;

    -- data decoder (virtual channel 1)
    signal dd_vc1_data_fully_read_s: std_logic := '0';
    signal dd_vc1_rd_o_s: std_logic := '0';
    signal dd_vc1_err_s: std_logic := '0';

    component data_decoder is
        generic (
            TM_FRAME_DATA_SIZE_OCTET: integer := 2040
        );

        port (
            -- outputs
            data_o: out std_logic_vector(31 downto 0); -- to axi stream entity
            data_valid_o: out std_logic := '0';
            data_fully_read_o: out std_logic := '0';
            rdy_o: out std_logic := '0';

            packet_header_err_o: out std_logic := '0';

            -- inputs
            data_i: in std_logic_vector(7 downto 0);
            clk_i: in std_logic; -- "8 Bit" x4 clock
            data_valid_i: in std_logic := '0';
            tm_frame_first_header_pointer_i: in std_logic_vector(10 downto 0) := (others => '0');
            new_frame_i: in std_logic := '0';
            reset_i: in std_logic
        );
    end component data_decoder;

begin

    buffer_structure: decoder_buffer_and_structure generic map (
        TM_FRAME_SIZE_OCTET => 2046,
        FECF_ENB => false
    )
    port map (
        -- inputs
        data_i => data_i,
        clk_i => gnd_clk_i,
        reset_i => reset_i,
        fifo_empty_i => fifo_empty_i,
        master_channel_demux_rdy_i => mc_rdy_s,

        -- outputs
        tm_frame_first_header_pointer_o => tm_frame_first_header_pointer_s,
        new_frame_o => new_frame_s,
        master_channel_id_o => master_channel_id_s,
        virtual_channel_id_o => virtual_channel_id_s,
        
        space_packet_data_o => space_packet_data_s,
        space_packet_data_valid_o => space_packet_data_valid_s,
        rdy_o => rdy_o
    );

    master_channel_demux: master_channel_demultiplexer generic map (
        MASTER_CHANNEL_1_ID => "000000000000"
    )
    port map (
        -- inputs
        data_i => space_packet_data_s,
        clk_i => gnd_clk_i,
        data_valid_i => space_packet_data_valid_s,
        reset_i => reset_i,
        rdy_vc1_i => vc1_rdy_s,

        master_channel_id_i => master_channel_id_s,
        virtual_channel_id_i => virtual_channel_id_s,
        new_frame_i => new_frame_s,
        first_header_pointer_i => tm_frame_first_header_pointer_s,

        -- outputs
        -- create these outputs for every master channel
        data_mc1_o => mc1_data_s,
        data_valid_mc1_o => mc1_data_valid_s,
        virtual_channel_id_mc1_o => mc1_virtual_channel_id_s,
        new_frame_mc1_o => mc1_new_frame_s,
        first_header_pointer_mc1_o => mc1_first_header_pointer_s,
        rdy_o => mc_rdy_s
    );

    virtual_channel_demux_master_channel_1: virtual_channel_demultiplexer generic map (
        VIRTUAL_CHANNEL_1_ID => "000"
    )
    port map (
        data_i => mc1_data_s,
        clk_i => gnd_clk_i,
        data_valid_i => mc1_data_valid_s,
        reset_i => reset_i,
        virtual_channel_id_i => mc1_virtual_channel_id_s,
        new_frame_i => mc1_new_frame_s,
        first_header_pointer_i => mc1_first_header_pointer_s,
        rdy_vc1_i => dd_vc1_rd_o_s,
        data_vc_1_o => data_vc1_s,
        data_valid_vc_1_o => data_valid_vc1_s,
        new_frame_vc1_o => new_frame_vc1_s,
        first_header_pointer_vc1_o => first_header_pointer_vc1_s,
        rdy_o => vc1_rdy_s
    );

    data_decoder_virtual_channel_1: data_decoder generic map (
        TM_FRAME_DATA_SIZE_OCTET => TM_FRAME_DATA_FIELD_SIZE_OCTET
    )
    port map (
        data_o => tm_data_field_vc1_o,
        data_valid_o => tm_data_field_valid_vc1_o,
        data_fully_read_o => dd_vc1_data_fully_read_s,
        rdy_o => dd_vc1_rd_o_s,
        packet_header_err_o => dd_vc1_err_s,
        data_i => data_vc1_s,
        clk_i => gnd_clk_i,
        data_valid_i => data_valid_vc1_s,
        tm_frame_first_header_pointer_i => first_header_pointer_vc1_s,
        new_frame_i => new_frame_vc1_s,
        reset_i => reset_i
    );

end architecture behavioral;