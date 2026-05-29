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
# Common code for simulation Makefiles.
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

###############################################################################
# Common functions

# Map multiple flag values to "YES" or NO
# Use like this, to test variable MYVAR
# ifeq ($(call IS_YES($(MYVAR)),YES)
YES_VALS=Y YES 1 y yes TRUE true
IS_YES=$(if $(filter $(YES_VALS),$(1)),YES,NO)
NO_VALS=N NO 0 n no FALSE false
IS_NO=$(if $(filter $(NO_VALS),$(1)),NO,YES)

# Resolve flags for tool options in precdence order
# Call as: MY_FLAG=$(call RESOLVE_FLAG3,$(FIRST),$(SECOND))
# The first resolved variable in order of FIRST,SECOND will be assigned to MY_FLAG
RESOLVE_FLAG2=$(if $(1),$(1),$(2))

###############################################################################
# Common variables
BANNER=*******************************************************************************************

###############################################################################
# Fetch commands
ifndef CV_CORE_REPO
$(error Must define a CV_CORE_REPO to use the common makefile)
endif

ifndef RISCVDV_REPO
$(error Must define a RISCVDV_REPO to use the common makefile)
endif

ifndef EMBENCH_REPO
$(warning Must define a EMBENCH_REPO to use the common makefile)
endif

ifndef COMPLIANCE_REPO
$(error Must define a COMPLIANCE_REPO to use the common makefile)
endif

# TODO: uncomment when Spike is integrated
#ifndef DPI_DASM_SPIKE_REPO
#$(warning Must define a DPI_DASM_SPIKE_REPO to use the common makefile)
#endif

###############################################################################
# Generate command to clone or symlink the core RTL
ifeq ($(CV_CORE_PATH),)
  ifeq ($(CV_CORE_BRANCH), master)
    TMP = git clone $(CV_CORE_REPO) $(CV_CORE_PKG)
  else
    TMP = git clone -b $(CV_CORE_BRANCH) --single-branch $(CV_CORE_REPO) $(CV_CORE_PKG)
  endif

  # If head is not specified, get a specific hash
  ifeq ($(CV_CORE_HASH), head)
    CLONE_CV_CORE_CMD = $(TMP)
  else
      CLONE_CV_CORE_CMD = $(TMP); cd $(CV_CORE_PKG); git checkout $(CV_CORE_HASH)
  endif
else
  CLONE_CV_CORE_CMD = ln -s $(CV_CORE_PATH) $(CV_CORE_PKG)
endif

###############################################################################
# Generate command to clone RISCV-DV (Google's random instruction generator)
ifeq ($(RISCVDV_BRANCH), master)
  TMP3 = git clone $(RISCVDV_REPO) --recurse $(RISCVDV_PKG)
else
  TMP3 = git clone -b $(RISCVDV_BRANCH) --single-branch $(RISCVDV_REPO) --recurse $(RISCVDV_PKG)
endif

ifeq ($(RISCVDV_HASH), head)
  CLONE_RISCVDV_CMD = $(TMP3)
else
  CLONE_RISCVDV_CMD = $(TMP3); cd $(RISCVDV_PKG); git checkout $(RISCVDV_HASH)
endif
# RISCV-DV repo var end

###############################################################################
# Generate command to clone the RISCV Compliance Test-suite
ifeq ($(COMPLIANCE_BRANCH), master)
  TMP4 = git clone $(COMPLIANCE_REPO) --recurse $(COMPLIANCE_PKG)
else
  TMP4 = git clone -b $(COMPLIANCE_BRANCH) --single-branch $(COMPLIANCE_REPO) --recurse $(COMPLIANCE_PKG)
endif

ifeq ($(COMPLIANCE_HASH), head)
  CLONE_COMPLIANCE_CMD = $(TMP4)
else
  CLONE_COMPLIANCE_CMD = $(TMP4); cd $(COMPLIANCE_PKG); sleep 2; git checkout $(COMPLIANCE_HASH)
endif
# RISCV Compliance repo var end

###############################################################################
# Generate command to clone EMBench (Embedded Benchmarking suite)
ifeq ($(EMBENCH_BRANCH), master)
  TMP5 = git clone $(EMBENCH_REPO) --recurse $(EMBENCH_PKG)
else
  TMP5 = git clone -b $(EMBENCH_BRANCH) --single-branch $(EMBENCH_REPO) --recurse $(EMBENCH_PKG)
endif

ifeq ($(EMBENCH_HASH), head)
  CLONE_EMBENCH_CMD = $(TMP5)
else
  CLONE_EMBENCH_CMD = $(TMP5); cd $(EMBENCH_PKG); git checkout $(EMBENCH_HASH)
endif
# EMBench repo var end

###############################################################################
# Generate command to clone Spike for the Disassembler DPI (used in the isacov model)
ifeq ($(DPI_DASM_SPIKE_BRANCH), master)
  TMP7 = git clone $(DPI_DASM_SPIKE_REPO) --recurse $(DPI_DASM_SPIKE_PKG)
else
  TMP7 = git clone -b $(DPI_DASM_SPIKE_BRANCH) --single-branch $(DPI_DASM_SPIKE_REPO) --recurse $(DPI_DASM_SPIKE_PKG)
endif

ifeq ($(DPI_DASM_SPIKE_HASH), head)
  CLONE_DPI_DASM_SPIKE_CMD = $(TMP7)
