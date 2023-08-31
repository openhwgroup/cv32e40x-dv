//
// Copyright 2023 OpenHW Group
// Copyright 2023 Datum Technology Corporation
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

module uvmt_cv32e40x_rv32e_assert
  import uvm_pkg::*;
  import uvma_rvfi_pkg::*;
  import cv32e40x_pkg::*;
  import uvmt_cv32e40x_base_test_pkg::*;
  import isa_decoder_pkg::*;
  (
      uvma_rvfi_instr_if_t rvfi_if
  );


  // ---------------------------------------------------------------------------
  // Local parameters
  // ---------------------------------------------------------------------------


  // ---------------------------------------------------------------------------
  // Local variables
  // ---------------------------------------------------------------------------
  string        info_tag = "CV32E40X_RV32E_ASSERT";

  // ---------------------------------------------------------------------------
  // Clocking blocks
  // ---------------------------------------------------------------------------

  // Single clock, single reset design, use default clocking
  default clocking @(posedge rvfi_if.clk); endclocking
  default disable iff !(rvfi_if.reset_n);

  // ---------------------------------------
  // Assertions
  // ---------------------------------------

  // any instruction that uses a register not implemented with RV32E should trap
  property p_unimplemented_register_traps(reg_addr, reg_valid);
      rvfi_if.rvfi_valid &&
      reg_valid &&
      reg_addr > 15
    |->
      rvfi_if.rvfi_trap.trap;
  endproperty

  a_unimplemented_rs1_traps: assert property(
    p_unimplemented_register_traps(rvfi_if.instr_asm.rs1.gpr.raw, rvfi_if.instr_asm.rs1.valid)
  )
  else `uvm_error(info_tag, $sformatf("RS2 is outside rv32e and should trap. RS2==%d", rvfi_if.instr_asm.rs1.gpr.raw));

  a_unimplemented_rs2_traps: assert property(
    p_unimplemented_register_traps(rvfi_if.instr_asm.rs2.gpr.raw, rvfi_if.instr_asm.rs2.valid)
  )
  else `uvm_error(info_tag, $sformatf("RS2 is outside rv32e and should trap. RS2==%d", rvfi_if.instr_asm.rs2.gpr.raw));

  a_unimplemented_rd_traps: assert property(
    p_unimplemented_register_traps(rvfi_if.instr_asm.rd.gpr.raw, rvfi_if.instr_asm.rd.valid)
  )
  else `uvm_error(info_tag, $sformatf("RS2 is outside rv32e and should trap. RS2==%d", rvfi_if.instr_asm.rd.gpr.raw));

  a_unimplemented_rlist_traps: assert property(
      rvfi_if.rvfi_valid &&
      rvfi_if.instr_asm.rlist.valid &&
      (rvfi_if.instr_asm.rlist.rlist.raw > RA__S0_S1)
    |->
      rvfi_if.rvfi_trap.trap
  )
  else `uvm_error(info_tag, $sformatf("Rlist is outside rv32e and should trap. Rlist==%d", rvfi_if.instr_asm.rlist.rlist.raw));


endmodule : uvmt_cv32e40x_rv32e_assert


