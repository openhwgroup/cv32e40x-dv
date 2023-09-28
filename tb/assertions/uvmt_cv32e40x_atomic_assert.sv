//
// Copyright 2023 Silicon Laboratories Inc
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
  import cv32e40x_pkg::*;
  import isa_decoder_pkg::*;
  #(
    parameter A_EXT = A_NONE
  )(
    uvma_clknrst_if_t       clknrst_if,
    uvma_rvfi_instr_if_t    rvfi_if,
    uvma_obi_memory_if_t    data_obi_if,
    uvmt_cv32e40x_support_logic_module_o_if_t.slave_mp  support_if,

    input logic[31:0]       ex_stage_instr_rdata_i,
    input logic             ex_valid
  );


  // ---------------------------------------------------------------------------
  // Local variables
  // ---------------------------------------------------------------------------

  string  info_tag                = "CV32E40X_ATOMIC_ASSERT";
  localparam ATOP_ATOMIC_OPERATION_POS      = 5;
  localparam ATOP_LR_W                   = 6'h22;
  localparam ATOP_SC_W                   = 6'h23;

  // ---------------------------------------------------------------------------
  // Support logic
  // ---------------------------------------------------------------------------

  logic reservation_valid;
  logic [31:0] reservation_set;

  always_ff @(posedge clknrst_if.clk or negedge clknrst_if.reset_n) begin
    if (!clknrst_if.reset_n) begin
      reservation_valid <= 1'b0;
      reservation_set <= '0;
    end else begin
      if (support_if.asm_rvfi.instr == LR_W && rvfi_if.rvfi_mem_exokay && rvfi_if.rvfi_valid && (!rvfi_if.rvfi_trap.trap || rvfi_if.rvfi_trap.debug_cause==DBG_CAUSE_STEP)) begin
        reservation_valid <= 1'b1;
        reservation_set <= rvfi_if.rvfi_mem_addr[31:0];
      end else if (support_if.asm_rvfi.instr == SC_W && rvfi_if.rvfi_valid && !rvfi_if.rvfi_trap.trap) begin
        reservation_valid <= 1'b0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Clocking block
  // ---------------------------------------------------------------------------
  default clocking @(posedge clknrst_if.clk); endclocking
  default disable iff !(clknrst_if.reset_n);


  // ---------------------------------------------------------------------------
  // Assertions
  // ---------------------------------------------------------------------------

  if (A_EXT != A_NONE) begin

    // A_EXT = A or ZALRSC:

    a_atomic_no_outstanding_req: assert property (
      data_obi_if.req && data_obi_if.gnt && data_obi_if.atop[ATOP_ATOMIC_OPERATION_POS] ##1 !data_obi_if.rvalid
      |->
      (!data_obi_if.req until_with data_obi_if.rvalid)
    ) else `uvm_error(info_tag, "There are unfinished atomic memory operations.\n");

    a_atomic_no_initiated_req: assert property (
      data_obi_if.req && data_obi_if.gnt && !data_obi_if.atop[ATOP_ATOMIC_OPERATION_POS]
      |->
      (!(data_obi_if.req && data_obi_if.atop[ATOP_ATOMIC_OPERATION_POS])) until_with data_obi_if.rvalid
    ) else `uvm_error(info_tag, "There are unfinished earlier memory operations.\n");

    // A_EXT = ZALRSC:

    a_atomic_atop_5: assert property (
      rvfi_if.rvfi_valid &&
      !rvfi_if.rvfi_trap.trap &&
      (support_if.asm_rvfi.instr == LR_W ||
      support_if.asm_rvfi.instr == SC_W)
      |->
      rvfi_if.rvfi_mem_atop[ATOP_ATOMIC_OPERATION_POS]
    ) else `uvm_error(info_tag, "Atop[5] is cleared for a non-traped LR_W or SC_W instruction.\n");

    //Verifying that the oposite of the above assertion is also true.
    a_atomic_atop_5_zalrsc: assert property (
      rvfi_if.rvfi_valid &&
      !rvfi_if.rvfi_trap.trap &&
      rvfi_if.rvfi_mem_atop[ATOP_ATOMIC_OPERATION_POS] &&
      (rvfi_if.rvfi_mem_rmask ||
      rvfi_if.rvfi_mem_wmask)
      |->
      (support_if.asm_rvfi.instr == LR_W ||
      support_if.asm_rvfi.instr == SC_W)
    ) else `uvm_error(info_tag, "Atop[5] is set for a memory instruction, but it is not a LR_W or SC_W.\n");

    a_atomic_atop_4_to_0_lrw: assert property (
      rvfi_if.rvfi_valid &&
      !rvfi_if.rvfi_trap.trap &&
      support_if.asm_rvfi.instr == LR_W
      |->
      rvfi_if.rvfi_mem_atop == ATOP_LR_W
    ) else `uvm_error(info_tag, "Atop[4:0] != 2 for a non-traped LR_W instruction.\n");

    a_atomic_atop_4_to_0_scw: assert property (
      rvfi_if.rvfi_valid &&
      !rvfi_if.rvfi_trap.trap &&
      support_if.asm_rvfi.instr == SC_W
      |->
      rvfi_if.rvfi_mem_atop == ATOP_SC_W
    ) else `uvm_error(info_tag, "Atop[4:0] != 3 for a non-traped SC_W instruction.\n");

    c_atomic_lrw_exokay_ignore: cover property (
      rvfi_if.rvfi_valid &&
      support_if.asm_rvfi.instr == LR_W &&
      !rvfi_if.rvfi_mem_err &&
      !rvfi_if.rvfi_mem_exokay &&
      !rvfi_if.rvfi_trap.trap
    );

    a_atomic_lrw_address: assert property (
      support_if.asm_rvfi.instr == LR_W &&
      rvfi_if.rvfi_valid &&
      !rvfi_if.rvfi_trap.trap
      |->
      rvfi_if.rvfi_mem_addr == rvfi_if.rvfi_rs1_rdata
    ) else `uvm_error(info_tag, "The memory address of a non-traped LR_W instruction is not the value held in RS1.\n");

    a_atomic_lrw_data: assert property (
      support_if.asm_rvfi.instr == LR_W &&
      rvfi_if.rvfi_valid &&
      !rvfi_if.rvfi_trap.trap &&
      rvfi_if.rvfi_rd1_addr != X0
      |->
      rvfi_if.rvfi_rd1_wdata == rvfi_if.rvfi_mem_rdata
    ) else `uvm_error(info_tag, "The RD register does not contained the data fetched from memory by a non-traped LR_W instruction.\n");

    a_atomic_scw_success: assert property (
      support_if.asm_rvfi.instr == SC_W &&
      rvfi_if.rvfi_valid &&
      !rvfi_if.rvfi_trap.trap &&
      rvfi_if.rvfi_mem_exokay
      |->
      rvfi_if.rvfi_rd1_wdata == 32'h0
    ) else `uvm_error(info_tag, "A successful SC_W instruction has not written 0 to RD.\n");

    a_atomic_scw_failure: assert property (
      support_if.asm_rvfi.instr == SC_W &&
      rvfi_if.rvfi_valid &&
      !rvfi_if.rvfi_trap.trap &&
      !rvfi_if.rvfi_mem_exokay &&
      rvfi_if.rvfi_rd1_addr != X0
      |->
      rvfi_if.rvfi_rd1_wdata == 32'h1
    ) else `uvm_error(info_tag, "An unsuccessful SC_W instruction has not written 1 to RD.\n");

    a_atomic_scw_invalidates_reservation_set: assert property (
      (!reservation_valid ||
      rvfi_if.rvfi_mem_addr[31:0] != reservation_set) &&
      support_if.asm_rvfi.instr == SC_W &&
      rvfi_if.rvfi_valid &&
      !rvfi_if.rvfi_trap.trap
      |->
      !rvfi_if.rvfi_mem_exokay
    ) else `uvm_error(info_tag, "A SC_W instruction is successful even though there is no valid reservation set or it accessed bytes outside the reservation set.\n");

    a_atomic_alignment: assert property (
      (support_if.asm_rvfi.instr == SC_W ||
      support_if.asm_rvfi.instr == LR_W) &&

      rvfi_if.rvfi_valid &&
      !rvfi_if.rvfi_trap.trap

      |->
      rvfi_if.rvfi_rs1_rdata[1:0]  == 2'b0
    ) else `uvm_error(info_tag, "A non trapped SC_W or LR_W instruction access a non-aligned memory field.\n");

    a_atomic_alignment_exceptions_lrw: assert property (
      support_if.asm_rvfi.instr == LR_W &&

      rvfi_if.rvfi_valid &&
      rvfi_if.rvfi_rs1_rdata[1:0] != 2'b0 &&

      !rvfi_if.rvfi_trap.debug &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_INSTR_FAULT &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_INSTR_BUS_FAULT &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_ILLEGAL_INSN &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_ECALL_MMODE &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_BREAKPOINT &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_STORE_FAULT &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_LOAD_FAULT

      |->
      rvfi_if.rvfi_trap.exception_cause == cv32e40x_pkg::EXC_CAUSE_LOAD_MISALIGNED

    ) else `uvm_error(info_tag, "A LR_W instruction that access a non-aligned memory field does not have a misaligned exception.\n");

    a_atomic_alignment_exceptions_scw: assert property (
      support_if.asm_rvfi.instr == SC_W &&

      rvfi_if.rvfi_valid &&
      rvfi_if.rvfi_rs1_rdata[1:0] != 2'b0 &&

      !rvfi_if.rvfi_trap.debug &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_INSTR_FAULT &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_INSTR_BUS_FAULT &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_ILLEGAL_INSN &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_ECALL_MMODE &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_BREAKPOINT &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_STORE_FAULT &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_LOAD_FAULT

      |->

      rvfi_if.rvfi_trap.exception_cause == cv32e40x_pkg::EXC_CAUSE_STORE_MISALIGNED

    ) else `uvm_error(info_tag, "A SC_W instruction that access a non-aligned memory field does not have a misaligned exception.\n");


    // A_EXT = A or ZALRSC:
    //TODO: krdosvik, it would be nice to have rvfi timing. Look into this when enabeling A_EXT=ATOMIC
    // atop[4:0] shall be equal to bits [31:27] of the instruction if atop[5] == 1.
    // atop compared to bits [31:27] of the instruction
    a_atomic_atop_match_instruction : assert property (
      data_obi_if.atop[5] == 1 && data_obi_if.req && data_obi_if.gnt && ex_valid
      |->
      data_obi_if.atop[4:0] == ex_stage_instr_rdata_i[31:27]
    ) else `uvm_error(info_tag, "Atop does not match the instruction.\n");

  end


endmodule : uvmt_cv32e40x_atomic_assert

`default_nettype wire
