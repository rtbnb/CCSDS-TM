# build.tcl
source [file normalize [file join [file dirname [info script]] create_project.tcl]]

# set the device/part (create in-memory project)
set PART xc7a200tfbg484-1
set_part $PART

# specify top (or use set_property top ... on a file)
set TOP top_level


# --- BUILD DIR (create and switch into it) ---
set BUILD_DIR [file normalize [file join $PROJ_ROOT build]]
if {![file exists $BUILD_DIR]} {
    if {[catch {file mkdir $BUILD_DIR} err]} {
        puts "ERROR: failed to create build dir $BUILD_DIR -> $err"
        error "mkdir failed"
    }
}
# change CWD so Vivado writes .Xil, .runs, default outputs into build/
cd $BUILD_DIR

# helper to create dirname of a file path (safe)
proc ensure_parent_dir {f} {
    set d [file dirname $f]
    if {![file exists $d]} {
        if {[catch {file mkdir $d} err]} {
            puts "ERROR: could not create directory $d -> $err"
            return -code error "mkdir failed"
        }
    }
}

# --- SYNTHESIS ---
synth_design -top $TOP -part $PART -verbose
# write a post-synthesis checkpoint and a synth netlist
set SYN_DCP [file normalize [file join $BUILD_DIR ${TOP}_synth.dcp]]
set SYN_V    [file normalize [file join $BUILD_DIR ${TOP}_synth.v]]
ensure_parent_dir $SYN_DCP
write_checkpoint -force $SYN_DCP
#write_verilog -force -mode synth $SYN_V

# optional: capture optimized netlist after opt_design
opt_design
set OPT_DCP [file normalize [file join $BUILD_DIR ${TOP}_opt.dcp]]
write_checkpoint -force $OPT_DCP

# --- IMPLEMENTATION ---
place_design
# checkpoint after placement
set PLACED_DCP [file normalize [file join $BUILD_DIR ${TOP}_placed.dcp]]
write_checkpoint -force $PLACED_DCP

route_design
# checkpoint after routing
set ROUTED_DCP [file normalize [file join $BUILD_DIR ${TOP}_routed.dcp]]
write_checkpoint -force $ROUTED_DCP

# write SDF and a post-implementation Verilog (with SDF annotated)
set SDF_FILE [file normalize [file join $BUILD_DIR ${TOP}.sdf]]
write_sdf -force -mode timesim $SDF_FILE

set POST_IMPL_V [file normalize [file join $BUILD_DIR ${TOP}_post_impl.v]]
write_verilog -force -mode design -sdf_anno true -sdf_file $SDF_FILE $POST_IMPL_V

# finally write bitstream (ensure dir exists)
set BIT_FILE [file normalize [file join $BUILD_DIR ${TOP}.bit]]
ensure_parent_dir $BIT_FILE
write_bitstream -force -file $BIT_FILE

puts "Build finished -- bitstream in $BIT_FILE"