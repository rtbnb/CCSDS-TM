
################################################################
# This is a generated script based on design: system_integration
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2025.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source system_integration_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# virtual_channel_buffer, transfer_frame_encoder, decoder_buffer_and_structure, ccsds_131_ground, ccsds_131_space, synchronization_fifo, synchronization_fifo, empty_to_valid

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z020clg400-1
   set_property BOARD_PART tul.com.tw:pynq-z2:part0:1.0 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name system_integration

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
virtual_channel_buffer\
transfer_frame_encoder\
decoder_buffer_and_structure\
ccsds_131_ground\
ccsds_131_space\
synchronization_fifo\
synchronization_fifo\
empty_to_valid\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports

  # Create ports
  set data_valid_i_0 [ create_bd_port -dir I data_valid_i_0 ]
  set clk_i_0 [ create_bd_port -dir I clk_i_0 ]
  set reset_i_0 [ create_bd_port -dir I -type rst reset_i_0 ]
  set data_i_0 [ create_bd_port -dir I -from 7 -to 0 data_i_0 ]
  set ready_o_0 [ create_bd_port -dir O ready_o_0 ]
  set transfer_frame_version_number_i_0 [ create_bd_port -dir I -from 1 -to 0 transfer_frame_version_number_i_0 ]
  set spacecraft_id_i_0 [ create_bd_port -dir I -from 9 -to 0 spacecraft_id_i_0 ]
  set tm_data_field_o_0 [ create_bd_port -dir O -from 31 -to 0 tm_data_field_o_0 ]
  set tm_data_field_valid_o_0 [ create_bd_port -dir O tm_data_field_valid_o_0 ]
  set ground_clk_i_1 [ create_bd_port -dir I ground_clk_i_1 ]

  # Create instance: virtual_channel_buff_0, and set properties
  set block_name virtual_channel_buffer
  set block_cell_name virtual_channel_buff_0
  if { [catch {set virtual_channel_buff_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $virtual_channel_buff_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: transfer_frame_encod_0, and set properties
  set block_name transfer_frame_encoder
  set block_cell_name transfer_frame_encod_0
  if { [catch {set transfer_frame_encod_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $transfer_frame_encod_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: decoder_buffer_and_s_0, and set properties
  set block_name decoder_buffer_and_structure
  set block_cell_name decoder_buffer_and_s_0
  if { [catch {set decoder_buffer_and_s_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $decoder_buffer_and_s_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: ccsds_131_ground_0, and set properties
  set block_name ccsds_131_ground
  set block_cell_name ccsds_131_ground_0
  if { [catch {set ccsds_131_ground_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ccsds_131_ground_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: ccsds_131_space_0, and set properties
  set block_name ccsds_131_space
  set block_cell_name ccsds_131_space_0
  if { [catch {set ccsds_131_space_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ccsds_131_space_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: synchronization_fifo_0, and set properties
  set block_name synchronization_fifo
  set block_cell_name synchronization_fifo_0
  if { [catch {set synchronization_fifo_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $synchronization_fifo_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: synchronization_fifo_1, and set properties
  set block_name synchronization_fifo
  set block_cell_name synchronization_fifo_1
  if { [catch {set synchronization_fifo_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $synchronization_fifo_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: empty_to_valid_0, and set properties
  set block_name empty_to_valid
  set block_cell_name empty_to_valid_0
  if { [catch {set empty_to_valid_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $empty_to_valid_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create port connections
  connect_bd_net -net ccsds_131_ground_0_data_valid_o  [get_bd_pins ccsds_131_ground_0/data_valid_o] \
  [get_bd_pins synchronization_fifo_1/wr_en_i]
  connect_bd_net -net ccsds_131_ground_0_output_byte_o  [get_bd_pins ccsds_131_ground_0/output_byte_o] \
  [get_bd_pins synchronization_fifo_1/wr_data_i]
  connect_bd_net -net ccsds_131_space_0_data_o  [get_bd_pins ccsds_131_space_0/data_o] \
  [get_bd_pins ccsds_131_ground_0/data_i]
  connect_bd_net -net ccsds_131_space_0_data_valid_o  [get_bd_pins ccsds_131_space_0/data_valid_o] \
  [get_bd_pins ccsds_131_ground_0/data_valid_i]
  connect_bd_net -net ccsds_131_space_0_read_data_fifo_o  [get_bd_pins ccsds_131_space_0/read_data_fifo_o] \
  [get_bd_pins synchronization_fifo_0/rd_en_i]
  connect_bd_net -net clk_i_0_1  [get_bd_ports clk_i_0] \
  [get_bd_pins ccsds_131_space_0/clk_i] \
  [get_bd_pins synchronization_fifo_0/wr_clk_i] \
  [get_bd_pins synchronization_fifo_0/rd_clk_i] \
  [get_bd_pins transfer_frame_encod_0/clk_i] \
  [get_bd_pins virtual_channel_buff_0/clk_i]
  connect_bd_net -net clk_i_1_1  [get_bd_ports ground_clk_i_1] \
  [get_bd_pins ccsds_131_ground_0/clk_i] \
  [get_bd_pins empty_to_valid_0/clk_i] \
  [get_bd_pins synchronization_fifo_1/wr_clk_i] \
  [get_bd_pins synchronization_fifo_1/rd_clk_i] \
  [get_bd_pins decoder_buffer_and_s_0/clk_i]
  connect_bd_net -net data_i_0_1  [get_bd_ports data_i_0] \
  [get_bd_pins virtual_channel_buff_0/data_i]
  connect_bd_net -net data_valid_i_0_1  [get_bd_ports data_valid_i_0] \
  [get_bd_pins virtual_channel_buff_0/data_valid_i]
  connect_bd_net -net decoder_buffer_and_s_0_tm_data_field_o  [get_bd_pins decoder_buffer_and_s_0/tm_data_field_o] \
  [get_bd_ports tm_data_field_o_0]
  connect_bd_net -net decoder_buffer_and_s_0_tm_data_field_valid_o  [get_bd_pins decoder_buffer_and_s_0/tm_data_field_valid_o] \
  [get_bd_ports tm_data_field_valid_o_0]
  connect_bd_net -net empty_to_valid_0_data_valid_o  [get_bd_pins empty_to_valid_0/data_valid_o] \
  [get_bd_pins decoder_buffer_and_s_0/data_valid_i]
  connect_bd_net -net empty_to_valid_0_rd_enb_o  [get_bd_pins empty_to_valid_0/rd_enb_o] \
  [get_bd_pins synchronization_fifo_1/rd_en_i]
  connect_bd_net -net reset_i_0_1  [get_bd_ports reset_i_0] \
  [get_bd_pins ccsds_131_ground_0/reset_i] \
  [get_bd_pins ccsds_131_space_0/reset_i] \
  [get_bd_pins transfer_frame_encod_0/reset_i] \
  [get_bd_pins virtual_channel_buff_0/reset_i] \
  [get_bd_pins decoder_buffer_and_s_0/reset_i]
  connect_bd_net -net spacecraft_id_i_0_1  [get_bd_ports spacecraft_id_i_0] \
  [get_bd_pins transfer_frame_encod_0/spacecraft_id_i]
  connect_bd_net -net synchronization_fifo_0_empty_o  [get_bd_pins synchronization_fifo_0/empty_o] \
  [get_bd_pins ccsds_131_space_0/fifo_empty_i]
  connect_bd_net -net synchronization_fifo_0_full_o  [get_bd_pins synchronization_fifo_0/full_o] \
  [get_bd_pins transfer_frame_encod_0/out_full_i]
  connect_bd_net -net synchronization_fifo_0_rd_data_o  [get_bd_pins synchronization_fifo_0/rd_data_o] \
  [get_bd_pins ccsds_131_space_0/input_byte_i]
  connect_bd_net -net synchronization_fifo_1_empty_o  [get_bd_pins synchronization_fifo_1/empty_o] \
  [get_bd_pins empty_to_valid_0/empty_i]
  connect_bd_net -net synchronization_fifo_1_rd_data_o  [get_bd_pins synchronization_fifo_1/rd_data_o] \
  [get_bd_pins decoder_buffer_and_s_0/data_i]
  connect_bd_net -net transfer_frame_encod_0_data_o  [get_bd_pins transfer_frame_encod_0/data_o] \
  [get_bd_pins synchronization_fifo_0/wr_data_i]
  connect_bd_net -net transfer_frame_encod_0_out_en_o  [get_bd_pins transfer_frame_encod_0/out_en_o] \
  [get_bd_pins synchronization_fifo_0/wr_en_i]
  connect_bd_net -net transfer_frame_encod_0_vch0_data_en_o  [get_bd_pins transfer_frame_encod_0/vch0_data_en_o] \
  [get_bd_pins virtual_channel_buff_0/data_out_en_i]
  connect_bd_net -net transfer_frame_version_number_i_0_1  [get_bd_ports transfer_frame_version_number_i_0] \
  [get_bd_pins transfer_frame_encod_0/transfer_frame_version_number_i]
  connect_bd_net -net virtual_channel_buff_0_data_o  [get_bd_pins virtual_channel_buff_0/data_o] \
  [get_bd_pins transfer_frame_encod_0/vch0_data_i]
  connect_bd_net -net virtual_channel_buff_0_frame_ready_o  [get_bd_pins virtual_channel_buff_0/frame_ready_o] \
  [get_bd_pins transfer_frame_encod_0/vch0_frame_ready_i]
  connect_bd_net -net virtual_channel_buff_0_ready_o  [get_bd_pins virtual_channel_buff_0/ready_o] \
  [get_bd_ports ready_o_0]
  connect_bd_net -net virtual_channel_buff_0_virtual_channel_frame_count_o  [get_bd_pins virtual_channel_buff_0/virtual_channel_frame_count_o] \
  [get_bd_pins transfer_frame_encod_0/vch0_virtual_channel_frame_count_i]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


