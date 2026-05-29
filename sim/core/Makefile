###############################################################################
#
# Copyright 2020 OpenHW Group
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://solderpad.org/licenses/
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###############################################################################
#
# Makefile for the CV_CORE "core" testbench.  Substantially modified from the
# Makefile original for the RI5CY testbench.
#
###############################################################################
#
# Copyright 2019 Claire Wolf
# Copyright 2019 Robert Balas
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
#
# Original Author: Robert Balas (balasr@iis.ee.ethz.ch)
#
###############################################################################

# "Constants"
MAKE           = make
MAKE_DIR       = $(PWD)
MAKE_PATH     := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
COREV_PROJ     = cv32
# Standalone per-core layout: this repo is self-contained. CV32E40X_DV is the
# repo root; core-v-verif is vendored under it (cloned on demand).
CV32E40X_DV    = $(abspath $(MAKE_PATH)/../../)
CORE_V_VERIF   = $(CV32E40X_DV)/vendor_lib/openhwgroup_core-v-verif
DATE           = $(shell date +%F)
WAVES          = 0

CV_CORE       ?= CV32E40X
CV_CORE_LC     = $(shell echo $(CV_CORE) | tr A-Z a-z)
CV_CORE_UC     = $(shell echo $(CV_CORE) | tr a-z A-Z)

# Compile compile flags for all simulators
SV_CMP_FLAGS =

# Common output directories
RUN_INDEX               ?= 0
SIM_RESULTS              = simulation_results
SIM_TEST_RESULTS         = $(SIM_RESULTS)/$(TEST)
SIM_RUN_RESULTS          = $(SIM_TEST_RESULTS)/$(RUN_INDEX)
SIM_TEST_PROGRAM_RESULTS = $(SIM_RUN_RESULTS)/test_program
SIM_BSP_RESULTS          = $(SIM_TEST_PROGRAM_RESULTS)/bsp

# Test-Program directores.
# Relative path is used for Verilator which cannot seem to handle loooong pathnames.
TEST_PROGRAM_PATH    ?= $(CV32E40X_DV)/tests/programs/custom
TEST_PROGRAM_RELPATH ?= ../../tests/programs/custom
# Default test-program
TEST                 ?= hello-world

# TEST_FLAGS_MAKE / CFG_FLAGS_MAKE (parsed from test.yaml/cfg.yaml via
# bin/yaml2make) are generated in mk/Common.mk, conditionally on the make goal,
# so non-test goals (e.g. gen / certify / gen-certify) do not require a TEST.

# Common Makefiles:
#  -Variables for RTL and other dependencies (e.g. RISCV-DV)
include ../ExternalRepos.mk
#  -Core Firmware and the RISCV GCC Toolchain (SDK)
include $(CV32E40X_DV)/mk/Common.mk

# vsim configuration
VVERSION  = "10.7b"

VLIB      = vlib
VWORK     = work

VLOG          = vlog
VLOG_FLAGS    = -pedanticerrors -suppress 2577 -suppress 2583 +define+COREV_ASSERT_OFF
VLOG_LOG      = vloggy

VOPT          = vopt
VOPT_FLAGS    = -debugdb -fsmdebug -pedanticerrors +acc #=mnprft

VSIM              = vsim
VSIM_HOME         = /usr/pack/modelsim-$(VVERSION)-kgf/questasim
VSIM_FLAGS       ?=  # user defined
ALL_VSIM_FLAGS    = $(VSIM_FLAGS)
VSIM_DEBUG_FLAGS  = -debugdb
VSIM_GUI_FLAGS    = -gui -debugdb
VSIM_SCRIPT_DIR	  = ../tools/vsim
VSIM_SCRIPT       = $(VSIM_SCRIPT_DIR)/vsim.tcl

# vcs configuration (hopelessly out of date)
VCS_VERSION             = O-2018.09-SP1-1
VCS_HOME                = /opt/synopsys/vcs-mx/$(VCS_VERSION)
VCS                     = vcs
VCS_FLAGS              ?= # user defined
ALL_VCS_FLAGS           = $(VCS_FLAGS)
VCS_SCRIPT_DIR          = ../tools/vcs
VCS_SCRIPT              = $(VCS_SCRIPT_DIR)/vcs_batch.tcl
VCS_SCRIPT_GUI          = $(VCS_SCRIPT_DIR)/vcs.tcl
SIMV                    = ./simv

# dsim is the Metrics Technologies SystemVerilog simulator  (https://metrics.ca/)
DSIM                    = dsim
DSIM_HOME               = /tools/Metrics/dsim
DSIM_CMP_FLAGS          = +define+CORE_TB+COREV_ASSERT_OFF -timescale 1ns/1ps $(SV_CMP_FLAGS) -suppress MultiBlockWrite +define+CV32E40X_APU_TRACE
DSIM_RUN_FLAGS          = -write-sql
DSIM_UVM_ARGS           = +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv
DSIM_RESULTS           ?= $(PWD)/dsim_results
DSIM_WORK              ?= $(DSIM_RESULTS)/dsim_work
DSIM_IMAGE              = dsim.out

ifneq (${WAVES}, 0)
  DSIM_CMP_FLAGS += +acc+b
  DSIM_DMP_FILE  ?= dsim.fst
  DSIM_RUN_FLAGS += -waves $(DSIM_DMP_FILE) +disass +disass_display
