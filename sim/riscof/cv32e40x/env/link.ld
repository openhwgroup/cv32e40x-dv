// Copyright 2024 Silicon Labs, Inc.
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you
// may not use this file except in compliance with the License, or, at your
// option, the Apache License version 2.0.
//
// You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and
// limitations under the License.

OUTPUT_ARCH( "riscv" )
ENTRY(rvtest_entry_point)

SECTIONS
{
  . = 0x80000000;
  .text.init : { *(.text.init) }
  . = ALIGN(0x1000);
  .text : { *(.text) }

  . = 0x80800000;
  .data : { *(.data) }
  .data.string : { *(.data.string)}
  .bss : { *(.bss) }
  _end = .;

  /* Below section "test_env_section" defined to use as mailbox for DUT testbench. To write
    "begin_signature", "end_signature" symbol addresses from each riscv_arch_test for DUT testbench.
     Note :
     Text Section start address defined above = 0x8000_0000
     Section "test_env_section" chosen offset wrt start of text section = 0x03FF_1000.
     (This offset addr is chosen to be within a default SAIL ref model "ram-size" constraint of 0x0400_0000).
     So effective section address = 0x8000_0000 + 0x03FF_1000 = 0x83FF_1000. */

  . = 0x83FF1000;
  .test_env_section : {
     /* __TEST_SIG_BEGIN_ADDR -> After boot-up the test code will do a store to this address (0x83FF_1000)
                                 writing the address of symbol "begin_signature"
        Refer to riscof/cv32e40p/env/model_test.h -> RVMODEL_BOOT macro for relevant boot code */
    __TEST_SIG_BEGIN_ADDR = .;
    /* initialize this location to 0xDEADBEEF */
    LONG(0xDEADBEEF);
     /* __TEST_SIG_END_ADDR -> Next after boot-up the test code will do a store to this address (0x83FF_1004)
                             writing the address of symbol "end_signature"
        Refer to riscof/cv32e40p/env/model_test.h -> RVMODEL_BOOT macro for relevant boot code */
    __TEST_SIG_END_ADDR = .;
    /* initialize this location to 0xDEADBEEF */
    LONG(0xDEADBEEF);
  }
}

