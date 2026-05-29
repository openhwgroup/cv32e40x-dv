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
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#
###############################################################################
#
# Makefile for the UVMT testbench for multiple OpenHW-verified cores.  Substantially modified
# from the original Makefile for the RI5CY testbench.
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

# Variable checks
ifndef CV_CORE
$(error Must set CV_CORE to a valid core)
endif

# "Constants"
DATE           = $(shell date +%F)
CV_CORE_LC     = $(shell echo $(CV_CORE) | tr A-Z a-z)
CV_CORE_UC     = $(shell echo $(CV_CORE) | tr a-z A-Z)
SIMULATOR_UC   = $(shell echo $(SIMULATOR) | tr a-z A-Z)
export CV_CORE_LC
export CV_CORE_UC
.DEFAULT_GOAL := no_rule

# Useful commands
MKDIR_P = mkdir -p


# Compile compile flags for all simulators (careful!)
WAVES        ?= 0
SV_CMP_FLAGS ?= "+define+$(CV_CORE_UC)_ASSERT_ON"
TIMESCALE    ?= -timescale 1ns/1ps
UVM_PLUSARGS ?=

# User selectable SystemVerilog simulator targets/rules
CV_SIMULATOR ?= unsim
SIMULATOR    ?= $(CV_SIMULATOR)

# Optionally exclude the OVPsim (not recommended)
USE_ISS      ?= YES
ISS          ?= IMPERAS
COMPILE_SPIKE=$(USE_ISS)

# Common configuration variables
CFG             ?= default

# Common Generation variables
GEN_START_INDEX ?= 0
GEN_NUM_TESTS   ?= 1
export RUN_INDEX       ?= 0

# Common output directories
SIM_RESULTS             ?= $(if $(CV_RESULTS),$(abspath $(CV_RESULTS))/$(SIMULATOR)_results,$(MAKE_PATH)/$(SIMULATOR)_results)
SIM_CFG_RESULTS          = $(SIM_RESULTS)/$(CFG)
SIM_COREVDV_RESULTS      = $(SIM_CFG_RESULTS)/corev-dv
SIM_LDGEN_RESULTS        = $(SIM_CFG_RESULTS)/$(LDGEN)
SIM_TEST_RESULTS         = $(SIM_CFG_RESULTS)/$(TEST)
SIM_RUN_RESULTS          = $(SIM_TEST_RESULTS)/$(RUN_INDEX)
SIM_TEST_PROGRAM_RESULTS = $(SIM_RUN_RESULTS)/test_program
SIM_BSP_RESULTS          = $(SIM_TEST_PROGRAM_RESULTS)/bsp

# EMBench options
EMB_TYPE           ?= speed
EMB_TARGET         ?= 0
EMB_CPU_MHZ        ?= 1
EMB_TIMEOUT        ?= 3600
EMB_PARALLEL_ARG    = $(if $(filter $(YES_VALS),$(EMB_PARALLEL)),YES,NO)
EMB_BUILD_ONLY_ARG  = $(if $(filter $(YES_VALS),$(EMB_BUILD_ONLY)),YES,NO)
EMB_DEBUG_ARG       = $(if $(filter $(YES_VALS),$(EMB_DEBUG)),YES,NO)

