# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Nicole Narr <narrn@student.ethz.ch>
# Christopher Reinwardt <creinwar@student.ethz.ch>
# Cyril Koenig <cykoenig@iis.ee.ethz.ch>
# Paul Scheffler <paulsc@iis.ee.ethz.ch>

VIVADO ?= vitis-2022.1 vivado

CHS_XILINX_DIR ?= $(CHS_ROOT)/target/xilinx

# Required to split stems
.SECONDEXPANSION:

##############
# Xilinx IPs #
##############

.PRECIOUS: $(CHS_XILINX_DIR)/build/%/ $(CHS_XILINX_DIR)/build/%/out.xci

$(CHS_XILINX_DIR)/build/%/:
	mkdir -p $@

# We split the stem into a board and an IP and resolve dependencies accordingly
$(CHS_XILINX_DIR)/build/%/out.xci: \
		$(CHS_XILINX_DIR)/scripts/impl_ip.tcl \
		$$(wildcard $(CHS_XILINX_DIR)/src/ips/$$*.prj) \
		| $(CHS_XILINX_DIR)/build/%/
	@rm -f $(CHS_XILINX_DIR)/build/%.log $(CHS_XILINX_DIR)/build/%.jou
	cd $| && $(VIVADO) -mode batch -log ../$*.log -jou ../$*.jou -source $< -tclargs "$(subst ., ,$*)"

##############
# Bitstreams #
##############

CHS_XILINX_BOARDS := genesys2 vcu128

CHS_XILINX_IPS_genesys2 := clkwiz vio mig7s
CHS_XILINX_IPS_vcu128   := clkwiz vio ddr4

$(CHS_XILINX_DIR)/scripts/add_sources.%.tcl: $(CHS_ROOT)/Bender.yml
	$(BENDER) script vivado -t fpga -t cv64a6_imafdcsclic_sv39 -t cva6 -t $* > $@

define chs_xilinx_bit_rule
$$(CHS_XILINX_DIR)/out/%.$(1).bit: \
		$$(CHS_XILINX_DIR)/scripts/impl_sys.tcl \
		$$(CHS_XILINX_DIR)/scripts/add_sources.$(1).tcl \
		$$(CHS_XILINX_IPS_$(1):%=$(CHS_XILINX_DIR)/build/$(1).%/out.xci) \
		$$(CHS_HW_ALL) \
		| $(CHS_XILINX_DIR)/build/$(1).%/
	@rm -f $(CHS_XILINX_DIR)/build/$$*.$(1).log $(CHS_XILINX_DIR)/build/$$*.$(1).jou
	cd $$| && $(VIVADO) -mode batch -log ../$$*.$(1).log -jou ../$$*.$(1).jou -source $$< \
		-tclargs "$(1) $$* $$(CHS_XILINX_IPS_$(1):%=$(CHS_XILINX_DIR)/build/$(1).%/out.xci)"

chs_xilinx_$(1): $$(CHS_XILINX_DIR)/out/cheshire.$(1).bit
endef

$(foreach board,$(CHS_XILINX_BOARDS),$(eval $(call chs_xilinx_bit_rule,$(board))))

# Builds bitstreams for all available boards
CHS_XILINX_ALL = $(foreach board,$(CHS_XILINX_BOARDS),$$(CHS_XILINX_DIR)/out/cheshire.$(board).bit)

#############
# Utilities #
#############

# TODO