else
  CLONE_DPI_DASM_SPIKE_CMD = $(TMP7); cd $(DPI_DASM_SPIKE_PKG); git checkout $(DPI_DASM_SPIKE_HASH)
endif
# DPI_DASM Spike repo var end

###############################################################################
# Generate command to clone Verilab SVLIB
ifeq ($(SVLIB_BRANCH), master)
  TMP8 = git clone $(SVLIB_REPO) --recurse $(SVLIB_PKG)
else
  TMP8 = git clone -b $(SVLIB_BRANCH) --single-branch $(SVLIB_REPO) --recurse $(SVLIB_PKG)
endif

ifeq ($(SVLIB_HASH), head)
  CLONE_SVLIB_CMD = $(TMP8)
else
  CLONE_SVLIB_CMD = $(TMP8); cd $(SVLIB_PKG); git checkout $(SVLIB_HASH)
endif
# SVLIB repo var end

###############################################################################
# Generate command to clone CORE-V-VERIF (OpenHW's UVM Verification Library)
ifeq ($(CV_VERIF_BRANCH), master)
  TMP9 = git clone $(CV_VERIF_REPO) --recurse $(CV_VERIF_PKG)
else
  TMP9 = git clone -b $(CV_VERIF_BRANCH) --single-branch $(CV_VERIF_REPO) --recurse $(CV_VERIF_PKG)
endif

ifeq ($(CV_VERIF_HASH), head)
  CLONE_CV_VERIF_CMD = $(TMP9)
else
  CLONE_CV_VERIF_CMD = $(TMP9); cd $(CV_VERIF_PKG); git checkout $(CV_VERIF_HASH)
endif
# CORE-V-VERIF repo var end

###############################################################################
# Generate command to clone RISC-V Architectural Certification Tests (ACT4)
ifeq ($(ACT4_BRANCH), master)
  TMP10 = git clone $(ACT4_REPO) $(ACT4_PKG)
else
  TMP10 = git clone -b $(ACT4_BRANCH) --single-branch $(ACT4_REPO) $(ACT4_PKG)
endif

ifeq ($(ACT4_HASH), head)
  CLONE_ACT4_CMD = $(TMP10)
else
  CLONE_ACT4_CMD = $(TMP10); cd $(ACT4_PKG); git checkout $(ACT4_HASH)
endif
# ACT4 repo var end

###############################################################################
# Run the yaml2make scripts

ifeq ($(VERBOSE),1)
YAML2MAKE_DEBUG = --debug
else
YAML2MAKE_DEBUG =
endif

###############################################################################
# Fetch CV_SW_ variables from the TEST yaml
# If the gen_corev-dv target is defined then read in a test defintions file
YAML2MAKE = $(CV32E40X_DV)/bin/yaml2make
ifneq ($(filter gen_corev-dv,$(MAKECMDGOALS)),)
  $(info MAKECMDGOALS contains gen_corev-dv)
  ifeq ($(TEST),)
    $(error ERROR must specify a TEST variable with gen_corev-dv target)
  endif
  GEN_FLAGS_MAKE := $(shell $(YAML2MAKE) --test=$(TEST) --yaml=corev-dv.yaml $(YAML2MAKE_DEBUG) --prefix=GEN --core=$(CV_CORE))
  ifeq ($(GEN_FLAGS_MAKE),)
    $(error ERROR Could not find corev-dv.yaml for test: $(TEST))
  endif
  include $(GEN_FLAGS_MAKE)
else
  $(info MAKECMDGOALS=$(MAKECMDGOALS) not in set: gen_corev-dv)
endif

###############################################################################
# Generate and include TEST_FLAGS_MAKE, based on the YAML test description.
# An example of what is generated is below (not all of these flags are used):
#       TEST_DESCRIPTION=Simple hello-world sanity test
#       TEST_NAME=hello-world
#       TEST_PROGRAM=hello-world
#       TEST_TEST_DIR=/home/mike/GitHubRepos/MikeOpenHWGroup/core-v-verif/master/cv32e40p/tests/programs/custom/hello-world
#       TEST_UVM_TEST=uvmt_$(CV_CORE_LC)_firmware_test_c
TEST_YAML_PARSE_TARGETS=test waves cov hex clean_hex veri-test dsim-test xrun-test bsp check
ifneq ($(filter $(TEST_YAML_PARSE_TARGETS),$(MAKECMDGOALS)),)
  $(info MAKECMDGOALS=$(MAKECMDGOALS) is contained in TEST_YAML_PARSE_TARGETS=$(TEST_YAML_PARSE_TARGETS))
  ifeq ($(TEST),)
    $(error ERROR! must specify a TEST variable)
  endif
  TEST_FLAGS_MAKE := $(shell $(YAML2MAKE) --test=$(TEST) --yaml=test.yaml  $(YAML2MAKE_DEBUG) --run-index=$(u) --prefix=TEST --core=$(CV_CORE))
  ifeq ($(TEST_FLAGS_MAKE),)
    $(error ERROR Could not find test.yaml for test: $(TEST))
  endif
  include $(TEST_FLAGS_MAKE)
else
  $(info MAKECMDGOALS=$(MAKECMDGOALS) not in set: TEST_YAML_PARSE_TARGETS=$(TEST_YAML_PARSE_TARGETS))
endif