# UVM Environment
# OLD
#export DV_UVMT_PATH             = $(CV32E40X_DV)/$(CV_CORE_LC)/tb/uvmt
#export DV_UVME_PATH             = $(CV32E40X_DV)/$(CV_CORE_LC)/env/uvme
#export DV_UVML_HRTBT_PATH       = $(CV32E40X_DV)/lib/uvm_libs/uvml_hrtbt
#export DV_UVMA_CORE_CNTRL_PATH  = $(CV32E40X_DV)/lib/uvm_agents/uvma_core_cntrl
#export DV_UVMA_ISACOV_PATH      = $(CV32E40X_DV)/lib/uvm_agents/uvma_isacov
#export DV_UVMA_RVFI_PATH        = $(CV32E40X_DV)/lib/uvm_agents/uvma_rvfi
#export DV_UVMA_RVVI_PATH        = $(CV32E40X_DV)/lib/uvm_agents/uvma_rvvi
#export DV_UVMA_RVVI_OVPSIM_PATH = $(CV32E40X_DV)/lib/uvm_agents/uvma_rvvi_ovpsim
#export DV_UVMA_CLKNRST_PATH     = $(CV32E40X_DV)/lib/uvm_agents/uvma_clknrst
#export DV_UVMA_INTERRUPT_PATH   = $(CV32E40X_DV)/lib/uvm_agents/uvma_interrupt
#export DV_UVMA_DEBUG_PATH       = $(CV32E40X_DV)/lib/uvm_agents/uvma_debug
#export DV_UVMA_PMA_PATH         = $(CV32E40X_DV)/lib/uvm_agents/uvma_pma
#export DV_UVMA_OBI_MEMORY_PATH  = $(CV32E40X_DV)/lib/uvm_agents/uvma_obi_memory
#export DV_UVMA_FENCEI_PATH      = $(CV32E40X_DV)/lib/uvm_agents/uvma_fencei
#export DV_UVML_TRN_PATH         = $(CV32E40X_DV)/lib/uvm_libs/uvml_trn
#export DV_UVML_LOGS_PATH        = $(CV32E40X_DV)/lib/uvm_libs/uvml_logs
#export DV_UVML_SB_PATH          = $(CV32E40X_DV)/lib/uvm_libs/uvml_sb
#export DV_UVML_MEM_PATH         = $(CV32E40X_DV)/lib/uvm_libs/uvml_mem
#
#export DV_UVMC_RVFI_SCOREBOARD_PATH      = $(CV32E40X_DV)/lib/uvm_components/uvmc_rvfi_scoreboard/
#export DV_UVMC_RVFI_REFERENCE_MODEL_PATH = $(CV32E40X_DV)/lib/uvm_components/uvmc_rvfi_reference_model/
#
#export DV_OVPM_HOME             = $(CV32E40X_DV)/vendor_lib/imperas
#export DV_OVPM_MODEL            = $(DV_OVPM_HOME)/imperas_DV_COREV
#
#export DV_OVPM_DESIGN           = $(DV_OVPM_HOME)/design
#
#export DV_SVLIB_PATH            = $(CV32E40X_DV)/$(CV_CORE_LC)/vendor_lib/verilab
#
#DV_UVMT_SRCS                  = $(wildcard $(DV_UVMT_PATH)/*.sv))

# NEW NEW NEW!!!
export DV_UVMT_PATH             = $(CV32E40X_DV)/tb/uvmt
export DV_UVME_PATH             = $(CV32E40X_DV)/env/uvme
export DV_UVML_HRTBT_PATH       = $(CV_VERIF_PKG)/lib/uvm_libs/uvml_hrtbt
export DV_UVMA_CORE_CNTRL_PATH  = $(CV_VERIF_PKG)/lib/uvm_agents/uvma_core_cntrl
export DV_UVMA_ISACOV_PATH      = $(CV_VERIF_PKG)/lib/uvm_agents/uvma_isacov
export DV_UVMA_RVFI_PATH        = $(CV_VERIF_PKG)/lib/uvm_agents/uvma_rvfi
export DV_UVMA_RVVI_PATH        = $(CV_VERIF_PKG)/lib/uvm_agents/uvma_rvvi
export DV_UVMA_RVVI_OVPSIM_PATH = $(CV_VERIF_PKG)/lib/uvm_agents/uvma_rvvi_ovpsim
export DV_UVMA_CLKNRST_PATH     = $(CV_VERIF_PKG)/lib/uvm_agents/uvma_clknrst
export DV_UVMA_INTERRUPT_PATH   = $(CV_VERIF_PKG)/lib/uvm_agents/uvma_interrupt
export DV_UVMA_DEBUG_PATH       = $(CV_VERIF_PKG)/lib/uvm_agents/uvma_debug
export DV_UVMA_PMA_PATH         = $(CV_VERIF_PKG)/lib/uvm_agents/uvma_pma
export DV_UVMA_OBI_MEMORY_PATH  = $(CV_VERIF_PKG)/lib/uvm_agents/uvma_obi_memory
export DV_UVMA_FENCEI_PATH      = $(CV_VERIF_PKG)/lib/uvm_agents/uvma_fencei
export DV_UVML_TRN_PATH         = $(CV_VERIF_PKG)/lib/uvm_libs/uvml_trn
export DV_UVML_LOGS_PATH        = $(CV_VERIF_PKG)/lib/uvm_libs/uvml_logs
export DV_UVML_SB_PATH          = $(CV_VERIF_PKG)/lib/uvm_libs/uvml_sb
export DV_UVML_MEM_PATH         = $(CV_VERIF_PKG)/lib/uvm_libs/uvml_mem

