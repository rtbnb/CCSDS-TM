@echo off
set VIVADO=vivado.bat
%VIVADO% -mode batch -source ./tools/tcl_scripts/build.tcl -tclargs %*