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
        K : integer := 7; -- Constraint length
        G1 : integer := 8#171#; -- Generator polynomial G1 (octal)
        G2 : integer := 8#133#; -- Generator polynomial G2 (octal)
        INVERT_MASK : std_logic_vector(1 downto 0) := "10" -- Mask to invert output bits, '1' means invert. CCSDS standard uses "01" to invert the second output bit.
    );
    port (
        clk_i               : in  std_logic;
        reset_i             : in  std_logic;

        s_axis_tdata        : in std_logic_vector(0 downto 0);
        s_axis_tvalid       : in std_logic;
        s_axis_tready       : out std_logic;

        m_axis_tdata        : out std_logic_vector(0 downto 0);
        m_axis_tvalid       : out std_logic;
        m_axis_tready       : in std_logic
    );
end entity convolutional_encoder;

architecture behavioral of convolutional_encoder is

    signal fifo_data_in_r : std_logic_vector(0 downto 0) := (others => '0');
    signal fifo_data_valid_r : std_logic := '0';
    signal fifo_full_s : std_logic;
    signal ready_out_s : std_logic;

    signal internal_data_in_ready_r : std_logic := '0';

    component synchronization_fifo_axi_stream_out is
        generic (
            DATA_WIDTH : integer := 8;
            DEPTH      : integer := 16
        );
        port (
            -- Input Interface
            wr_clk_i   : in  std_logic;
            wr_en_i    : in  std_logic;
            wr_data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            full_o     : out std_logic;

            -- Output Interface
            m_axis_aclk : in  std_logic;
            m_axis_aresetn : in  std_logic;
            m_axis_tvalid : out std_logic;
            m_axis_tdata  : out std_logic_vector(DATA_WIDTH-1 downto 0);
            m_axis_tready : in  std_logic
        );
    end component synchronization_fifo_axi_stream_out;

    function calculate_parity_bit(
        shift_reg : std_logic_vector(K-1 downto 0);
        g : integer
    ) return std_logic is
        
        variable parity_bit : std_logic := '0';
        variable g_vector : std_logic_vector(K-1 downto 0);
    begin
        g_vector := std_logic_vector(to_unsigned(g, K));
        for i in 0 to K-1 loop
            if g_vector(i) = '1' then
                parity_bit := parity_bit xor shift_reg(i);
            end if;
        end loop;
        return parity_bit;
    end function calculate_parity_bit;


    -- For monitoring purposes
    signal shift_register_monitor_r : std_logic_vector(K-1 downto 0) := (others => '0');
    signal input_counter_monitor_r : integer range 0 to 1 := 0;
begin

    convolutional_out_sync_fifo : synchronization_fifo_axi_stream_out
        generic map (
            DATA_WIDTH => 1,
            DEPTH => 16
        )
        port map (
            wr_clk_i => clk_i,
            wr_en_i => fifo_data_valid_r,
            wr_data_i => fifo_data_in_r,
            full_o => fifo_full_s,

            m_axis_aclk => clk_i,
            m_axis_aresetn => reset_i,
            m_axis_tvalid => m_axis_tvalid,
            m_axis_tdata => m_axis_tdata,
            m_axis_tready => m_axis_tready
        );


    main_process : process(clk_i, reset_i)
        variable input_counter : integer range 0 to 1 := 0; -- To track input data state
        variable shift_register_r : std_logic_vector(K-1 downto 0) := (others => '0');
    begin
        if reset_i = '0' then
            shift_register_r := (others => '0');
            input_counter := 0;
            internal_data_in_ready_r <= '1';
        elsif rising_edge(clk_i) then
            -- Only process input every second clock cycle
            if input_counter = 0 then
                if s_axis_tvalid = '1' then
                    fifo_data_valid_r <= '1';
                    if ready_out_s = '1' then
                        shift_register_r := s_axis_tdata(0) & shift_register_r(K-1 downto 1);
                        shift_register_monitor_r <= shift_register_r;
                        internal_data_in_ready_r <= '0';
                        input_counter := 1; 
                        input_counter_monitor_r <= input_counter;
                        fifo_data_in_r(0) <= calculate_parity_bit(shift_register_r, G1) xor INVERT_MASK(0);
                    end if;
                else
                    fifo_data_valid_r <= '0';
                end if;
            else
                fifo_data_valid_r <= '1';
                if fifo_full_s = '0' then
                    internal_data_in_ready_r <= '1';
                    input_counter := 0;
                    input_counter_monitor_r <= input_counter;
                    fifo_data_in_r(0) <= calculate_parity_bit(shift_register_r, G2) xor INVERT_MASK(1);
                end if;
            end if;
        end if;
    end process main_process;

    ready_out_s <= internal_data_in_ready_r and not fifo_full_s;
    s_axis_tready <= ready_out_s;

end architecture behavioral;