export DV_UVMC_RVFI_SCOREBOARD_PATH      = $(CV_VERIF_PKG)/lib/uvm_components/uvmc_rvfi_scoreboard/
export DV_UVMC_RVFI_REFERENCE_MODEL_PATH = $(CV_VERIF_PKG)/lib/uvm_components/uvmc_rvfi_reference_model/

export DV_OVPM_HOME             = $(CV_VERIF_PKG)/vendor_lib/imperas
export DV_OVPM_MODEL            = $(DV_OVPM_HOME)/imperas_DV_COREV

export DV_OVPM_DESIGN           = $(DV_OVPM_HOME)/design

export DV_SVLIB_PATH            = $(CV32E40X_DV)/vendor_lib/verilab

DV_UVMT_SRCS                  = $(wildcard $(DV_UVMT_PATH)/*.sv))

# Testcase name: must be the CLASS name of the testcase (not the filename).
# Look in ../../tests/uvmt
UVM_TEST_NAME ?= uvmt_$(CV_CORE_LC)_general_purpose_test_c
TEST_UVM_TEST ?= $(UVM_TEST_NAME)

# Google's random instruction generator
RISCVDV_PKG         := $(CV32E40X_DV)/$(CV_CORE_LC)/vendor_lib/google/riscv-dv
COREVDV_PKG         := $(CV32E40X_DV)/lib/corev-dv
CV_CORE_COREVDV_PKG := $(CV32E40X_DV)/$(CV_CORE_LC)/env/corev-dv
export RISCV_DV_ROOT         = $(RISCVDV_PKG)
export COREV_DV_ROOT         = $(COREVDV_PKG)
export CV_CORE_COREV_DV_ROOT = $(CV_CORE_COREVDV_PKG)

# RISC-V Foundation's RISC-V Compliance Test-suite
COMPLIANCE_PKG := $(CV32E40X_DV)/$(CV_CORE_LC)/vendor_lib/riscv/riscv-compliance

# EMBench benchmarking suite
EMBENCH_PKG    := $(CV32E40X_DV)/$(CV_CORE_LC)/vendor_lib/embench
EMBENCH_TESTS  := $(CV32E40X_DV)/$(CV_CORE_LC)/tests/programs/embench

# Disassembler
DPI_DASM_PKG               := $(CV_VERIF_PKG)/lib/dpi_dasm
DPI_DASM_SPIKE_PKG         := $(CV_VERIF_PKG)/vendor_lib/dpi_dasm_spike
export DPI_DASM_PKG         = $(CV_VERIF_PKG)/lib/dpi_dasm
export DPI_DASM_SPIKE_PKG   = $(CV_VERIF_PKG)/vendor_lib/dpi_dasm_spike
export DPI_DASM_ROOT        = $(DPI_DASM_PKG)
export DPI_DASM_SPIKE_ROOT  = $(DPI_DASM_SPIKE_PKG)

# TB source files for the CV32E core
#TBSRC_HOME  := $(CV32E40X_DV)/$(CV_CORE_LC)/tb
TBSRC_HOME  := $(CV32E40X_DV)/tb
TBSRC_TOP   := $(TBSRC_HOME)/uvmt/uvmt_$(CV_CORE_LC)_tb.sv
#export TBSRC_HOME = $(CV32E40X_DV)/$(CV_CORE_LC)/tb
export TBSRC_HOME = $(CV32E40X_DV)/tb

SIM_LIBS    := $(CV32E40X_DV)/lib/sim_libs

RTLSRC_VLOG_TB_TOP	:= $(basename $(notdir $(TBSRC_TOP)))
RTLSRC_VOPT_TB_TOP	:= $(addsuffix _vopt, $(RTLSRC_VLOG_TB_TOP))

# RTL source files for the CV32E core
# DESIGN_RTL_DIR is used by CV32E40P_MANIFEST file
CV_CORE_PKG          := $(CV32E40X_DV)/core-v-cores/$(CV_CORE_LC)
CV_CORE_MANIFEST     := $(CV_CORE_PKG)/$(CV_CORE_LC)_manifest.flist
export DESIGN_RTL_DIR = $(CV_CORE_PKG)/rtl

RTLSRC_HOME   := $(CV_CORE_PKG)/rtl
RTLSRC_INCDIR := $(RTLSRC_HOME)/include

# CORE-V-VERIF
#CV_VERIF_PKG        := $(CV32E40X_DV)/$(CV_CORE_LC)/vendor_lib/openhwgroup_core-v-verif
#export CV_VERIF_PKG  = $(CV32E40X_DV)/$(CV_CORE_LC)/vendor_lib/openhwgroup_core-v-verif
CV_VERIF_PKG        := $(CV32E40X_DV)/vendor_lib/openhwgroup_core-v-verif
export CV_VERIF_PKG  = $(CV32E40X_DV)/vendor_lib/openhwgroup_core-v-verif

# RVVI
#RVVI_HOME             := $(CV32E40X_DV)/$(CV_CORE_LC)/vendor_lib/riscv-verification/RVVI
#export RVVI_HOME       = $(CV32E40X_DV)/$(CV_CORE_LC)/vendor_lib/riscv-verification/RVVI
RVVI_HOME             := $(CV32E40X_DV)/vendor_lib/riscv-verification/RVVI
export RVVI_HOME       = $(CV32E40X_DV)/vendor_lib/riscv-verification/RVVI
RVVI_STUB             := $(RVVI_HOME)/../stubs
export RVVI_STUB       = $(RVVI_HOME)/../stubs
RVVI_IMPERASDV        := $(RVVI_HOME)/source/host/rvvi
export RVVI_IMPERASDV  = $(RVVI_HOME)/source/host/rvvi

###############################################################################
# Seed management for constrained-random sims
SEED    ?= 1
RNDSEED ?=

ifeq ($(SEED),random)
RNDSEED = $(shell date +%N)
else
ifeq ($(SEED),)
# Empty SEED variable selects 1
RNDSEED = 1
else
RNDSEED = $(SEED)
endif
endif

###############################################################################
# Common Makefile:
#    - Core Firmware and the RISCV GCC Toolchain (SDK)
#    - Variables for RTL dependencies
include $(CV32E40X_DV)/mk/Common.mk
###############################################################################
# Clone core RTL and DV dependencies
clone_cv_core_rtl: $(CV_CORE_PKG)

clone_riscv-dv: $(RISCVDV_PKG)

clone_embench: $(EMBENCH_PKG)

clone_compliance: $(COMPLIANCE_PKG)

clone_dpi_dasm_spike:
	$(CLONE_DPI_DASM_SPIKE_CMD)

$(CV_CORE_PKG):
	@echo "$(BANNER)"
	@echo "* Cloning the RTL for the $(CV_CORE_UC)"
	@echo "$(BANNER)"
	$(CLONE_CV_CORE_CMD)

$(RISCVDV_PKG):
	$(CLONE_RISCVDV_CMD)

$(COMPLIANCE_PKG):
	$(CLONE_COMPLIANCE_CMD)

$(EMBENCH_PKG):
	$(CLONE_EMBENCH_CMD)

$(DPI_DASM_SPIKE_PKG):
	$(CLONE_DPI_DASM_SPIKE_CMD)

$(CV_VERIF_PKG):
	@echo "$(BANNER)"
	@echo "* Cloning CORE-V-VERIF to $(CV_VERIF_PKG)"
	@echo "$(BANNER)"
	$(CLONE_CV_VERIF_CMD)

###############################################################################
# RISC-V Compliance Test-suite
#     As much as possible, the test suite is used "out-of-the-box".  The
#     "build_compliance" target below uses the Makefile supplied by the suite
#     to compile all the individual test-programs in the suite to generate the
#     elf and hex files used in simulation.  Each <sim>.mk is assumed to have a
#     target to run the compiled test-program.

# RISCV_ISA='rv32i|rv32im|rv32imc|rv32Zicsr|rv32Zifencei'
RISCV_ISA    ?= rv32i
RISCV_TARGET ?= OpenHW
RISCV_DEVICE ?= $(CV_CORE_LC)

clone_compliance:
	$(CLONE_COMPLIANCE_CMD)

clr_compliance:
	make clean -C $(CV32E40X_DV)/$(CV_CORE_LC)/vendor_lib/riscv/riscv-compliance

build_compliance: $(COMPLIANCE_PKG)
	make simulate -i -C $(CV32E40X_DV)/$(CV_CORE_LC)/vendor_lib/riscv/riscv-compliance \
		RISCV_TARGET=${RISCV_TARGET} \
		RISCV_DEVICE=${RISCV_DEVICE} \
		PATH=$(RISCV)/bin:$(PATH) \
		RISCV_PREFIX=$(RISCV_PREFIX) \
		NOTRAPS=1 \
		RISCV_ISA=$(RISCV_ISA)
#		VERBOSE=1

all_compliance: $(COMPLIANCE_PKG)
	make build_compliance RISCV_ISA=rv32i        && \
	make build_compliance RISCV_ISA=rv32im       && \
	make build_compliance RISCV_ISA=rv32imc      && \
	make build_compliance RISCV_ISA=rv32Zicsr    && \
	make build_compliance RISCV_ISA=rv32Zifencei

# "compliance" is a simulator-specific target defined in <sim>.mk
COMPLIANCE_RESULTS = $(SIM_RESULTS)

compliance_check_sig: compliance
	@echo "Checking Compliance Signature for $(RISCV_ISA)/$(COMPLIANCE_PROG)"
	@echo "Reference: $(REF)"
	@echo "Signature: $(SIG)"
	@export SUITEDIR=$(CV32E40X_DV)/$(CV_CORE_LC)/vendor_lib/riscv/riscv-compliance/riscv-test-suite/$(RISCV_ISA) && \
	export REF=$(REF) && export SIG=$(SIG) && export COMPL_PROG=$(COMPLIANCE_PROG) && \
	export RISCV_TARGET=${RISCV_TARGET} && export RISCV_DEVICE=${RISCV_DEVICE} && \
	export RISCV_ISA=${RISCV_ISA} export SIG_ROOT=${SIG_ROOT} && \
	$(CV32E40X_DV)/bin/diff_signatures.sh | tee $(COMPLIANCE_RESULTS)/$(CFG)/$(RISCV_ISA)/$(COMPLIANCE_PROG)/$(RUN_INDEX)/diff_signatures.log

compliance_check_all_sigs:
	@$(MKDIR_P) $(COMPLIANCE_RESULTS)/$(CFG)/$(RISCV_ISA)
	@echo "Checking Compliance Signature for all tests in $(CFG)/$(RISCV_ISA)"
	@export SUITEDIR=$(CV32E40X_DV)/$(CV_CORE_LC)/vendor_lib/riscv/riscv-compliance/riscv-test-suite/$(RISCV_ISA) && \
	export RISCV_TARGET=${RISCV_TARGET} && export RISCV_DEVICE=${RISCV_DEVICE} && \
	export RISCV_ISA=${RISCV_ISA} export SIG_ROOT=${SIG_ROOT} && \
	$(CV32E40X_DV)/bin/diff_signatures.sh $(RISCV_ISA) | tee $(COMPLIANCE_RESULTS)/$(CFG)/$(RISCV_ISA)/diff_signatures.log

compliance_regression:
	make build_compliance RISCV_ISA=$(RISCV_ISA)
	@export SIM_DIR=$(CV32E40X_DV)/$(CV_CORE_LC)/sim/uvmt && \
	$(CV32E40X_DV)/bin/run_compliance.sh $(RISCV_ISA)
	make compliance_check_all_sigs RISCV_ISA=$(RISCV_ISA)

dah:
	@export SIM_DIR=$(CV32E40X_DV)/cv32/sim/uvmt && \
	$(CV32E40X_DV)/bin/run_compliance.sh $(RISCV_ISA)

###############################################################################
# EMBench benchmark
# 	target to check out and run the EMBench suite for code size and speed
#

embench: $(EMBENCH_PKG)
	$(CV32E40X_DV)/bin/run_embench.py \
		-c $(CV_CORE) \
		-cc $(RISCV_EXE_PREFIX)$(RISCV_CC) \
		-sim $(SIMULATOR) \
		-t $(EMB_TYPE) \
		--timeout $(EMB_TIMEOUT) \
		--parallel $(EMB_PARALLEL_ARG) \
		-b $(EMB_BUILD_ONLY_ARG) \
		-tgt $(EMB_TARGET) \
		-f $(EMB_CPU_MHZ) \
		-d $(EMB_DEBUG_ARG)

###############################################################################
# ISACOV (ISA coverage)
#   Compare the log against the tracer log.
#   This checks that sampling went correctly without false positives/negatives.

ISACOV_LOGDIR = $(SIM_CFG_RESULTS)/$(TEST)/$(RUN_INDEX)
ISACOV_RVFILOG = $(ISACOV_LOGDIR)/uvm_test_top.env.rvfi_agent.trn.log
ISACOV_COVERAGELOG = $(ISACOV_LOGDIR)/uvm_test_top.env.isacov_agent.trn.log

isacov_logdiff:
	@echo isacov_logdiff:
	@echo checking that env/dirs/files are as expected...
		@printenv TEST > /dev/null || (echo specify TEST; false)
		@ls $(ISACOV_LOGDIR) > /dev/null
		@ls $(ISACOV_RVFILOG) > /dev/null
		@ls $(ISACOV_COVERAGELOG) > /dev/null
	@echo extracting assembly code from logs...
		@cat $(ISACOV_RVFILOG)                                                      \
			| awk -F ' - ' '{print $$2}' `#discard everything but the assembly` \
			| sed 's/ *#.*//'            `#discard comments`                    \
			| sed 's/ *<.*//'            `#discard symbol information`          \
			| sed 's/,/, /g'             `#add space after commas`              \
			| tail -n +4 > trace.tmp     `#don't include banner`
		@cat $(ISACOV_COVERAGELOG)                       \
			| awk -F '\t' '{print $$3}' `#discard everything but the assembly` \
			| sed 's/_/./'              `#convert "c_addi" to "c.addi" etc`    \
			| tail -n +2 > agent.tmp    `#don't include banner`
	@echo diffing the instruction sequences...
		@echo saving to $(ISACOV_LOGDIR)/isacov_logdiff
		@rm -rf $(ISACOV_LOGDIR)/isacov_logdiff
		@diff trace.tmp agent.tmp > $(ISACOV_LOGDIR)/isacov_logdiff; true
		@rm -rf trace.tmp agent.tmp
		@(test ! -s $(ISACOV_LOGDIR)/isacov_logdiff && echo OK) || (echo FAIL; false)

###############################################################################
# Include the targets/rules for the selected SystemVerilog simulator
#ifeq ($(SIMULATOR), unsim)
#include unsim.mk
#else
ifeq ($(SIMULATOR), dsim)
include $(CV32E40X_DV)/mk/uvmt/dsim.mk
else
ifeq ($(SIMULATOR), xrun)
include $(CV32E40X_DV)/mk/uvmt/xrun.mk
else
ifeq ($(SIMULATOR), vsim)
include $(CV32E40X_DV)/mk/uvmt/vsim.mk
else
ifeq ($(SIMULATOR), vcs)
include $(CV32E40X_DV)/mk/uvmt/vcs.mk
else
ifeq ($(SIMULATOR), riviera)
include $(CV32E40X_DV)/mk/uvmt/riviera.mk
else
include $(CV32E40X_DV)/mk/uvmt/unsim.mk
endif
endif
endif
endif
endif
#endif

################################################################################
# Open a DVT Eclipse IDE instance with the project imported automatically
ifeq ($(MAKECMDGOALS), open_in_dvt_ide)
include $(CV32E40X_DV)/mk/uvmt/dvt.mk
else
ifeq ($(MAKECMDGOALS), create_dvt_build_file)
include $(CV32E40X_DV)/mk/uvmt/dvt.mk
else
ifeq ($(MAKECMDGOALS), dvt_dump_env_vars)
include $(CV32E40X_DV)/mk/uvmt/dvt.mk
endif
endif
endif

################################################################################
# Display all the shell env vars defined in the Makefiles (handy debug tool).
# Note that some of these vars may be defined in 'included' Makefiles.
echo_env:
	@echo "ENV vars set in uvmt.mk:"
	@echo "   CV_CORE_LC                        = $(CV_CORE_LC)"
	@echo "   CV_CORE_UC                        = $(CV_CORE_UC)"
	@echo "   DV_UVMT_PATH                      = $(DV_UVMT_PATH)"
	@echo "   DV_UVME_PATH                      = $(DV_UVME_PATH)"
	@echo "   DV_UVML_HRTBT_PATH                = $(DV_UVML_HRTBT_PATH)"
	@echo "   DV_UVMA_CORE_CNTRL_PATH           = $(DV_UVMA_CORE_CNTRL_PATH)"
	@echo "   DV_UVMA_ISACOV_PATH               = $(DV_UVMA_ISACOV_PATH)"
	@echo "   DV_UVMA_RVFI_PATH                 = $(DV_UVMA_RVFI_PATH)"
	@echo "   DV_UVMA_RVVI_PATH                 = $(DV_UVMA_RVVI_PATH)"
	@echo "   DV_UVMA_RVVI_OVPSIM_PATH          = $(DV_UVMA_RVVI_OVPSIM_PATH)"
	@echo "   DV_UVMA_CLKNRST_PATH              = $(DV_UVMA_CLKNRST_PATH)"
	@echo "   DV_UVMA_INTERRUPT_PATH            = $(DV_UVMA_INTERRUPT_PATH)"
	@echo "   DV_UVMA_DEBUG_PATH                = $(DV_UVMA_DEBUG_PATH)"
	@echo "   DV_UVMA_PMA_PATH                  = $(DV_UVMA_PMA_PATH)"
	@echo "   DV_UVMA_OBI_MEMORY_PATH           = $(DV_UVMA_OBI_MEMORY_PATH)"
	@echo "   DV_UVMA_FENCEI_PATH               = $(DV_UVMA_FENCEI_PATH)"
	@echo "   DV_UVML_TRN_PATH                  = $(DV_UVML_TRN_PATH)"
	@echo "   DV_UVML_LOGS_PATH                 = $(DV_UVML_LOGS_PATH)"
	@echo "   DV_UVML_SB_PATH                   = $(DV_UVML_SB_PATH)"
	@echo "   DV_UVML_MEM_PATH                  = $(DV_UVML_MEM_PATH)"
	@echo "   DV_UVMC_RVFI_SCOREBOARD_PATH      = $(DV_UVMC_RVFI_SCOREBOARD_PATH)"
	@echo "   DV_UVMC_RVFI_REFERENCE_MODEL_PATH = $(DV_UVMC_RVFI_REFERENCE_MODEL_PATH)"
	@echo "   DV_OVPM_HOME                      = $(DV_OVPM_HOME)"
	@echo "   DV_OVPM_MODEL                     = $(DV_OVPM_MODEL)"
	@echo "   DV_OVPM_DESIGN                    = $(DV_OVPM_DESIGN)"
	@echo "   DV_SVLIB_PATH                     = $(DV_SVLIB_PATH)"
	@echo "   SVLIB_PKG                         = $(SVLIB_PKG)"
	@echo "   CV_VERIF_PKG                      = $(CV_VERIF_PKG)"
	@echo "   RISCV_DV_ROOT                     = $(RISCV_DV_ROOT)"
	@echo "   COREV_DV_ROOT                     = $(COREV_DV_ROOT)"
	@echo "   CV_CORE_COREV_DV_ROOT             = $(CV_CORE_COREV_DV_ROOT)"
	@echo "   DPI_DASM_ROOT                     = $(DPI_DASM_ROOT)"
	@echo "   DPI_DASM_SPIKE_ROOT               = $(DPI_DASM_SPIKE_ROOT)"
	@echo "   TBSRC_HOME                        = $(TBSRC_HOME)"
	@echo "   RVVI_HOME                         = $(RVVI_HOME)"
	@echo "   RVVI_STUB                         = $(RVVI_STUB)"
	@echo "   RVVI_IMPERASDV                    = $(RVVI_IMPERASDV)"
	@echo "   DESIGN_RTL_DIR                    = $(DESIGN_RTL_DIR)"

###############################################################################
# Clean up your mess!
#   1. Clean all generated files of the C and assembler tests
#   2. Simulator-specific clean targets are in ./<simulator>.mk
#   3. clean_bsp target is specified in ../Common.mk
clean_rtl:
	rm -rf $(CV_CORE_PKG)

clean_hex:
	rm -rf $(SIM_TEST_PROGRAM_RESULTS)

clean_test_programs: clean_bsp
	if [ -d "$(SIM_RESULTS)" ]; then \
		find $(SIM_RESULTS) -depth -type d -name test_program | xargs rm -rf; \
	fi

clean_riscv-dv:
	rm -rf $(RISCVDV_PKG)
	rm -rf $(COREVDV_PKG)/out_*

clean_compliance:
	rm -rf $(COMPLIANCE_PKG)

clean_embench:
	rm -rf $(EMBENCH_PKG)
	cd $(EMBENCH_TESTS) && \
		find . ! -path . ! -path ./README.md -delete
	if [ -d "$(SIM_RESULTS)" ]; then \
		cd $(SIM_RESULTS) && find . -depth -type d -name "emb_*" | xargs rm -rf; \
	fi

clean_dpi_dasm_spike:
	rm -rf $(DPI_DASM_SPIKE_PKG)

clean_core_v_verif:
	rm -rf $(CV_VERIF_PKG)

clean_rvvi_stub:
	rm -rf $(RVVI_STUB_LIB)