###############################################################################
# Generate and include CFG_FLAGS_MAKE, based on the YAML test description.
CFGYAML2MAKE = $(CV32E40X_DV)/bin/cfgyaml2make
CFG_YAML_PARSE_TARGETS=comp ldgen comp_corev-dv gen_corev-dv test hex clean_hex corev-dv sanity-veri-run bsp check
ifneq ($(filter $(CFG_YAML_PARSE_TARGETS),$(MAKECMDGOALS)),)
  $(info MAKECMDGOALS=$(MAKECMDGOALS) is contained in CFG_YAML_PARSE_TARGETS=$(CFG_YAML_PARSE_TARGETS))
  ifeq ($(CFG),)
    $(info CFG variable not specified)
  else
    $(info CFG=$(CFG))
  endif
  CFG_FLAGS_MAKE := $(shell $(CFGYAML2MAKE) --yaml=$(CFG).yaml $(YAML2MAKE_DEBUG) --prefix=CFG --core=$(CV_CORE))
  ifeq ($(CFG_FLAGS_MAKE),)
    $(error ERROR Error finding or parsing configuration: $(CFG).yaml)
  endif
  include $(CFG_FLAGS_MAKE)
else
  $(info MAKECMDGOALS=$(MAKECMDGOALS) not in set: CFG_YAML_PARSE_TARGETS=$(CFG_YAML_PARSE_TARGETS))
endif

###############################################################################
# Determine the values of the CV_SW_ variables.
# The priority order is ENV > TEST > CFG.
ifndef __ALWAYS_PRINT_THESE_MSGS__
  $(info *******************************************************************************************)
  $(info * Values of the CV_SW_* variables:)
  $(info *******************************************************************************************)
else
  $(error __ALWAYS_PRINT_THESE_MSGS__ should not be defined.)
endif

ifndef CV_SW_TOOLCHAIN
  ifdef  TEST_CV_SW_TOOLCHAIN
    CV_SW_TOOLCHAIN = $(TEST_CV_SW_TOOLCHAIN)
    $(info CV_SW_TOOLCHAIN = $(CV_SW_TOOLCHAIN))
  else
    ifdef  CFG_CV_SW_TOOLCHAIN
      CV_SW_TOOLCHAIN = $(CFG_CV_SW_TOOLCHAIN)
      $(info CV_SW_TOOLCHAIN = $(CV_SW_TOOLCHAIN))
    else
      $(error CV_SW_TOOLCHAIN not defined in either the shell environment, test.yaml or cfg.yaml)
    endif
  endif
else
  $(info CV_SW_TOOLCHAIN = $(CV_SW_TOOLCHAIN))
endif

ifndef CV_SW_PREFIX
  ifdef  TEST_CV_SW_PREFIX
    CV_SW_PREFIX = $(TEST_CV_SW_PREFIX)
    $(info CV_SW_PREFIX = $(CV_SW_PREFIX))
  else
    ifdef  CFG_CV_SW_PREFIX
      CV_SW_PREFIX = $(CFG_CV_SW_PREFIX)
      $(info CV_SW_PREFIX = $(CV_SW_PREFIX))
    else
      $(error CV_SW_PREFIX not defined in either the shell environment, test.yaml or cfg.yaml)
    endif
  endif
else
  $(info CV_SW_PREFIX = $(CV_SW_PREFIX))
endif

ifndef CV_SW_MARCH
  ifdef  TEST_CV_SW_MARCH
    CV_SW_MARCH = $(TEST_CV_SW_MARCH)
    $(info CV_SW_MARCH = $(CV_SW_MARCH))
  else
    ifdef  CFG_CV_SW_MARCH
      CV_SW_MARCH = $(CFG_CV_SW_MARCH)
      $(info CV_SW_MARCH = $(CV_SW_MARCH))
    else
      CV_SW_MARCH = rv32imc
      $(error CV_SW_MARCH not defined in either the shell environment, test.yaml or cfg.yaml)
    endif
  endif
else
  $(info CV_SW_MARCH = $(CV_SW_MARCH))
endif

ifndef CV_SW_CC
  ifdef  TEST_CV_SW_CC
    CV_SW_CC = $(TEST_CV_SW_CC)
    $(info CV_SW_CC = $(CV_SW_CC))
  else
    ifdef  CFG_CV_SW_CC
      CV_SW_CC = $(CFG_CV_SW_CC)
      $(info CV_SW_CC = $(CV_SW_CC))
    else
      CV_SW_CC = gcc
      $(info CV_SW_CC not defined in either the shell environment, test.yaml or cfg.yaml - setting to $(CV_SW_CC))
    endif
  endif
else
  $(info CV_SW_CC = $(CV_SW_CC))
endif

# TODO: add CV_SW_CFLAG to YAML2MAKE
#ifndef CV_SW_CFLAGS
#  ifdef  TEST_CV_SW_CFLAGS
#    CV_SW_CFLAGS = $(TEST_CV_SW_CFLAGS)
#  else
#    ifdef  CFG_CV_SW_CFLAGS
#      CV_SW_CFLAGS = $(CFG_CV_SW_CFLAGS)
#    else
#      $(error CV_SW_CFLAGS not defined in either the shell environment, test.yaml or cfg.yaml)
#    endif
#  endif
#else
#  $(info CV_SW_CFLAGS = $(CV_SW_CFLAGS))
#endif

###############################################################################
# Determine the values of the RISC_ variables.