endif

# xrun is the Cadence xcelium SystemVerilog simulator (https://cadence.com/)
XRUN              = xrun
XRUN_FLAGS        = -clean -smartorder -sv -top worklib.tb_top -timescale 1ns/1ps +define+CV32E40X_APU_TRACE -uvmhome CDNS-1.2-ML
XRUN_DIR          = xcelium.d

# verilator configuration
VERILATOR           = verilator
VERI_FLAGS         +=
VERI_COMPILE_FLAGS += -Wno-COMBDLY -Wno-BLKANDNBLK +define+COREV_ASSERT_OFF $(SV_CMP_FLAGS) # hope this doesn't hurt us in the long run
VERI_TRACE         ?=
VERI_OBJ_DIR       ?= cobj_dir
VERI_LOG_DIR       ?= cobj_dir/logs
VERI_CFLAGS        += -O2

#riviera configuration

ALIB      = "vlib"
AWORK     = work

ALOG          = vlog
ALOG_DEBUG    = -dbg
ALOG_FLAGS    =
ALOG_UVM      = -uvmver 1.2

ASIM              = vsim
ASIM_HOME         = $(ALDEC_PATH)
ASIM_FLAGS       ?=  # user defined
ALL_ASIM_FLAGS    = $(ASIM_FLAGS)
ASIM_DEBUG_FLAGS  = -dbg
ASIM_GUI_FLAGS    = -gui

# TB source files for the CV32E core
TBSRC_HOME  := $(CV32E40X_DV)/tb
TBSRC_TOP   := $(TBSRC_HOME)/core/tb_top.sv
TBSRC_CORE  := $(TBSRC_HOME)/core
TBSRC_PKG   := $(TBSRC_CORE)/tb_riscv/include/perturbation_defines.sv
TBSRC       := $(TBSRC_CORE)/tb_top.sv \
               $(TBSRC_CORE)/cv32e40x_tb_wrapper.sv \
               $(TBSRC_CORE)/mm_ram.sv \
               $(TBSRC_CORE)/dp_ram.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_random_stall.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_random_interrupt_generator.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_rvalid_stall.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_gnt_stall.sv

#/tb_riscv/riscv_rvalid_stall.sv

RTLSRC_VLOG_TB_TOP	:= $(basename $(notdir $(TBSRC_TOP)))
RTLSRC_VOPT_TB_TOP	:= $(addsuffix _vopt, $(RTLSRC_VLOG_TB_TOP))

TBSRC_VERI  := $(TBSRC_PKG) \
               $(TBSRC_CORE)/tb_top.sv \
               $(TBSRC_CORE)/cv32e40x_tb_wrapper.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_rvalid_stall.sv \
               $(TBSRC_CORE)/tb_riscv/riscv_gnt_stall.sv \
               $(TBSRC_CORE)/mm_ram.sv \
               $(TBSRC_CORE)/dp_ram.sv
SIM_LIBS    := $(CORE_V_VERIF)/lib/sim_libs

# RTL source files for the CV32E core
# DESIGN_RTL_DIR is used by CV_CORE_MANIFEST file
CV_CORE_PKG           := $(CV32E40X_DV)/core-v-cores/$(CV_CORE_LC)
CV_CORE_RTLSRC_INCDIR := $(CV_CORE_PKG)/rtl/include
CV_CORE_RTLSRC_PKG    := $(CV_CORE_PKG)/rtl/fpnew/src/fpnew_pkg.sv \
				$(addprefix $(CV_CORE_RTLSRC_INCDIR)/,\
				CV_CORE_apu_core_package.sv CV_CORE_defines.sv \
				CV_CORE_tracer_defines.sv)
