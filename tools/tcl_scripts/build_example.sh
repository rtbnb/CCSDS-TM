# tools/tcl_scripts/build.sh

VIVADO=${VIVADO:-vivado}
$VIVADO -mode batch -source ./tools/tcl_scripts/build_example.tcl -tclargs $@