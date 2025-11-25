// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.1 (win64) Build 6140274 Thu May 22 00:12:29 MDT 2025
// Date        : Tue Nov 25 16:57:57 2025
// Host        : BOOK-69BD3QPCMV running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode design -sdf_anno true -sdf_file
//               C:/Development/VHDL/CCSDS-TM/build/top_level.sdf C:/Development/VHDL/CCSDS-TM/build/top_level_post_impl.v
// Design      : top_level
// Purpose     : This is a Verilog netlist of the current design or from a specific cell of the design. The output is an
//               IEEE 1364-2001 compliant Verilog HDL file that contains netlist information obtained from the input
//               design files.
// Device      : xc7a200tfbg484-1
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* ECO_CHECKSUM = "93281a2b" *) 
(* STRUCTURAL_NETLIST = "yes" *)
module top_level
   (In1,
    In2,
    Out1);
  input In1;
  input In2;
  output Out1;

  wire In1;
  wire In1_IBUF;
  wire In2;
  wire In2_IBUF;
  wire Out1;
  wire Out1_OBUF;

  IBUF In1_IBUF_inst
       (.I(In1),
        .O(In1_IBUF));
  IBUF In2_IBUF_inst
       (.I(In2),
        .O(In2_IBUF));
  OBUF Out1_OBUF_inst
       (.I(Out1_OBUF),
        .O(Out1));
  LUT2 #(
    .INIT(4'h8)) 
    Out1_OBUF_inst_i_1
       (.I0(In1_IBUF),
        .I1(In2_IBUF),
        .O(Out1_OBUF));
endmodule
