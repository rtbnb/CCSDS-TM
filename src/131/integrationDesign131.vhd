--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
--Date        : Mon Apr 27 20:28:47 2026
--Host        : DESKTOP-GRQ86LT running 64-bit major release  (build 9200)
--Command     : generate_target integrationDesign.bd
--Design      : integrationDesign
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity integrationDesign is
  port (
    empty_o_0 : out STD_LOGIC;
    fifo_rd_en : in STD_LOGIC;
    full_o_0 : out STD_LOGIC;
    ground_clk : in STD_LOGIC;
    rd_data_o_0 : out STD_LOGIC_VECTOR ( 7 downto 0 );
    reset_i_0 : in STD_LOGIC;
    space_clk : in STD_LOGIC;
    wr_data_i_0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    wr_en_i_0 : in STD_LOGIC
  );
  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of integrationDesign : entity is "integrationDesign,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=integrationDesign,x_ipVersion=1.00.a,x_ipLanguage=VHDL,numBlks=14,numReposBlks=14,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=12,numPkgbdBlks=0,bdsource=USER,synth_mode=Hierarchical}";
  attribute HW_HANDOFF : string;
  attribute HW_HANDOFF of integrationDesign : entity is "integrationDesign.hwdef";
end integrationDesign;

architecture STRUCTURE of integrationDesign is
  component integrationDesign_synchronization_fifo_0_0 is
  port (
    wr_clk_i : in STD_LOGIC;
    wr_en_i : in STD_LOGIC;
    wr_data_i : in STD_LOGIC_VECTOR ( 7 downto 0 );
    full_o : out STD_LOGIC;
    rd_clk_i : in STD_LOGIC;
    rd_en_i : in STD_LOGIC;
    rd_data_o : out STD_LOGIC_VECTOR ( 7 downto 0 );
    empty_o : out STD_LOGIC
  );
  end component integrationDesign_synchronization_fifo_0_0;
  component integrationDesign_reed_solomon_encoder_0_0 is
  port (
    clk_i : in STD_LOGIC;
    reset_i : in STD_LOGIC;
    input_byte_i : in STD_LOGIC_VECTOR ( 7 downto 0 );
    fifo_empty_i : in STD_LOGIC;
    output_byte_o : out STD_LOGIC_VECTOR ( 7 downto 0 );
    encoder_done_flag_o : out STD_LOGIC;
    data_valid_o : out STD_LOGIC;
    read_data_fifo_o : out STD_LOGIC
  );
  end component integrationDesign_reed_solomon_encoder_0_0;
  component integrationDesign_width_converter_8_to_0_0 is
  port (
    clk_i : in STD_LOGIC;
    reset_i : in STD_LOGIC;
    input_byte_i : in STD_LOGIC_VECTOR ( 7 downto 0 );
    data_valid_i : in STD_LOGIC;
    encoder_done_i : in STD_LOGIC;
    output_bit_o : out STD_LOGIC;
    data_valid_o : out STD_LOGIC;
    encoder_done_o : out STD_LOGIC
  );
  end component integrationDesign_width_converter_8_to_0_0;
  component integrationDesign_pseudo_randomizer_0_0 is
  port (
    clk_i : in STD_LOGIC;
    reset_i : in STD_LOGIC;
    data_valid_i : in STD_LOGIC;
    encoder_done_i : in STD_LOGIC;
    data_i : in STD_LOGIC;
    data_o : out STD_LOGIC;
    data_valid_o : out STD_LOGIC;
    encoder_done_o : out STD_LOGIC
  );
  end component integrationDesign_pseudo_randomizer_0_0;
  component integrationDesign_asm_encoder_0_0 is
  port (
    clk_i : in STD_LOGIC;
    reset_i : in STD_LOGIC;
    data_i : in STD_LOGIC;
    encoder_done_i : in STD_LOGIC;
    data_valid_i : in STD_LOGIC;
    data_o : out STD_LOGIC;
    data_valid_o : out STD_LOGIC
  );
  end component integrationDesign_asm_encoder_0_0;
  component integrationDesign_stub_convolutional_e_0_0 is
  port (
    clk_i : in STD_LOGIC;
    reset_i : in STD_LOGIC;
    data_in_i : in STD_LOGIC;
    data_in_ready_i : in STD_LOGIC;
    data_out_o : out STD_LOGIC;
    data_out_ready_o : out STD_LOGIC
  );
  end component integrationDesign_stub_convolutional_e_0_0;
  component integrationDesign_stub_convolutional_d_0_0 is
  port (
    clk_i : in STD_LOGIC;
    reset_i : in STD_LOGIC;
    data_in_i : in STD_LOGIC;
    data_in_ready_i : in STD_LOGIC;
    data_out_o : out STD_LOGIC;
    data_out_ready_o : out STD_LOGIC
  );
  end component integrationDesign_stub_convolutional_d_0_0;
  component integrationDesign_asm_decoder_0_0 is
  port (
    clk_i : in STD_LOGIC;
    reset_i : in STD_LOGIC;
    data_i : in STD_LOGIC;
    data_valid_i : in STD_LOGIC;
    data_o : out STD_LOGIC;
    data_valid_o : out STD_LOGIC;
    decoder_done_o : out STD_LOGIC
  );
  end component integrationDesign_asm_decoder_0_0;
  component integrationDesign_reed_solomon_decoder_0_0 is
  port (
    clk_i : in STD_LOGIC;
    reset_i : in STD_LOGIC;
    input_byte_i : in STD_LOGIC_VECTOR ( 7 downto 0 );
    data_valid_i : in STD_LOGIC;
    data_valid_o : out STD_LOGIC;
    output_byte_o : out STD_LOGIC_VECTOR ( 7 downto 0 )
  );
  end component integrationDesign_reed_solomon_decoder_0_0;
  component integrationDesign_pseudo_randomizer_1_0 is
  port (
    clk_i : in STD_LOGIC;
    reset_i : in STD_LOGIC;
    data_valid_i : in STD_LOGIC;
    encoder_done_i : in STD_LOGIC;
    data_i : in STD_LOGIC;
    data_o : out STD_LOGIC;
    data_valid_o : out STD_LOGIC;
    encoder_done_o : out STD_LOGIC
  );
  end component integrationDesign_pseudo_randomizer_1_0;
  component integrationDesign_width_converter_1_to_0_0 is
  port (
    clk_i : in STD_LOGIC;
    reset_i : in STD_LOGIC;
    input_bit_i : in STD_LOGIC;
    data_valid_i : in STD_LOGIC;
    output_byte_o : out STD_LOGIC_VECTOR ( 7 downto 0 );
    data_valid_o : out STD_LOGIC
  );
  end component integrationDesign_width_converter_1_to_0_0;
  component integrationDesign_synchronization_fifo_1_0 is
  port (
    wr_clk_i : in STD_LOGIC;
    wr_en_i : in STD_LOGIC;
    wr_data_i : in STD_LOGIC_VECTOR ( 7 downto 0 );
    full_o : out STD_LOGIC;
    rd_clk_i : in STD_LOGIC;
    rd_en_i : in STD_LOGIC;
    rd_data_o : out STD_LOGIC_VECTOR ( 7 downto 0 );
    empty_o : out STD_LOGIC
  );
  end component integrationDesign_synchronization_fifo_1_0;
  component integrationDesign_util_vector_logic_0_0 is
  port (
    Op1 : in STD_LOGIC_VECTOR ( 0 to 0 );
    Res : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
  end component integrationDesign_util_vector_logic_0_0;
  component integrationDesign_util_vector_logic_1_0 is
  port (
    Op1 : in STD_LOGIC_VECTOR ( 0 to 0 );
    Op2 : in STD_LOGIC_VECTOR ( 0 to 0 );
    Res : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
  end component integrationDesign_util_vector_logic_1_0;
  signal asm_decoder_0_data_o : STD_LOGIC;
  signal asm_decoder_0_data_valid_o : STD_LOGIC;
  signal asm_decoder_0_decoder_done_o : STD_LOGIC;
  signal asm_encoder_0_data_o : STD_LOGIC;
  signal asm_encoder_0_data_valid_o : STD_LOGIC;
  signal pseudo_randomizer_0_data_o : STD_LOGIC;
  signal pseudo_randomizer_0_data_valid_o : STD_LOGIC;
  signal pseudo_randomizer_0_encoder_done_o : STD_LOGIC;
  signal pseudo_randomizer_1_data_o : STD_LOGIC;
  signal pseudo_randomizer_1_data_valid_o : STD_LOGIC;
  signal pseudo_randomizer_1_encoder_done_o : STD_LOGIC;
  signal reed_solomon_decoder_0_data_valid_o : STD_LOGIC;
  signal reed_solomon_decoder_0_output_byte_o : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal reed_solomon_encoder_0_data_valid_o : STD_LOGIC;
  signal reed_solomon_encoder_0_encoder_done_flag_o : STD_LOGIC;
  signal reed_solomon_encoder_0_output_byte_o : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal reed_solomon_encoder_0_read_data_fifo_o : STD_LOGIC;
  signal stub_convolutional_d_0_data_out_o : STD_LOGIC;
  signal stub_convolutional_d_0_data_out_ready_o : STD_LOGIC;
  signal stub_convolutional_e_0_data_out_o : STD_LOGIC;
  signal stub_convolutional_e_0_data_out_ready_o : STD_LOGIC;
  signal synchronization_fifo_0_empty_o : STD_LOGIC;
  signal synchronization_fifo_0_rd_data_o : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal util_vector_logic_0_Res : STD_LOGIC_VECTOR ( 0 to 0 );
  signal util_vector_logic_1_Res : STD_LOGIC_VECTOR ( 0 to 0 );
  signal width_converter_1_to_0_data_valid_o : STD_LOGIC;
  signal width_converter_1_to_0_output_byte_o : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal width_converter_8_to_0_data_valid_o : STD_LOGIC;
  signal width_converter_8_to_0_encoder_done_o : STD_LOGIC;
  signal width_converter_8_to_0_output_bit_o : STD_LOGIC;
  signal NLW_synchronization_fifo_0_full_o_UNCONNECTED : STD_LOGIC;
  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_INFO of reset_i_0 : signal is "xilinx.com:signal:reset:1.0 RST.RESET_I_0 RST";
  attribute X_INTERFACE_PARAMETER : string;
  attribute X_INTERFACE_PARAMETER of reset_i_0 : signal is "XIL_INTERFACENAME RST.RESET_I_0, INSERT_VIP 0, POLARITY ACTIVE_LOW";
begin
asm_decoder_0: component integrationDesign_asm_decoder_0_0
     port map (
      clk_i => ground_clk,
      data_i => stub_convolutional_d_0_data_out_o,
      data_o => asm_decoder_0_data_o,
      data_valid_i => stub_convolutional_d_0_data_out_ready_o,
      data_valid_o => asm_decoder_0_data_valid_o,
      decoder_done_o => asm_decoder_0_decoder_done_o,
      reset_i => reset_i_0
    );
asm_encoder_0: component integrationDesign_asm_encoder_0_0
     port map (
      clk_i => space_clk,
      data_i => pseudo_randomizer_0_data_o,
      data_o => asm_encoder_0_data_o,
      data_valid_i => pseudo_randomizer_0_data_valid_o,
      data_valid_o => asm_encoder_0_data_valid_o,
      encoder_done_i => pseudo_randomizer_0_encoder_done_o,
      reset_i => reset_i_0
    );
pseudo_randomizer_0: component integrationDesign_pseudo_randomizer_0_0
     port map (
      clk_i => space_clk,
      data_i => width_converter_8_to_0_output_bit_o,
      data_o => pseudo_randomizer_0_data_o,
      data_valid_i => width_converter_8_to_0_data_valid_o,
      data_valid_o => pseudo_randomizer_0_data_valid_o,
      encoder_done_i => width_converter_8_to_0_encoder_done_o,
      encoder_done_o => pseudo_randomizer_0_encoder_done_o,
      reset_i => reset_i_0
    );
pseudo_randomizer_1: component integrationDesign_pseudo_randomizer_1_0
     port map (
      clk_i => ground_clk,
      data_i => asm_decoder_0_data_o,
      data_o => pseudo_randomizer_1_data_o,
      data_valid_i => asm_decoder_0_data_valid_o,
      data_valid_o => pseudo_randomizer_1_data_valid_o,
      encoder_done_i => asm_decoder_0_decoder_done_o,
      encoder_done_o => pseudo_randomizer_1_encoder_done_o,
      reset_i => reset_i_0
    );
reed_solomon_decoder_0: component integrationDesign_reed_solomon_decoder_0_0
     port map (
      clk_i => ground_clk,
      data_valid_i => width_converter_1_to_0_data_valid_o,
      data_valid_o => reed_solomon_decoder_0_data_valid_o,
      input_byte_i(7 downto 0) => width_converter_1_to_0_output_byte_o(7 downto 0),
      output_byte_o(7 downto 0) => reed_solomon_decoder_0_output_byte_o(7 downto 0),
      reset_i => reset_i_0
    );
reed_solomon_encoder_0: component integrationDesign_reed_solomon_encoder_0_0
     port map (
      clk_i => space_clk,
      data_valid_o => reed_solomon_encoder_0_data_valid_o,
      encoder_done_flag_o => reed_solomon_encoder_0_encoder_done_flag_o,
      fifo_empty_i => synchronization_fifo_0_empty_o,
      input_byte_i(7 downto 0) => synchronization_fifo_0_rd_data_o(7 downto 0),
      output_byte_o(7 downto 0) => reed_solomon_encoder_0_output_byte_o(7 downto 0),
      read_data_fifo_o => reed_solomon_encoder_0_read_data_fifo_o,
      reset_i => reset_i_0
    );
stub_convolutional_d_0: component integrationDesign_stub_convolutional_d_0_0
     port map (
      clk_i => ground_clk,
      data_in_i => stub_convolutional_e_0_data_out_o,
      data_in_ready_i => stub_convolutional_e_0_data_out_ready_o,
      data_out_o => stub_convolutional_d_0_data_out_o,
      data_out_ready_o => stub_convolutional_d_0_data_out_ready_o,
      reset_i => reset_i_0
    );
stub_convolutional_e_0: component integrationDesign_stub_convolutional_e_0_0
     port map (
      clk_i => space_clk,
      data_in_i => asm_encoder_0_data_o,
      data_in_ready_i => asm_encoder_0_data_valid_o,
      data_out_o => stub_convolutional_e_0_data_out_o,
      data_out_ready_o => stub_convolutional_e_0_data_out_ready_o,
      reset_i => reset_i_0
    );
synchronization_fifo_0: component integrationDesign_synchronization_fifo_0_0
     port map (
      empty_o => synchronization_fifo_0_empty_o,
      full_o => NLW_synchronization_fifo_0_full_o_UNCONNECTED,
      rd_clk_i => space_clk,
      rd_data_o(7 downto 0) => synchronization_fifo_0_rd_data_o(7 downto 0),
      rd_en_i => reed_solomon_encoder_0_read_data_fifo_o,
      wr_clk_i => space_clk,
      wr_data_i(7 downto 0) => wr_data_i_0(7 downto 0),
      wr_en_i => wr_en_i_0
    );
synchronization_fifo_1: component integrationDesign_synchronization_fifo_1_0
     port map (
      empty_o => empty_o_0,
      full_o => full_o_0,
      rd_clk_i => ground_clk,
      rd_data_o(7 downto 0) => rd_data_o_0(7 downto 0),
      rd_en_i => fifo_rd_en,
      wr_clk_i => ground_clk,
      wr_data_i(7 downto 0) => reed_solomon_decoder_0_output_byte_o(7 downto 0),
      wr_en_i => reed_solomon_decoder_0_data_valid_o
    );
util_vector_logic_0: component integrationDesign_util_vector_logic_0_0
     port map (
      Op1(0) => pseudo_randomizer_1_encoder_done_o,
      Res(0) => util_vector_logic_0_Res(0)
    );
util_vector_logic_1: component integrationDesign_util_vector_logic_1_0
     port map (
      Op1(0) => pseudo_randomizer_1_data_valid_o,
      Op2(0) => util_vector_logic_0_Res(0),
      Res(0) => util_vector_logic_1_Res(0)
    );
width_converter_1_to_0: component integrationDesign_width_converter_1_to_0_0
     port map (
      clk_i => ground_clk,
      data_valid_i => util_vector_logic_1_Res(0),
      data_valid_o => width_converter_1_to_0_data_valid_o,
      input_bit_i => pseudo_randomizer_1_data_o,
      output_byte_o(7 downto 0) => width_converter_1_to_0_output_byte_o(7 downto 0),
      reset_i => reset_i_0
    );
width_converter_8_to_0: component integrationDesign_width_converter_8_to_0_0
     port map (
      clk_i => space_clk,
      data_valid_i => reed_solomon_encoder_0_data_valid_o,
      data_valid_o => width_converter_8_to_0_data_valid_o,
      encoder_done_i => reed_solomon_encoder_0_encoder_done_flag_o,
      encoder_done_o => width_converter_8_to_0_encoder_done_o,
      input_byte_i(7 downto 0) => reed_solomon_encoder_0_output_byte_o(7 downto 0),
      output_bit_o => width_converter_8_to_0_output_bit_o,
      reset_i => reset_i_0
    );
end STRUCTURE;
