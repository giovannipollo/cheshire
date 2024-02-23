# Copyright 2024 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Florian Zaruba <zarubaf@iis.ee.ethz.ch>
# Paul Scheffler <paulsc@iis.ee.ethz.ch>

# Check argument count
if {$argc != 3} {
    puts "Error: Wrong number of cfgmem arguments (${argc}): ${argv}."
    return -code error
}

# Get arguments
set board [lindex $argv 0]
set bit   [lindex $argv 1]
set mcs   [lindex $argv 2]

switch $board {
    genesys2 {
        write_cfgmem -format mcs -interface SPIx1 -size 256  -loadbit "up 0x0 ${bit}" -file $mcs -force
    }
    vcu128 {

    }
    default {
        puts "Error: Unsupported board ${board} for MCS file generation."
        return -code error
    }
}