RISCV            = $(CV_SW_TOOLCHAIN)
RISCV_PREFIX     = $(CV_SW_PREFIX)
RISCV_EXE_PREFIX = $(RISCV)/bin/$(RISCV_PREFIX)

RISCV_MARCH      = $(CV_SW_MARCH)
RISCV_CC         = $(CV_SW_CC)
RISCV_CFLAGS     = $(CV_SW_CFLAGS)

#CFLAGS ?= -Os -g -static -mabi=ilp32 -march=$(RISCV_MARCH) -Wall -pedantic $(RISCV_CFLAGS)
CFLAGS ?= -Os -g -static -mabi=ilp32 -march=$(RISCV_MARCH) $(RISCV_CFLAGS)

ifndef __ALWAYS_PRINT_THESE_MSGS__
  $(info *******************************************************************************************)
  $(info * Values of the RISCV_* variables:)
  $(info *******************************************************************************************)
else
  $(error __ALWAYS_PRINT_THESE_MSGS__ should not be defined.)
endif
$(info RISCV            = $(RISCV))
$(info RISCV_PREFIX     = $(RISCV_PREFIX))
$(info RISCV_EXE_PREFIX = $(RISCV_EXE_PREFIX))
$(info RISCV_MARCH      = $(RISCV_MARCH))
$(info RISCV_CC         = $(RISCV_CC))
$(info RISCV_CFLAGS     = $(RISCV_CFLAGS))

# TODO: are these still necessary?
ASM       ?= ../../tests/asm
ASM_DIR   ?= $(ASM)

###############################################################################
# CORE FIRMWARE vars. The C and assembler test-programs
# were once collectively known as "Core Firmware".
# TODO: are these still necessary?
#
# Note that the DSIM targets allow for writing the log-files to arbitrary
# locations, so all of these paths are absolute, except those used by Verilator.
#CORE_TEST_DIR                        = $(CV32E40X_DV)/$(CV_CORE_LC)/tests/programs
#BSP                                  = $(CV32E40X_DV)/$(CV_CORE_LC)/bsp
CORE_TEST_DIR                        = $(CV32E40X_DV)/tests/programs
BSP                                  = $(CV32E40X_DV)/bsp
FIRMWARE                             = $(CORE_TEST_DIR)/firmware
VERI_FIRMWARE                        = ../../tests/core/firmware
ASM_PROG                            ?= my_hello_world
CV32_RISCV_TESTS_FIRMWARE            = $(CORE_TEST_DIR)/cv32_riscv_tests_firmware
CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE = $(CORE_TEST_DIR)/cv32_riscv_compliance_tests_firmware
RISCV_TESTS                          = $(CORE_TEST_DIR)/riscv_tests
RISCV_COMPLIANCE_TESTS               = $(CORE_TEST_DIR)/riscv_compliance_tests
RISCV_TEST_INCLUDES                  = -I$(CORE_TEST_DIR)/riscv_tests/ \
                                       -I$(CORE_TEST_DIR)/riscv_tests/macros/scalar \
                                       -I$(CORE_TEST_DIR)/riscv_tests/rv64ui \
                                       -I$(CORE_TEST_DIR)/riscv_tests/rv64um
CV32_RISCV_TESTS_FIRMWARE_OBJS       = $(addprefix $(CV32_RISCV_TESTS_FIRMWARE)/, \
                                         start.o print.o sieve.o multest.o stats.o)
CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE_OBJS = $(addprefix $(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/, \
                                              start.o print.o sieve.o multest.o stats.o)
RISCV_TESTS_OBJS         = $(addsuffix .o, \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32ui/*.S)) \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32um/*.S)) \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32uc/*.S)))
FIRMWARE_OBJS            = $(addprefix $(FIRMWARE)/, \
                             start.o print.o sieve.o multest.o stats.o)
FIRMWARE_TEST_OBJS       = $(addsuffix .o, \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32ui/*.S)) \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32um/*.S)) \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32uc/*.S)))
FIRMWARE_SHORT_TEST_OBJS = $(addsuffix .o, \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32ui/*.S)) \
                             $(basename $(wildcard $(RISCV_TESTS)/rv32um/*.S)))
COMPLIANCE_TEST_OBJS     = $(addsuffix .o, \
                             $(basename $(wildcard $(RISCV_COMPLIANCE_TESTS)/*.S)))


# Thales verilator testbench compilation start

SUPPORTED_COMMANDS := vsim-firmware-unit-test questa-unit-test questa-unit-test-gui dsim-unit-test vcs-unit-test
SUPPORTS_MAKE_ARGS := $(filter $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))

ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  UNIT_TEST := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(UNIT_TEST):;@:)
  UNIT_TEST_CMD := 1
else
 UNIT_TEST_CMD := 0
endif

COMPLIANCE_UNIT_TEST = $(subst _,-,$(UNIT_TEST))

FIRMWARE_UNIT_TEST_OBJS   =  	$(addsuffix .o, \
				$(basename $(wildcard $(RISCV_TESTS)/rv32*/$(UNIT_TEST).S)) \
				$(basename $(wildcard $(RISCV_COMPLIANCE_TESTS)*/$(COMPLIANCE_UNIT_TEST).S)))

# Thales verilator testbench compilation end

