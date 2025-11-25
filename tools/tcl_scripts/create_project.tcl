# create_project.tcl


proc get_root {} {
    if {[info script] ne ""} {
        return [file normalize [file join [file dirname [info script]] .. ..]]
    } else {
        return [file normalize [pwd]]
    }
}
set PROJ_ROOT [get_root]
puts "PROJECT ROOT: $PROJ_ROOT"

# read a simple file list (sources.txt) with relative paths (one per line)
set sources_file [file join $PROJ_ROOT src/sources.txt]
if {![file exists $sources_file]} {
    puts "ERROR: sources.txt not found at $sources_file"
    error "sources.txt missing"
}
set fh [open $sources_file r]
set lines [split [read $fh] "\n"]
close $fh

foreach l $lines {
    set f [string trim $l]
    if {$f eq ""} continue
    set full [file normalize [file join $PROJ_ROOT src $f]]
    if {[file exists $full]} {
        puts "Adding source file: $full"
        add_files $full
    } else {
        error "File not found: $full"
    }
}

# add constraints
if {[file exists [file join $PROJ_ROOT constraints/top.xdc]]} {
    add_files [file normalize [file join $PROJ_ROOT constraints/top.xdc]] -fileset constrs_1
}

# register local IP repo (if you have custom IP in repo/ip)
if {[file exists [file join $PROJ_ROOT ip]]} {
    set_property IP_REPO_PATHS [file normalize [file join $PROJ_ROOT ip]] [current_fileset]
    update_ip_catalog
}

# if your design uses IP integrator BD, read it (bd/my_bd.bd)
if {[file exists [file join $PROJ_ROOT bd/my_bd.bd]]} {
    read_bd [file normalize [file join $PROJ_ROOT bd/my_bd.bd]]
} else {
    puts "No block design to read"
}