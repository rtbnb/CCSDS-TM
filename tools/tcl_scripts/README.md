# VHDL Build Tooling

These TCL scripts are meant for generating a bitstream from VHDL files.

## Prerequesites

Vivado needs to be installed a such a way, that the command `vivado` (Linux) or `vivado.bat` (Windows) are available from the command line. This typically involves the vivado binary folder being added to `PATH`.

All paths mentioned here will be relative to the repository root directory.

The VHDL source files are expected in `./src/`.

A `sources.txt` file is expected in `./src/`, where all source files need to be listed explicitely. The supplied files are interpreted as relative to the `sources.txt` file.

The build process assumes the top level entity to be called `top_level`. This may be changed in the `build.tcl` script, by setting the variable `TOP` to something different.

## Usage

Call the respective script (`./tools/tcl_scripts/build.sh` for Linux or `./tools/tcl_scripts/build.bat` for Windows) from the project root directory.

This will start a synthesis and implementation run, with checkpoints being written into `./build/`. If these steps complete without error, a bitstream will be written to `./build/top_level.bit` (The name depends on the top_level entity's name).

### Building example
1. cd into repository root
2. on Windows execute .\tools\tcl_scripts\build_example.bat
3. on Linux execute .\tools\tcl_scripts\build_example.sh

### Getting Started with Vivado
1. Create Post-Synthesis Project
2. Add build/example/top_level_synth.dcp to Sources
3. Add Simulation file from example/src/sim/top_sim.vhd
4. Run Simulation and select top_sim as sim file
5. Verify, that in the first 10ns Out1 is 0 and after 10ns Out1 is 1