CV_CORE_RTLSRC  := $(filter-out $(CV_CORE_PKG)/rtl/$(CV_CORE_LC)_register_file_latch.sv, \
                $(wildcard $(CV_CORE_PKG)/rtl/*.sv))
# FIXME: temporarily using a local manifest for the core.
#        This is BAD PRACTICE and will be fixed with
#        https://github.com/openhwgroup/CV_CORE/pull/421 is resolved.
CV_CORE_MANIFEST    := $(CV_CORE_PKG)/cv32e40x_manifest.flist
export DESIGN_RTL_DIR = $(CV_CORE_PKG)/rtl

###############################################################################
# ACT4 certification (gen-certify) configuration
#
# ACT4_PKG is the cloned ACT4 checkout (see mk/Common.mk / sim/ExternalRepos.mk).
# CV_CORE_CONFIG selects the ISA config -> the ACT4 CTP directory under
# config/cores/cve4/ and a per-config Verilator binary (so configs are certified
# side by side without rebuilding). rv32imcab additionally enables the A and B
# extensions via compile defines consumed by cv32e40x_tb_wrapper localparams.
CV_CORE_CONFIG          ?= rv32imc
CERT_CONFIG_NAME        ?= cv32e40x-$(CV_CORE_CONFIG)
# Sm: excluded by ACT4 by default.
# SsstrictSm: excluded due to an ACT4 issue.
CERT_EXCLUDE_EXTENSIONS ?= Sm,SsstrictSm
# Per-test cycle bound so a non-terminating ELF can't hang the certify sweep.
CERT_MAXCYCLES          ?= 200000

CERT_BIN_DIR             = $(SIM_RESULTS)/certification_$(CV_CORE_CONFIG)
CERT_BIN                 = $(CERT_BIN_DIR)/verilator_executable

ifeq ($(CV_CORE_CONFIG),rv32imcab)
  CERT_EXT_DEFINES = +define+CV32E40X_RVA +define+CV32E40X_RVB
else
  CERT_EXT_DEFINES =
endif

# ACT4 emits ELFs here. ELFs have varying entry points, so the testbench reads
# each ELF header for boot_addr (+elf_file=) rather than a shared +test_program.
certification_PROGRAM_PATH = $(ACT4_PKG)/work/$(CERT_CONFIG_NAME)/elfs

# Optional extension filter: narrows the certify scan to a subdirectory.
# Usage: make certify FILTER=priv/InterruptsSm
FILTER ?=

# Shorthand rules for convience
CV_CORE_pkg: clone_$(CV_CORE_LC)_rtl

tbsrc_pkg: $(TBSRC_PKG)

tbsrc: $(TBSRC)

###############################################################################

SIMULATOR ?= vcs

.PHONY: hello-world
hello-world: $(SIMULATOR)-hello-world

.PHONY: cv32_riscv_tests
cv32_riscv_tests: $(SIMULATOR)-cv32_riscv_tests

.PHONY: cv32_riscv_tests-gui
cv32_riscv_tests-gui: $(SIMULATOR)-cv32_riscv_tests-gui

.PHONY: cv32_riscv_compliance_tests
cv32_riscv_compliance_tests: $(SIMULATOR)-cv32_riscv_compliance_tests

.PHONY: cv32_riscv_compliance_tests-gui
cv32_riscv_compliance_tests-gui: $(SIMULATOR)-cv32_riscv_compliance_tests-gui

.PHONY: firmware
firmware: $(SIMULATOR)-firmware

.PHONY: firmware-gui
firmware-gui: $(SIMULATOR)-firmware-gui

.PHONY: unit-test
unit-test: $(SIMULATOR)-unit-test

.PHONY: unit-test-gui
unit-test-gui: $(SIMULATOR)-unit-test-gui

# assume verilator if no target chosen
.DEFAULT_GOAL := sanity-veri-run

all: clean_all sanity-veri-run dsim-sanity

###############################################################################
# Metrics DSIM
.PHONY: dsim-comp dsim-comp-rtl-only

MKDIR_P = mkdir -p

mk_results:
	$(MKDIR_P) $(DSIM_RESULTS)
	$(MKDIR_P) $(DSIM_WORK)

# Metrics dsim compile targets
dsim-comp: mk_results CV_CORE_pkg tbsrc_pkg tbsrc
		cd $(DSIM_RESULTS) && \
		$(DSIM) \
		$(DSIM_CMP_FLAGS) \
		$(DSIM_UVM_ARGS) \
		-f $(CV_CORE_MANIFEST) \
		$(TBSRC_PKG) \
		$(TBSRC) \
		-work $(DSIM_WORK) \
		-genimage $(DSIM_IMAGE)

dsim-comp-rtl-only: mk_results $(CV_CORE_PKG)
	$(DSIM) \
		$(DSIM_CMP_FLAGS) \
		-f $(CV_CORE_MANIFEST) \
		-work $(DSIM_WORK) \
		-genimage $(DSIM_IMAGE)


# Metrics dsim simulations
.PHONY: dsim-hello-world dsim-firmware

dsim-sanity: dsim-test

dsim-custom:
	@echo "This target is depreciated.  Please use 'make dsim-test TEST=<test-program>'"
	@echo "                             Example:   'make dsim-test TEST=fibonacci'"

dsim-test: dsim-comp $(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex
	@echo "$(BANNER)"
	@echo "* Running with Metrics DSIM"
	@echo "$(BANNER)"
	mkdir -p $(DSIM_RESULTS)/$(TEST) && cd $(DSIM_RESULTS)/$(TEST)  && \
	$(DSIM) -l dsim-$(TEST).log \
		-image $(DSIM_IMAGE) \
		-work $(DSIM_WORK) \
		$(DSIM_RUN_FLAGS) \
		-sv_lib $(UVM_HOME)/src/dpi/libuvm_dpi.so \
		-sv_lib $(OVP_MODEL_DPI)  \
		+firmware=$(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex

# Metrics dsim cleanup
.PHONY: dsim-clean

dsim-clean: tc-clean
	rm -f dsim.log
	rm -f dsim-*.log
	rm -f metrics_history.db
	rm -f metrics.xml
	rm -f trace_core_00_0.log
	rm -rf dsim_work
	rm -f dsim.env
	rm -f $(DSIM_IMAGE)
	rm -rf $(uIM_RESULTS)

###############################################################################
# Mentor Questasim


.lib-rtl:
	$(VLIB) $(VWORK)
	touch .lib-rtl


.build-rtl: .lib-rtl CV_CORE_pkg $(CV_CORE_PKG) $(TBSRC_PKG) $(TBSRC)
	$(VLOG) \
		-work $(VWORK) \
		$(VLOG_FLAGS) \
		-f $(CV_CORE_MANIFEST) \
		$(TBSRC_PKG) $(TBSRC)


vsim-all:  .opt-rtl


.opt-rtl: .build-rtl
	$(VOPT) -work $(VWORK) $(VOPT_FLAGS) $(RTLSRC_VLOG_TB_TOP) -o $(RTLSRC_VOPT_TB_TOP)
	touch .opt-rtl

# run tb and exit
.PHONY: vsim-run
vsim-run: ALL_VSIM_FLAGS += -c
vsim-run: vsim-all
	$(VSIM) -work $(VWORK) $(DPILIB_VSIM_OPT) $(ALL_VSIM_FLAGS) \
	$(RTLSRC_VOPT_TB_TOP) -do 'source $(VSIM_SCRIPT); exit -f'



# run tb and drop into interactive shell
.PHONY: vsim-run-sh
vsim-run-sh: ALL_VSIM_FLAGS += -c
vsim-run-sh: vsim-all
	$(VSIM) -work $(VWORK) $(DPILIB_VSIM_OPT) $(ALL_VSIM_FLAGS) \
	$(RTLSRC_VOPT_TB_TOP) -do $(VSIM_SCRIPT)

# run tb with simulator gui
.PHONY: vsim-run-gui
vsim-run-gui: ALL_VSIM_FLAGS += $(VSIM_GUI_FLAGS)
vsim-run-gui: vsim-all
	$(VSIM) -work $(VWORK) $(DPILIB_VSIM_OPT) $(ALL_VSIM_FLAGS) \
	$(RTLSRC_VOPT_TB_TOP) -do $(VSIM_SCRIPT)

.PHONY: questa-custom
questa-custom: vsim-all $(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex
questa-custom: ALL_VSIM_FLAGS += +firmware=$(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex
questa-custom: vsim-run

.PHONY: questa-custom-gui
questa-custom-gui: vsim-all $(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex
questa-custom-gui: ALL_VSIM_FLAGS += +firmware=$(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex
questa-custom-gui: vsim-run-gui

.PHONY: questa-cv32_riscv_tests
questa-cv32_riscv_tests: vsim-all $(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.hex
questa-cv32_riscv_tests: ALL_VSIM_FLAGS += +firmware=$(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.hex
questa-cv32_riscv_tests: vsim-run

.PHONY: questa-cv32_riscv_tests-gui
questa-cv32_riscv_tests-gui: vsim-all $(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.hex
questa-cv32_riscv_tests-gui: ALL_VSIM_FLAGS += +firmware=$(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.hex
questa-cv32_riscv_tests-gui: vsim-run-gui

.PHONY: questa-cv32_riscv_compliance_tests
questa-cv32_riscv_compliance_tests: vsim-all $(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/cv32_riscv_compliance_tests_firmware.hex
questa-cv32_riscv_compliance_tests: ALL_VSIM_FLAGS += +firmware=$(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/cv32_riscv_compliance_tests_firmware.hex
questa-cv32_riscv_compliance_tests: vsim-run

.PHONY: questa-cv32_riscv_compliance_tests-gui
questa-cv32_riscv_compliance_tests-gui: vsim-all $(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/cv32_riscv_compliance_tests_firmware.hex
questa-cv32_riscv_compliance_tests-gui: ALL_VSIM_FLAGS += +firmware=$(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/cv32_riscv_compliance_tests_firmware.hex
questa-cv32_riscv_compliance_tests-gui: vsim-run-gui

.PHONY: questa-firmware
questa-firmware: vsim-all $(FIRMWARE)/firmware.hex
questa-firmware: ALL_VSIM_FLAGS += +firmware=$(FIRMWARE)/firmware.hex
questa-firmware: vsim-run

.PHONY: questa-firmware-gui
questa-firmware-gui: vsim-all $(FIRMWARE)/firmware.hex
questa-firmware-gui: ALL_VSIM_FLAGS += +firmware=$(FIRMWARE)/firmware.hex
questa-firmware-gui: vsim-run-gui

.PHONY: questa-unit-test
questa-unit-test:  firmware-unit-test-clean
questa-unit-test:  $(FIRMWARE)/firmware_unit_test.hex
questa-unit-test: ALL_VSIM_FLAGS += "+firmware=$(FIRMWARE)/firmware_unit_test.hex"
questa-unit-test: vsim-run

.PHONY: questa-unit-test-gui
questa-unit-test-gui:  firmware-unit-test-clean
questa-unit-test-gui:  $(FIRMWARE)/firmware_unit_test.hex
questa-unit-test-gui: ALL_VSIM_FLAGS += "+firmware=$(FIRMWARE)/firmware_unit_test.hex"
questa-unit-test-gui: vsim-run-gui

questa-clean:
	if [ -d $(VWORK) ]; then rm -r $(VWORK); fi
	rm -f transcript vsim.wlf vsim.dbg trace_core*.log \
	.build-rtl .opt-rtl .lib-rtl *.vcd objdump

###############################################################################
# Cadence Xcelium xrun testbench compilation
.PHONY: xrun-all
xrun-all: $(CV_CORE_PKG) $(RTLSRC_PKG) $(RTLSRC) $(TBSRC_PKG) $(TBSRC)
	$(XRUN) \
		$(XRUN_FLAGS) \
		-f $(CV_CORE_MANIFEST) \
		$(TBSRC_PKG) $(TBSRC)

xrun-custom:
	@echo "This target is depreciated.  Please use 'make xrun-test TEST=<test-program>'"
	@echo "                             Example:   'make xrun-test TEST=fibonacci'"

.PHONY: xrun-test
xrun-test: xrun-all $(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex
	$(XRUN) \
		$(XRUN_FLAGS) \
		-f $(CV_CORE_MANIFEST) \
		$(TBSRC_PKG) $(TBSRC) \
		+firmware=$(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex

# Cadence Xcelium xrun cleanup
.PHONY: xrun-clean xrun-clean-all
xrun-clean:
	rm -vrf $(XRUN_DIR)
	if [ -e xrun.history ]; then rm xrun.history; fi
	if [ -e xrun.log ]; then rm xrun.log; fi

xrun-clean-all: xrun-clean
	rm -vrf $(addprefix $(FIRMWARE)/firmware., elf bin hex map) \
		$(FIRMWARE_OBJS) $(FIRMWARE_TEST_OBJS) $(COMPLIANCE_TEST_OBJS)

###############################################################################
# Verilator

# We first test if the user wants to to vcd dumping. This hacky part is required
# because we need to conditionally compile the testbench (-DVCD_TRACE) and pass
# the --trace flags to the verilator call
#ifeq ($(findstring +vcd,$(VERI_FLAGS)),+vcd)

ifneq (${WAVES}, 0)
VERI_TRACE="--trace"
VERI_CFLAGS+="-DVCD_TRACE"
endif

sanity-veri-run:
	make veri-test TEST=hello-world

# Single consolidated tb_top built with Verilator's --main (no hand-written C++
# harness). --timing is required by tb_top's integer clock/reset delays.
# --trace is ALWAYS passed: without it a Verilator X-propagation optimization
# makes tests pass vacuously / fail silently (hard regression guard).
verilate: CV_CORE_pkg $(TBSRC_VERI) $(TBSRC_PKG)
	@echo "$(BANNER)"
	@echo "* Compiling CORE TB and CV32E40X with Verilator"
	@echo "$(BANNER)"
	$(VERILATOR) --cc --sv --exe --build --main --timing \
		--trace \
		--Wno-lint --Wno-UNOPTFLAT --Wno-MODDUP --Wno-SYMRSVDWORD \
		--top-module tb_top \
		$(TBSRC_VERI) \
		-f $(CV_CORE_MANIFEST) \
		$(CV_CORE_PKG)/bhv/$(CV_CORE_LC)_core_log.sv \
		--Mdir $(VERI_OBJ_DIR) \
		-CFLAGS "-std=gnu++14 $(VERI_CFLAGS)" \
		$(VERI_COMPILE_FLAGS)
	mkdir -p $(SIM_TEST_RESULTS)
	cp $(VERI_OBJ_DIR)/Vtb_top $(SIM_TEST_RESULTS)/verilator_executable

veri-test: verilate $(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex
	@echo "$(BANNER)"
	@echo "* Running with Verilator: logfile in $(VERI_LOG_DIR)/$(TEST).log"
	@echo "$(BANNER)"
	mkdir -p $(VERI_LOG_DIR)
	$(SIM_TEST_RESULTS)/verilator_executable $(VERI_FLAGS) \
		"+firmware=$(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex" \
		| tee $(VERI_LOG_DIR)/$(TEST).log

# verilator specific cleanup
veri-clean: verilate-clean

verilate-clean: tc-clean
	if [ -d $(VERI_LOG_DIR) ]; then rm -r $(VERI_LOG_DIR); fi
	if [ -d $(VERI_OBJ_DIR) ]; then rm -r $(VERI_OBJ_DIR); fi
	rm -rf testbench_verilator
	if [ -e memory_dump.bin ]; then rm memory_dump.bin; fi


###############################################################################
# Synopsys VCS

vcsify: CV_CORE_pkg tbsrc_pkg tbsrc
	$(VCS) +vc -sverilog -race=all -ignore unique_checks -full64 \
		-timescale=1ns/1ps \
		-assert svaext \
		-CC "-I$(VCS_HOME)/include -O3 -march=native" $(VCS_FLAGS) \
		-f $(MAKE_DIR)/$(CV_CORE_MANIFEST) \
		$(TBSRC_PKG) $(TBSRC)

RTLSRC_TB_TOP	:= $(basename $(notdir $(TBSRC_TOP)))

vcs-run: vcsify
	$(SIMV) $(ALL_VCS_FLAGS) -ucli -do $(VCS_SCRIPT)

vcs-run-gui: vcsify
	$(SIMV) $(ALL_VCS_FLAGS) -gui -do $(VCS_SCRIPT_GUI)

.PHONY: vcs-hello-world
vcs-hello-world: vcsify $(TEST_PROGRAM_PATH)/hello-world.hex
vcs-hello-world: ALL_VCS_FLAGS += +firmware=$(TEST_PROGRAM_PATH)/hello-world.hex
vcs-hello-world: vcs-run

.PHONY: vcs-custom
vcs-custom: vcsify $(TEST_PROGRAM_PATH)/$(TEST).hex
vcs-custom: ALL_VCS_FLAGS += +firmware=$(TEST_PROGRAM_PATH)/$(TEST).hex
vcs-custom: vcs-run

.PHONY: vcs-cv32_riscv_tests
vcs-cv32_riscv_tests: vcsify $(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.hex
vcs-cv32_riscv_tests: ALL_VCS_FLAGS += +firmware=$(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.hex
vcs-cv32_riscv_tests: vcs-run

.PHONY: vcs-cv32_riscv_tests-gui
vcs-cv32_riscv_tests-gui: vcsify $(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.hex
vcs-cv32_riscv_tests-gui: ALL_VCS_FLAGS += +firmware=$(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.hex
vcs-cv32_riscv_tests-gui: vcs-run-gui

.PHONY: vcs-cv32_riscv_compliance_tests
vcs-cv32_riscv_compliance_tests: vcsify $(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/cv32_riscv_compliance_tests_firmware.hex
vcs-cv32_riscv_compliance_tests: ALL_VCS_FLAGS += +firmware=$(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/cv32_riscv_compliance_tests_firmware.hex
vcs-cv32_riscv_compliance_tests: vcs-run

.PHONY: vcs-cv32_riscv_compliance_tests-gui
vcs-cv32_riscv_compliance_tests-gui: vcsify $(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/cv32_riscv_compliance_tests_firmware.hex
vcs-cv32_riscv_compliance_tests-gui: ALL_VCS_FLAGS += +firmware=$(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/cv32_riscv_compliance_tests_firmware.hex
vcs-cv32_riscv_compliance_tests-gui: vcs-run-gui

.PHONY: vcs-firmware
vcs-firmware: vcsify $(FIRMWARE)/firmware.hex
vcs-firmware: ALL_VCS_FLAGS += +firmware=$(FIRMWARE)/firmware.hex
vcs-firmware: vcs-run

.PHONY: vcs-firmware-gui
vcs-firmware-gui: vcsify $(FIRMWARE)/firmware.hex
vcs-firmware-gui: ALL_VCS_FLAGS += +firmware=$(FIRMWARE)/firmware.hex
vcs-firmware-gui: vcs-run-gui

.PHONY: vcs-unit-test
vcs-unit-test:  firmware-unit-test-clean
vcs-unit-test:  $(FIRMWARE)/firmware_unit_test.hex
vcs-unit-test: ALL_VCS_FLAGS += "+firmware=$(FIRMWARE)/firmware_unit_test.hex"
vcs-unit-test: vcs-run

.PHONY: vcs-unit-test-gui
vcs-unit-test-gui:  firmware-unit-test-clean
vcs-unit-test-gui:  $(FIRMWARE)/firmware_unit_test.hex
vcs-unit-test-gui: ALL_VCS_FLAGS += "+firmware=$(FIRMWARE)/firmware_unit_test.hex"
vcs-unit-test-gui: vcs-run-gui

vcs-clean:
	rm -rf simv* *.daidir *.vpd *.db csrc ucli.key vc_hdrs.h

###############################################################################
# Aldec Riviera-PRO

.rvrlib-rtl:
	$(ALIB) $(AWORK)
	touch .rvrlib-rtl

rvr-build-rtl: .rvrlib-rtl CV_CORE_pkg tbsrc_pkg tbsrc
	$(ALOG) \
		-work $(AWORK) \
		$(ALOG_FLAGS) \
		$(ALOG_UVM) \
		-f $(CV_CORE_MANIFEST) \
		$(TBSRC_PKG) $(TBSRC)

asim-all:  .rvr-build-rtl

# run tb and exit
.PHONY: asim-run
asim-run: ALL_ASIM_FLAGS += -c
asim-run: rvr-build-rtl
	$(ASIM) -lib $(AWORK) $(ALL_ASIM_FLAGS)\
	$(RTLSRC_VLOG_TB_TOP) -do "run -all; endsim; quit -force"

# run tb and drop into interactive shell
.PHONY: asim-run-sh
asim-run-sh: ALL_ASIM_FLAGS += -c
asim-run-sh: rvr-build-rtl
	$(ASIM) -lib $(AWORK) $(ALL_ASIM_FLAGS) \
	$(RTLSRC_VLOG_TB_TOP) -do "run -all"

# run tb with simulator gui
.PHONY: asim-run-gui
asim-run-gui: ALL_ASIM_FLAGS += $(ASIM_GUI_FLAGS)
asim-run-gui: rvr-build-rtl
	$(ASIM) -lib $(AWORK) $(ALL_ASIM_FLAGS) \
	$(RTLSRC_VLOG_TB_TOP) -do "run -all"

.PHONY: riviera-hello-world
riviera-hello-world: rvr-build-rtl $(TEST_PROGRAM_PATH)/hello-world/hello-world.hex
riviera-hello-world: ALL_ASIM_FLAGS += +firmware=$(TEST_PROGRAM_PATH)/hello-world/hello-world.hex
riviera-hello-world: asim-run

.PHONY: riviera-hello-world-gui
riviera-hello-world-gui: rvr-build-rtl $(TEST_PROGRAM_PATH)/hello-world/hello-world.hex
riviera-hello-world-gui: ALL_ASIM_FLAGS += +firmware=$(TEST_PROGRAM_PATH)/hello-world/hello-world.hex
riviera-hello-world-gui: asim-run-gui

.PHONY: riviera-custom
riviera-custom: rvr-build-rtl $(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex
riviera-custom: ALL_ASIM_FLAGS += +firmware=$(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex
riviera-custom: asim-run

.PHONY: riviera-custom-gui
riviera-custom-gui: rvr-build-rtl $(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex
riviera-custom-gui: ALL_ASIM_FLAGS += +firmware=$(TEST_PROGRAM_PATH)/$(TEST)/$(TEST).hex
riviera-custom-gui: asim-run-gui

riviera-clean:
	if [ -d $(AWORK) ]; then rm -r $(AWORK); fi
	rm -f transcript trace_core*.log \
	.build-rtl .rvrlib-rtl *.vcd objdump *.asdb *.cfg dpi_header.h

###############################################################################
# CV_CORE RTL dependencies

clone_$(CV_CORE_LC)_rtl:
	@echo "$(BANNER)"
	@echo "* Cloning CV32E40X RTL model"
	@echo "$(BANNER)"
	$(CLONE_CV_CORE_CMD)




###############################################################################
# general targets
.PHONY: tc-clean

# clean up toolchain generated files
clean-test-programs:
	find $(CV32E40X_DV)/tests/programs -name *.o       -exec rm {} \;
	find $(CV32E40X_DV)/tests/programs -name *.hex     -exec rm {} \;
	find $(CV32E40X_DV)/tests/programs -name *.elf     -exec rm {} \;
	find $(CV32E40X_DV)/tests/programs -name *.map     -exec rm {} \;
	find $(CV32E40X_DV)/tests/programs -name *.readelf -exec rm {} \;
	find $(CV32E40X_DV)/tests/programs -name *.objdump -exec rm {} \;
	find $(CV32E40X_DV)/tests/programs -name corev_*.S -exec rm {} \;

.PHONY: clean clean_all distclean
clean: clean-test-programs questa-clean verilate-clean vcs-clean firmware-clean dsim-clean xrun-clean vcs-clean clean_bsp riviera-clean

distclean: clean
	rm -rf riscv-fesvr riscv-isa-sim $(CV_CORE_PKG) work

clean_all: distclean
#endend

###############################################################################
# ACT4 certification flow (gen-certify)
#
#   gen              : generate the ACT4 ELFs for CV_CORE_CONFIG (needs `uv`).
#   certify          : build the per-config Verilator binary and run every ELF,
#                      tallying PASS/FAIL into certification_summary.txt.
#   gen-certify      : gen + certify.
#   elfs-package     : tar the generated ELFs (CI cache of the slow `gen` step).
#   certify-prebuilt : unpack a prebuilt ELF tarball and certify (CI fast path).
#
# Validate with:  make gen-certify CV_CORE_CONFIG=rv32imc     (Sm excluded)
#                 make gen-certify CV_CORE_CONFIG=rv32imcab   (adds A + B)
###############################################################################
.PHONY: gen certify gen-certify elfs-package certify-prebuilt

# objcopy used to turn ACT4 ELFs into $readmemh hex. The ACT4 ELFs are built by
# ACT4's own toolchain, so this is decoupled from the DUT's CV_SW_PREFIX.
CERT_SW_PREFIX ?= riscv64-unknown-elf-

# Per-config Verilator build dir so configs don't clobber each other.
CERT_OBJ_DIR    = $(VERI_OBJ_DIR)_$(CV_CORE_CONFIG)

# Per-config Verilator binary. Same recipe as `verilate` (tb_top, --main,
# --timing, ALWAYS --trace) plus the A/B extension defines for this config.
$(CERT_BIN): CV_CORE_pkg $(TBSRC_VERI) $(TBSRC_PKG)
	@echo "$(BANNER)"
	@echo "* Compiling CORE TB and CV32E40X with Verilator ($(CV_CORE_CONFIG))"
	@echo "$(BANNER)"
	$(VERILATOR) --cc --sv --exe --build --main --timing \
		--trace \
		--Wno-lint --Wno-UNOPTFLAT --Wno-MODDUP --Wno-SYMRSVDWORD \
		--top-module tb_top \
		$(TBSRC_VERI) \
		-f $(CV_CORE_MANIFEST) \
		$(CV_CORE_PKG)/bhv/$(CV_CORE_LC)_core_log.sv \
		--Mdir $(CERT_OBJ_DIR) \
		-CFLAGS "-std=gnu++14 $(VERI_CFLAGS)" \
		$(VERI_COMPILE_FLAGS) \
		$(CERT_EXT_DEFINES)
	mkdir -p $(CERT_BIN_DIR)
	cp $(CERT_OBJ_DIR)/Vtb_top $(CERT_BIN)

gen: $(ACT4_PKG)
	@command -v uv >/dev/null 2>&1 || { echo "Error: 'uv' not found. Install from https://docs.astral.sh/uv/getting-started/installation/"; exit 1; }
	@echo "* Cleaning ACT4 directory..."
	@$(MAKE) -C $(ACT4_PKG) clean
	@echo "* Generating ACT4 tests for $(CERT_CONFIG_NAME)..."
	@$(MAKE) -C $(ACT4_PKG) \
		EXCLUDE_EXTENSIONS=$(CERT_EXCLUDE_EXTENSIONS) \
		CONFIG_FILES=config/cores/cve4/$(CERT_CONFIG_NAME)/test_config.yaml
	@echo "* Tests generated in: $(certification_PROGRAM_PATH)"
	@echo "* Pre-generating .hex files alongside ELFs..."
	@find "$(certification_PROGRAM_PATH)" \( -iname '*.elf' -o -iname '*.elf32' \) | \
		while IFS= read -r elf; do \
		  hex="$${elf%.*}.hex"; \
		  if [ ! -f "$$hex" ] || [ "$$elf" -nt "$$hex" ]; then \
		    $(CERT_SW_PREFIX)objcopy -O verilog "$$elf" "$$hex"; \
		  fi; \
		done

certify: $(CERT_BIN)
	@echo "$(BANNER)"
	@echo "* Running ALL ACT4 ELFs through Verilator ($(CERT_CONFIG_NAME))"
	@echo "$(BANNER)"
	@set -e; \
	mkdir -p "$(VERI_LOG_DIR)"; \
	SUMMARY="$(VERI_LOG_DIR)/certification_summary.txt"; \
	echo "RESULT  TEST" > "$$SUMMARY"; \
	echo "------  ----" >> "$$SUMMARY"; \
	ROOT="$(certification_PROGRAM_PATH)$(if $(FILTER),/$(FILTER),)"; \
	ELFS="$$(find -L "$$ROOT" \( -type f -o -type l \) -a \( -iname '*.elf' -o -iname '*.elf32' \) 2>/dev/null | sort)"; \
	if [ -z "$$ELFS" ]; then \
	  echo "No .elf files found under $$ROOT"; \
	  echo "Hint: run \`make gen CV_CORE_CONFIG=$(CV_CORE_CONFIG)\` first."; \
	  exit 2; \
	fi; \
	PASS=0; FAIL=0; TOTAL=0; \
	for ELF in $$ELFS; do \
	  TOTAL=$$((TOTAL+1)); \
	  REL="$${ELF#$$ROOT/}"; \
	  BASE="$${ELF%.*}"; HEX="$$BASE.hex"; \
	  LOG="$(VERI_LOG_DIR)/$${REL%.*}.log"; \
	  mkdir -p "$$(dirname "$$LOG")"; \
	  if [ ! -f "$$HEX" ] || [ "$$ELF" -nt "$$HEX" ]; then \
	    $(CERT_SW_PREFIX)objcopy -O verilog "$$ELF" "$$HEX"; \
	  fi; \
	  set +e; \
	  "$(CERT_BIN)" $(VERI_FLAGS) "+maxcycles=$(CERT_MAXCYCLES)" "+elf_file=$$ELF" > "$$LOG" 2>&1; \
	  RC=$$?; \
	  set -e; \
	  if [ $$RC -eq 0 ] && grep -q "ALL TESTS PASSED" "$$LOG"; then \
	    echo "PASS    $$REL" | tee -a "$$SUMMARY"; PASS=$$((PASS+1)); \
	  else \
	    echo "FAIL    $$REL" | tee -a "$$SUMMARY"; FAIL=$$((FAIL+1)); \
	  fi; \
	done; \
	echo "" | tee -a "$$SUMMARY"; \
	echo "TOTAL=$$TOTAL PASS=$$PASS FAIL=$$FAIL" | tee -a "$$SUMMARY"; \
	echo "Summary saved to: $$SUMMARY"; \
	true

gen-certify: gen certify

CERT_TARBALL = $(CV32E40X_DV)/tests/act4/act4-elfs-$(CERT_CONFIG_NAME).tar.gz

elfs-package:
	@if [ -z "$$(find -L "$(certification_PROGRAM_PATH)" \( -iname '*.elf' -o -iname '*.elf32' \) 2>/dev/null)" ]; then \
	    echo "Error: no ELFs at $(certification_PROGRAM_PATH). Run 'make gen CV_CORE_CONFIG=$(CV_CORE_CONFIG)' first."; \
	    exit 1; \
	fi
	@mkdir -p $(CV32E40X_DV)/tests/act4
	@tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='UTC 2020-01-01' \
	    --exclude='*.objdump' \
	    -C $(certification_PROGRAM_PATH) \
	    -czf $(CERT_TARBALL) .
	@echo "Tests:   $(CERT_TARBALL)"

certify-prebuilt:
	@if [ ! -f "$(CERT_TARBALL)" ]; then \
	    echo "Error: no prebuilt tarball at $(CERT_TARBALL)."; \
	    echo "Run 'make elfs-package CV_CORE_CONFIG=$(CV_CORE_CONFIG)' or download one first."; \
	    exit 2; \
	fi
	@mkdir -p $(CV32E40X_DV)/tests/act4/unpacked_$(CV_CORE_CONFIG)
	@tar -xzf $(CERT_TARBALL) -C $(CV32E40X_DV)/tests/act4/unpacked_$(CV_CORE_CONFIG)
	@$(MAKE) certify certification_PROGRAM_PATH=$(CV32E40X_DV)/tests/act4/unpacked_$(CV_CORE_CONFIG)