###############################################################################
# Rule to generate hex (loadable by simulators) from elf
#    $@ is the file being generated.
#    $< is first prerequiste.
#    $^ is all prerequistes.
#    $* is file_name (w/o extension) of target
%.hex: %.elf
	@echo "$(BANNER)"
	@echo "* Generating hexfile, readelf and objdump files"
	@echo "$(BANNER)"
	$(RISCV_EXE_PREFIX)objcopy -O verilog \
		$< \
		$@
	$(RISCV_EXE_PREFIX)readelf -a $< > $*.readelf
	$(RISCV_EXE_PREFIX)objdump \
		-d \
		-M no-aliases \
		-M numeric \
		-S \
		$*.elf > $*.objdump
	$(RISCV_EXE_PREFIX)objdump \
		-d \
		-S \
		-M no-aliases \
		-M numeric \
		-l \
		$*.elf | $(CV32E40X_DV)/bin/objdump2itb - > $*.itb

# Patterned targets to generate ELF.  Used only if explicit targets do not match.
#
.PRECIOUS : %.elf

# Single rule for compiling test source into an ELF file
# For directed tests, TEST_FILES gathers all of the .S and .c files in a test directory
# For corev_ tests, TEST_FILES will only point to the specific .S for the RUN_INDEX and TEST_NAME provided to make
ifeq ($(shell echo $(TEST) | head -c 6),corev_)
TEST_FILES        = $(filter %.c %.S,$(wildcard  $(SIM_TEST_PROGRAM_RESULTS)/$(TEST_NAME)$(OPT_RUN_INDEX_SUFFIX).S))
else
TEST_FILES        = $(filter %.c %.S,$(wildcard  $(TEST_TEST_DIR)/*))
endif

# If a test defines "default_cflags" in its yaml, then it is responsible to define ALL flags
# Otherwise add the default cflags in the variable CFLAGS defined above
ifneq ($(TEST_DEFAULT_CFLAGS),)
TEST_CFLAGS += $(TEST_DEFAULT_CFLAGS)
else
TEST_CFLAGS += $(CFLAGS)
endif

# Optionally use linker script provided in test directory
# this must be evaluated at access time, so ifeq/ifneq does
# not get parsed correctly
TEST_RESULTS_LD = $(addprefix $(SIM_TEST_PROGRAM_RESULTS)/, link.ld)
TEST_LD         = $(addprefix $(TEST_TEST_DIR)/, link.ld)

LD_LIBRARY 	= $(if $(wildcard $(TEST_RESULTS_LD)),-L $(SIM_TEST_PROGRAM_RESULTS),$(if $(wildcard $(TEST_LD)),-L $(TEST_TEST_DIR),))
LD_FILE 	= $(if $(wildcard $(TEST_RESULTS_LD)),$(TEST_RESULTS_LD),$(if $(wildcard $(TEST_LD)),$(TEST_LD),$(BSP)/link.ld))
LD_LIBRARY += -L $(SIM_BSP_RESULTS)

ifeq ($(TEST_FIXED_ELF),1)
%.elf:
	@echo "$(BANNER)"
	@echo "* Copying fixed ELF test program to $(@)"
	@echo "$(BANNER)"
	mkdir -p $(SIM_TEST_PROGRAM_RESULTS)
	cp $(TEST_TEST_DIR)/$(TEST).elf $@
else
ifeq ($(TEST_ACT),1)
%.elf: $(TEST_FILES)
	mkdir -p $(SIM_TEST_PROGRAM_RESULTS)
	make bsp ACT=1
	@echo "$(BANNER)"
	@echo "* Compiling ACT test-program $@"
	@echo "$(BANNER)"
	$(RISCV_EXE_PREFIX)$(RISCV_CC) \
		$(CFG_CFLAGS) \
		$(TEST_CFLAGS) \
		$(RISCV_CFLAGS) \
		-DSELFCHECK -DSIGNATURE -DXLEN=32 -DFLEN=32 \
		-I $(BSP) \
		-I $(ACT_MACROS) \
		-o $@ \
		-nostartfiles \
		$(TEST_FILES) \
		-T $(LD_FILE) \
		$(LD_LIBRARY)
#		-Wno-variadic-macros \
#		-lcv-verif

else
%.elf: $(TEST_FILES)
	mkdir -p $(SIM_TEST_PROGRAM_RESULTS)
	make bsp
	@echo "$(BANNER)"
	@echo "* Compiling test-program $@"
	@echo "$(BANNER)"
	$(RISCV_EXE_PREFIX)$(RISCV_CC) \
		$(CFG_CFLAGS) \
		$(TEST_CFLAGS) \
		$(RISCV_CFLAGS) \
		-I $(ASM) \
		-I $(BSP) \
		-o $@ \
		-nostartfiles \
		$(TEST_FILES) \
		-T $(LD_FILE) \
		$(LD_LIBRARY) \
		-lcv-verif
endif
endif

.PHONY: hex

# Shorthand target to only build the firmware using the hex and elf suffix rules above
hex: $(SIM_TEST_PROGRAM_RESULTS)/$(TEST_PROGRAM)$(OPT_RUN_INDEX_SUFFIX).hex

bsp:
	@echo "$(BANNER)"
	@echo "* Compiling the BSP"
	@echo "$(BANNER)"
	mkdir -p $(SIM_BSP_RESULTS)
	cp $(BSP)/Makefile $(SIM_BSP_RESULTS)
	make -C $(SIM_BSP_RESULTS) \
		VPATH=$(BSP) \
		ACT=$(ACT) \
		RISCV=$(RISCV) \
		RISCV_PREFIX=$(RISCV_PREFIX) \
		RISCV_EXE_PREFIX=$(RISCV_EXE_PREFIX) \
		RISCV_MARCH=$(RISCV_MARCH) \
		CV_SW_MARCH=$(RISCV_MARCH) \
		RISCV_CC=$(RISCV_CC) \
		RISCV_CFLAGS="$(RISCV_CFLAGS)" \
		all

vars_bsp:
	make vars -C $(BSP) RISCV=$(RISCV) RISCV_PREFIX=$(RISCV_PREFIX) RISCV_EXE_PREFIX=$(RISCV_EXE_PREFIX) RISCV_MARCH=$(RISCV_MARCH)

clean_bsp:
	make -C $(BSP) clean
	rm -rf $(SIM_BSP_RESULTS)


# compile and dump RISCV_TESTS only
#$(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.elf: $(CV32_RISCV_TESTS_FIRMWARE_OBJS) $(RISCV_TESTS_OBJS) \
#							$(CV32_RISCV_TESTS_FIRMWARE)/link.ld
#	$(RISCV_EXE_PREFIX)gcc -g -Os -mabi=ilp32 -march=rv32imc -ffreestanding -nostdlib -o $@ \
#		$(RISCV_TEST_INCLUDES) \
#		-Wl,-Bstatic,-T,$(CV32_RISCV_TESTS_FIRMWARE)/link.ld,-Map,$(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.map,--strip-debug \
#		$(CV32_RISCV_TESTS_FIRMWARE_OBJS) $(RISCV_TESTS_OBJS) -lgcc

#$(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.elf: $(CV32_RISCV_TESTS_FIRMWARE_OBJS) $(RISCV_TESTS_OBJS) \
#							$(CV32_RISCV_TESTS_FIRMWARE)/link.ld
../../tests/core/cv32_riscv_tests_firmware/cv32_riscv_tests_firmware.elf: $(CV32_RISCV_TESTS_FIRMWARE_OBJS) $(RISCV_TESTS_OBJS)
	$(RISCV_EXE_PREFIX)gcc $(CFLAGS) -ffreestanding -nostdlib -o $@ \
		$(RISCV_TEST_INCLUDES) \
		-Wl,-Bstatic,-T,$(CV32_RISCV_TESTS_FIRMWARE)/link.ld,-Map,$(CV32_RISCV_TESTS_FIRMWARE)/cv32_riscv_tests_firmware.map,--strip-debug \
		$(CV32_RISCV_TESTS_FIRMWARE_OBJS) $(RISCV_TESTS_OBJS) -lgcc

$(CV32_RISCV_TESTS_FIRMWARE)/start.o: $(CV32_RISCV_TESTS_FIRMWARE)/start.S
	$(RISCV_EXE_PREFIX)gcc -c $(CFLAGS) -o $@ $<

$(CV32_RISCV_TESTS_FIRMWARE)/%.o: $(CV32_RISCV_TESTS_FIRMWARE)/%.c
	$(RISCV_EXE_PREFIX)gcc -c $(CFLAGS) --std=c99 -Wall \
		$(RISCV_TEST_INCLUDES) \
		-ffreestanding -nostdlib -o $@ $<

# compile and dump RISCV_COMPLIANCE_TESTS only
$(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/cv32_riscv_compliance_tests_firmware.elf: $(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE_OBJS) $(COMPLIANCE_TEST_OBJS) \
							$(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/link.ld
	$(RISCV_EXE_PREFIX)gcc $(CFLAGS) -ffreestanding -nostdlib -o $@ \
		-D RUN_COMPLIANCE \
		$(RISCV_TEST_INCLUDES) \
		-Wl,-Bstatic,-T,$(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/link.ld,-Map,$(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/cv32_riscv_compliance_tests_firmware.map,--strip-debug \
		$(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE_OBJS) $(COMPLIANCE_TEST_OBJS) -lgcc

$(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/start.o: $(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/start.S
	$(RISCV_EXE_PREFIX)gcc -c $(CFLAGS) -D RUN_COMPLIANCE -o $@ $<

$(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/%.o: $(CV32_RISCV_COMPLIANCE_TESTS_FIRMWARE)/%.c
	$(RISCV_EXE_PREFIX)gcc -c $(CFLAGS) --std=c99 -Wall \
		$(RISCV_TEST_INCLUDES) \
		-ffreestanding -nostdlib -o $@ $<

# compile and dump picorv firmware

# Thales start
$(FIRMWARE)/firmware_unit_test.elf: $(FIRMWARE_OBJS) $(FIRMWARE_UNIT_TEST_OBJS) $(FIRMWARE)/link.ld
	$(RISCV_EXE_PREFIX)gcc $(CFLAGS) -ffreestanding -nostdlib -o $@ \
		$(RISCV_TEST_INCLUDES) \
		-D RUN_COMPLIANCE \
		-Wl,-Bstatic,-T,$(FIRMWARE)/link.ld,-Map,$(FIRMWARE)/firmware.map,--strip-debug \
		$(FIRMWARE_OBJS) $(FIRMWARE_UNIT_TEST_OBJS) -lgcc
# Thales end

$(FIRMWARE)/firmware.elf: $(FIRMWARE_OBJS) $(FIRMWARE_TEST_OBJS) $(COMPLIANCE_TEST_OBJS) $(FIRMWARE)/link.ld
	$(RISCV_EXE_PREFIX)gcc $(CFLAGS) -ffreestanding -nostdlib -o $@ \
		$(RISCV_TEST_INCLUDES) \
		-D RUN_COMPLIANCE \
		-Wl,-Bstatic,-T,$(FIRMWARE)/link.ld,-Map,$(FIRMWARE)/firmware.map,--strip-debug \
		$(FIRMWARE_OBJS) $(FIRMWARE_TEST_OBJS) $(COMPLIANCE_TEST_OBJS) -lgcc

#$(FIRMWARE)/start.o: $(FIRMWARE)/start.S
#	$(RISCV_EXE_PREFIX)gcc -c -march=rv32imc -g -D RUN_COMPLIANCE -o $@ $<

# Thales start
$(FIRMWARE)/start.o: $(FIRMWARE)/start.S
ifeq ($(UNIT_TEST_CMD),1)
ifeq ($(FIRMWARE_UNIT_TEST_OBJS),)
$(error no existing unit test in argument )
else
	$(RISCV_EXE_PREFIX)gcc -c $(CFLAGS) -D RUN_COMPLIANCE  -DUNIT_TEST_CMD=$(UNIT_TEST_CMD) -DUNIT_TEST=$(UNIT_TEST) -DUNIT_TEST_RET=$(UNIT_TEST)_ret -o $@ $<
endif
else
	$(RISCV_EXE_PREFIX)gcc -c $(CFLAGS) -D RUN_COMPLIANCE  -DUNIT_TEST_CMD=$(UNIT_TEST_CMD) -o $@ $<
endif
# Thales end

$(FIRMWARE)/%.o: $(FIRMWARE)/%.c
	$(RISCV_EXE_PREFIX)gcc -c $(CFLAGS) --std=c99 \
		$(RISCV_TEST_INCLUDES) \
		-ffreestanding -nostdlib -o $@ $<

$(RISCV_TESTS)/rv32ui/%.o: $(RISCV_TESTS)/rv32ui/%.S $(RISCV_TESTS)/riscv_test.h \
			$(RISCV_TESTS)/macros/scalar/test_macros.h
	$(RISCV_EXE_PREFIX)gcc -c $(CFLAGS) -o $@ \
		$(RISCV_TEST_INCLUDES) \
		-DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' \
		-DTEST_FUNC_RET=$(notdir $(basename $<))_ret $<

$(RISCV_TESTS)/rv32um/%.o: $(RISCV_TESTS)/rv32um/%.S $(RISCV_TESTS)/riscv_test.h \
			$(RISCV_TESTS)/macros/scalar/test_macros.h
	$(RISCV_EXE_PREFIX)gcc -c $(CFLAGS) -o $@ \
		$(RISCV_TEST_INCLUDES) \
		-DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' \
		-DTEST_FUNC_RET=$(notdir $(basename $<))_ret $<

$(RISCV_TESTS)/rv32uc/%.o: $(RISCV_TESTS)/rv32uc/%.S $(RISCV_TESTS)/riscv_test.h \
			$(RISCV_TESTS)/macros/scalar/test_macros.h
	$(RISCV_EXE_PREFIX)gcc -c $(CFLAGS) -o $@ \
		$(RISCV_TEST_INCLUDES) \
		-DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' \
		-DTEST_FUNC_RET=$(notdir $(basename $<))_ret $<

# Build riscv_compliance_test. Make sure to escape dashes to underscores
$(RISCV_COMPLIANCE_TESTS)/%.o: $(RISCV_COMPLIANCE_TESTS)/%.S $(RISCV_COMPLIANCE_TESTS)/riscv_test.h \
			$(RISCV_COMPLIANCE_TESTS)/test_macros.h $(RISCV_COMPLIANCE_TESTS)/compliance_io.h \
			$(RISCV_COMPLIANCE_TESTS)/compliance_test.h
	$(RISCV_EXE_PREFIX)gcc -c $(CFLAGS) -o $@ \
		-DTEST_FUNC_NAME=$(notdir $(subst -,_,$(basename $<))) \
		-DTEST_FUNC_TXT='"$(notdir $(subst -,_,$(basename $<)))"' \
		-DTEST_FUNC_RET=$(notdir $(subst -,_,$(basename $<)))_ret $<

# in dsim
.PHONY: dsim-unit-test
dsim-unit-test:  firmware-unit-test-clean
dsim-unit-test:  $(FIRMWARE)/firmware_unit_test.hex
dsim-unit-test: ALL_VSIM_FLAGS += "+firmware=$(FIRMWARE)/firmware_unit_test.hex +elf_file=$(FIRMWARE)/firmware_unit_test.elf"
dsim-unit-test: dsim-firmware-unit-test

# in vcs
.PHONY: firmware-vcs-run
firmware-vcs-run: vcsify $(FIRMWARE)/firmware.hex
	./simv $(SIMV_FLAGS) "+firmware=$(FIRMWARE)/firmware.hex"

.PHONY: firmware-vcs-run-gui
firmware-vcs-run-gui: VCS_FLAGS+=-debug_all
firmware-vcs-run-gui: vcsify $(FIRMWARE)/firmware.hex
	./simv $(SIMV_FLAGS) -gui "+firmware=$(FIRMWARE)/firmware.hex"

.PHONY: vcs-unit-test
vcs-unit-test:  firmware-unit-test-clean
vcs-unit-test:  $(FIRMWARE)/firmware_unit_test.hex
vcs-unit-test:  vcsify $(FIRMWARE)/firmware_unit_test.hex
vcs-unit-test:  vcs-run

###############################################################################
# Clone CORE-V-VERIF

core-v-verif:
	$(CLONE_CV_VERIF_CMD)

###############################################################################
# Build disassembler

DPI_DASM_SRC    = $(DPI_DASM_PKG)/dpi_dasm.cxx $(DPI_DASM_PKG)/spike/disasm.cc $(DPI_DASM_SPIKE_PKG)/disasm/regnames.cc
DPI_DASM_ARCH   = $(shell uname)$(shell getconf LONG_BIT)
DPI_DASM_LIB    ?= $(DPI_DASM_PKG)/lib/$(DPI_DASM_ARCH)/libdpi_dasm.so
DPI_DASM_CFLAGS = -shared -fPIC -std=c++11
DPI_DASM_INC    = -I$(DPI_DASM_PKG) -I$(DPI_INCLUDE) -I$(DPI_DASM_SPIKE_PKG)/riscv -I$(DPI_DASM_SPIKE_PKG)/softfloat
DPI_DASM_CXX    = g++

dpi_dasm: $(DPI_DASM_SPIKE_PKG)
	$(CLONE_DPI_DASM_SPIKE_CMD)
	$(DPI_DASM_CXX) $(DPI_DASM_CFLAGS) $(DPI_DASM_INC) $(DPI_DASM_SRC) -o $(DPI_DASM_LIB)

###############################################################################
# Build vendor/riscv-isa-sim into tools/

export SPIKE_PATH  = $(CV32E40X_DV)/vendor/riscv/riscv-isa-sim
export SPIKE_INSTALL_DIR = $(CV32E40X_DV)/tools/spike/
SPIKE_LIBS_DIR = $(SPIKE_INSTALL_DIR)/lib/
SPIKE_FESVR_LIB = $(SPIKE_LIBS_DIR)/libfesvr
SPIKE_RISCV_LIB = $(SPIKE_LIBS_DIR)/libriscv
SPIKE_DISASM_LIB = $(SPIKE_LIBS_DIR)/libdisasm
SPIKE_CUSTOMEXT_LIB = $(SPIKE_LIBS_DIR)/libcustomext
SPIKE_YAML_LIB = $(SPIKE_LIBS_DIR)/libyaml-cpp

NUM_JOBS ?= 8

$(SPIKE_FESVR_LIB).so $(SPIKE_RISCV_LIB).so:
	@echo "$(BANNER)"
	@echo "Building SPIKE"
	@echo "$(BANNER)"
	mkdir -p $(SPIKE_PATH)/build;
	[ ! -f $(SPIKE_PATH)/build/config.log ] && cd $(SPIKE_PATH)/build && ../configure --prefix=$(SPIKE_INSTALL_DIR) || true
	make -C $(SPIKE_PATH)/build/ -j $(NUM_JOBS) yaml-cpp-static;
	make -C $(SPIKE_PATH)/build/ -j $(NUM_JOBS) yaml-cpp;
	make -C $(SPIKE_PATH)/build/ -j $(NUM_JOBS) install;

spike_lib: $(SPIKE_FESVR_LIB).so $(SPIKE_RISCV_LIB).so

###############################################################################
# Build SVLIB DPI

SVLIB_PKG        := $(CV32E40X_DV)/vendor_lib/verilab/svlib
export SVLIB_PKG  = $(CV32E40X_DV)/vendor_lib/verilab/svlib


SVLIB_SRC    = $(SVLIB_PKG)/svlib/src/dpi/svlib_dpi.c
SVLIB_CFLAGS = -shared -fPIC
SVLIB_LIB    = $(SVLIB_PKG)/../svlib_dpi.so
SVLIB_CXX    = gcc

clone_svlib: $(SVLIB_PKG)

svlib: $(SVLIB_PKG)

clean_svlib:
	rm -rf $(SVLIB_LIB)
	rm -rf $(SVLIB_PKG)

$(SVLIB_PKG):
	$(CLONE_SVLIB_CMD)
	@echo "$(BANNER)"
	@echo "Building $(SVLIB_PKG)"
	@echo "$(BANNER)"
	$(SVLIB_CXX) $(SVLIB_CFLAGS) $(SVLIB_SRC) -I$(DPI_INCLUDE) -o $(SVLIB_LIB)

###############################################################################
# Clone ACT4
export ACT4_PKG  = $(CV32E40X_DV)/vendor_lib/riscv-arch-test/act4

clone_act4: $(ACT4_PKG)

$(ACT4_PKG):
	$(CLONE_ACT4_CMD)

###############################################################################
# Build Stub for RVVI-API (in the case where ImperasDV is not available)
RVVI_STUB_SRC    = $(RVVI_STUB)/rvviApiStubs.c
RVVI_STUB_CFLAGS = -shared -fPIC
RVVI_STUB_LIB    = $(RVVI_STUB)/rvviApi.so
RVVI_STUB_CXX    = gcc

rvvi_stub:
	@echo "$(BANNER)"
	@echo "Building $(RVVI_STUB)"
	@echo "$(BANNER)"
	$(RVVI_STUB_CXX) $(RVVI_STUB_CFLAGS) $(RVVI_STUB_SRC) -I$(DPI_INCLUDE) -o $(RVVI_STUB_LIB)

#endend


