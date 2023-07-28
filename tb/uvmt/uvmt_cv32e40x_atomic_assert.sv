//
// Copyright 2020 OpenHW Group
// Copyright 2020 Datum Technology Corporation
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://solderpad.org/licenses/
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

module uvmt_cv32e40x_atomic_assert
  import uvm_pkg::*;
  import uvma_rvfi_pkg::*;
  import cv32e40x_pkg::*;
  import uvmt_cv32e40x_base_test_pkg::*;
  import support_pkg::*;
  (
    uvma_rvfi_instr_if_t  rvfi_if,
    uvma_obi_memory_if_t  data_obi,
    logic[31:0]           id_stage_instr_rdata_i,
    logic[31:0]           ex_stage_instr_rdata_i,
    logic[31:0]           wb_stage_instr_rdata_i,
    logic                 if_valid,
    logic                 id_valid,
    logic                 ex_valid,
    logic                 wb_valid
  );


  // ---------------------------------------------------------------------------
  // Local variables
  // ---------------------------------------------------------------------------
  string  info_tag = "CV32E40X_ATOMIC_ASSERT";


  // When an atomic instruction is recognized, the atomic valid signal is asserted
  a_atomic_instr : assert property (
    rvfi_if.rvfi_valid
    && (rvfi_if.rvfi_insn[14:12] == 3'b010)
    && (rvfi_if.rvfi_insn[6:0]   == 7'b0101111)
    && (
    (  rvfi_if.rvfi_insn[31:27] == 5'b00010 && rvfi_if.rvfi_insn[24:20] == 5'b0)
    || rvfi_if.rvfi_insn[31:27] == 5'b00011
    || rvfi_if.rvfi_insn[31:27] == 5'b00001
    || rvfi_if.rvfi_insn[31:27] == 5'b00000
    || rvfi_if.rvfi_insn[31:27] == 5'b00100
    || rvfi_if.rvfi_insn[31:27] == 5'b01100
    || rvfi_if.rvfi_insn[31:27] == 5'b01000
    || rvfi_if.rvfi_insn[31:27] == 5'b10000
    || rvfi_if.rvfi_insn[31:27] == 5'b10100
    || rvfi_if.rvfi_insn[31:27] == 5'b11000
    || rvfi_if.rvfi_insn[31:27] == 5'b11100
    )
    |->
    rvfi_if.instr_asm.atomic.valid
  ) else `uvm_error(info_tag, "Atomic instruction not decoded");

  // R-142.1: There shall be no unfinished earlier memory operations when an atomic memory operation is initiated on the OBI interface
  a_atomic_no_unfinished_memory_operations : assert property (
    data_obi.req && data_obi.gnt && !(data_obi.atop[5] == 1) ##1 !data_obi.rvalid
    |->
    !(data_obi.req && data_obi.gnt && (data_obi.atop[5] == 1))[*0:$] ##1 data_obi.rvalid
  ) else `uvm_error(info_tag, "There are unfinished earlier memory operations");

  // R-142.2: There shall be no unfinished atomic memory operation when a later memory operation is initiated on the OBI interface
  a_no_unfinished_atomic_memory_operations : assert property (
    data_obi.req && data_obi.gnt && (data_obi.atop[5] == 1) ##1 !data_obi.rvalid
    |->
    !(data_obi.req && data_obi.gnt)[*0:$] ##1 data_obi.rvalid
  ) else `uvm_error(info_tag, "There are unfinished atomic memory operations");

  // R-11.2 atop[4:0] shall be equal to bits [31:27] of the instruction if atop[5] == 1.
  // atop compared to possible values of atomic instructions
  a_atomic_atop_correct_value : assert property (
    data_obi.atop[5] == 1 && ex_valid
    |->
    (  data_obi.atop[4:0] == 5'b00010)
    || data_obi.atop[4:0] == 5'b00011
    || data_obi.atop[4:0] == 5'b00001
    || data_obi.atop[4:0] == 5'b00000
    || data_obi.atop[4:0] == 5'b00100
    || data_obi.atop[4:0] == 5'b01100
    || data_obi.atop[4:0] == 5'b01000
    || data_obi.atop[4:0] == 5'b10000
    || data_obi.atop[4:0] == 5'b10100
    || data_obi.atop[4:0] == 5'b11000
    || data_obi.atop[4:0] == 5'b11100
  ) else `uvm_error(info_tag, "Atop does not match to an atomic instruction");

  // R-11.2 atop[4:0] shall be equal to bits [31:27] of the instruction if atop[5] == 1.
  // atop compared to bits [31:27] of the instruction
  a_atomic_atop_match_instruction : assert property (
    data_obi.atop[5] == 1 && data_obi.req && data_obi.gnt && ex_valid
    |->
    data_obi.atop[4:0] == ex_stage_instr_rdata_i[31:27]
  ) else `uvm_error(info_tag, "Atop does not match the instruction");


endmodule : uvmt_cv32e40x_atomic_assert

`default_nettype wire
