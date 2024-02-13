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
    parameter a_ext_e       A_EXT,
    parameter int           PMA_NUM_REGIONS,
    parameter pma_cfg_t     PMA_CFG [PMA_NUM_REGIONS-1:0],
    parameter rv32_e        RV32
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


  // Reservation set helper logic:

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


  // Trap helper logic:

  logic traps_prioritized_higher_than_load_store_faults;

  assign trap_prioritized_higher_than_load_store_faults =
    rvfi_if.rvfi_trap.exception_cause == EXC_CAUSE_INSTR_FAULT ||
    rvfi_if.rvfi_trap.exception_cause == EXC_CAUSE_INSTR_BUS_FAULT ||
    rvfi_if.rvfi_trap.exception_cause == EXC_CAUSE_ECALL_MMODE ||
    rvfi_if.rvfi_trap.exception_cause == EXC_CAUSE_BREAKPOINT ||
    rvfi_if.rvfi_trap.debug_cause == DBG_CAUSE_TRIGGER;

  // PMA helper logic:

  logic [$clog2(PMA_NUM_REGIONS)-1:0] transaction_addrs_pma_region;
  logic transaction_addrs_within_pma_region;

  always_comb begin
  transaction_addrs_pma_region = 0;
  transaction_addrs_within_pma_region = 0;
    for (int i = PMA_NUM_REGIONS-1; i >= 0; i--) begin
      if ((rvfi_if.rvfi_rs1_rdata >>2) >= PMA_CFG[i].word_addr_low &&
        (rvfi_if.rvfi_rs1_rdata >>2) < PMA_CFG[i].word_addr_high
      ) begin
        transaction_addrs_pma_region = i;
        transaction_addrs_within_pma_region = 1;
      end
    end
  end


  // Corner cases for PMA related assertions:

  logic corner_cases_high_trap_no_misalignment_no_dbg;

  assign no_corner_cases_no_high_prioritized_traps_no_misalignment_no_dbg =
    !trap_prioritized_higher_than_load_store_faults &&
    rvfi_if.rvfi_rs1_rdata[1:0] == 2'b00 && //No memory alignment error
    !rvfi_if.rvfi_dbg_mode; //No change in PMA setting due to debug


  // Illegal register for RV32E:
  logic RV32E_illegal_registers;

  assign RV32E_illegal_registers =
    support_if.asm_rvfi.rd.gpr.raw > 32'd15 ||
    support_if.asm_rvfi.rs1.gpr.raw > 32'd15 ||
    support_if.asm_rvfi.rs2.gpr.raw > 32'd15;

  // ---------------------------------------------------------------------------
  // Clocking block
  // ---------------------------------------------------------------------------

  default clocking @(posedge clknrst_if.clk); endclocking
  default disable iff (!clknrst_if.reset_n || (RV32==RV32E && RV32E_illegal_registers));


  // ---------------------------------------------------------------------------
  // Assertions
  // ---------------------------------------------------------------------------

  if (A_EXT inside {A, ZALRSC}) begin

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

    a_atomic_atop_5: assert property (
      rvfi_if.rvfi_valid &&
      !rvfi_if.rvfi_trap.trap &&
      (support_if.asm_rvfi.instr == LR_W ||
      support_if.asm_rvfi.instr == SC_W)
      |->
      rvfi_if.rvfi_mem_atop[ATOP_ATOMIC_OPERATION_POS]
    ) else `uvm_error(info_tag, "Atop[5] is cleared for a non-traped LR_W or SC_W instruction.\n");

  end
  if (A_EXT inside {ZALRSC}) begin

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

  end
  if (A_EXT inside {A, ZALRSC}) begin

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

    a_lrw_rs2_is_x0: assert property (
      support_if.asm_rvfi.instr == LR_W &&
      rvfi_if.rvfi_valid &&
      !rvfi_if.rvfi_trap
      |->
      support_if.asm_rvfi.rs2.valid &&
      support_if.asm_rvfi.rs2.gpr.gpr == X0
    ) else `uvm_error(info_tag, "LR.W's RS2 is not X0\n");

    a_lrw_rs2_not_x0: assert property (
      support_if.asm_rvfi.instr == LR_W &&
      support_if.asm_rvfi.rs2.gpr.gpr == X0 &&
      rvfi_if.rvfi_valid
      |->
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_ILLEGAL_INSN
    ) else `uvm_error(info_tag, "A LR.W's instruction with RS2 equal to X0 is not an illegal instruction.\n");

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
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_BREAKPOINT

      |->
      rvfi_if.rvfi_trap.exception_cause == cv32e40x_pkg::EXC_CAUSE_LOAD_FAULT
    ) else `uvm_error(info_tag, "A LR_W instruction that access a non-aligned memory field does not have a misaligned exception (shown as load fault).\n");

    a_atomic_alignment_exceptions_scw: assert property (
      support_if.asm_rvfi.instr == SC_W &&

      rvfi_if.rvfi_valid &&
      rvfi_if.rvfi_rs1_rdata[1:0] != 2'b0 &&

      !rvfi_if.rvfi_trap.debug &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_INSTR_FAULT &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_INSTR_BUS_FAULT &&
      rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_BREAKPOINT

      |->

      rvfi_if.rvfi_trap.exception_cause == cv32e40x_pkg::EXC_CAUSE_STORE_FAULT
    ) else `uvm_error(info_tag, "A SC_W instruction that access a non-aligned memory field does not have a misaligned exception (shown as store fault).\n");


    if (!PMA_NUM_REGIONS) begin

      a_atomic_access_no_pma_regions_LRW: assert property (
        rvfi_if.rvfi_valid &&
        support_if.asm_rvfi.instr == LR_W &&
        no_corner_cases_no_high_prioritized_traps_no_misalignment_no_dbg

        |->
        rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_LOAD_FAULT
      ) else `uvm_error(info_tag, "There are no PMA regions, but the LR.W traps due to load fault.\n");


      a_atomic_access_no_pma_regions_SCW: assert property (
        rvfi_if.rvfi_valid &&
        support_if.asm_rvfi.instr == SC_W &&
        no_corner_cases_no_high_prioritized_traps_no_misalignment_no_dbg

        |->
        rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_STORE_FAULT
      ) else `uvm_error(info_tag, "There are no PMA regions, but the SC.W traps due to store fault.\n");

    end else begin

      a_atomic_access_atomic_regions_LRW: assert property (
        rvfi_if.rvfi_valid &&
        support_if.asm_rvfi.instr == LR_W &&
        PMA_CFG[transaction_addrs_pma_region].atomic &&
        transaction_addrs_within_pma_region &&
        no_corner_cases_no_high_prioritized_traps_no_misalignment_no_dbg

        |->
        rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_LOAD_FAULT
      ) else `uvm_error(info_tag, "LR.W operation to atomic memory region cause load fault exception.\n");


      a_atomic_access_atomic_regions_SCW: assert property (
        rvfi_if.rvfi_valid &&
        support_if.asm_rvfi.instr == SC_W &&
        PMA_CFG[transaction_addrs_pma_region].atomic &&
        transaction_addrs_within_pma_region &&
        no_corner_cases_no_high_prioritized_traps_no_misalignment_no_dbg

        |->
        rvfi_if.rvfi_trap.exception_cause != EXC_CAUSE_STORE_FAULT
      ) else `uvm_error(info_tag, "SC.W operation to atomic memory region cause store fault exception.\n");


      a_atomic_access_nonatomic_regions_LRW: assert property (
        rvfi_if.rvfi_valid &&
        support_if.asm_rvfi.instr == LR_W &&
        !PMA_CFG[transaction_addrs_pma_region].atomic &&
        transaction_addrs_within_pma_region &&
        !trap_prioritized_higher_than_load_store_faults

        |->
        rvfi_if.rvfi_trap.trap &&
        rvfi_if.rvfi_trap.exception_cause == EXC_CAUSE_LOAD_FAULT
      ) else `uvm_error(info_tag, "LR.W operation to non atomic memory region does not cause load fault exception.\n");


      a_atomic_access_nonatomic_regions_SCW: assert property (
        rvfi_if.rvfi_valid &&
        support_if.asm_rvfi.instr == SC_W &&
        !PMA_CFG[transaction_addrs_pma_region].atomic &&
        transaction_addrs_within_pma_region &&
        !trap_prioritized_higher_than_load_store_faults

        |->
        rvfi_if.rvfi_trap.trap &&
        rvfi_if.rvfi_trap.exception_cause == EXC_CAUSE_STORE_FAULT
      ) else `uvm_error(info_tag, "SC.W operation to non atomic memory region does not cause store fault exception.\n");


      a_atomic_access_outside_pma_regions_LRW: assert property (
        rvfi_if.rvfi_valid &&
        support_if.asm_rvfi.instr == LR_W &&
        !transaction_addrs_within_pma_region &&
        no_corner_cases_no_high_prioritized_traps_no_misalignment_no_dbg

        |->
        rvfi_if.rvfi_trap.exception_cause == EXC_CAUSE_LOAD_FAULT
      ) else `uvm_error(info_tag, "LR.W operation outside PMA regions does not cause load fault exception.\n");


      a_atomic_access_outside_pma_regions_SCW: assert property (
        rvfi_if.rvfi_valid &&
        support_if.asm_rvfi.instr == SC_W &&
        !transaction_addrs_within_pma_region &&
        no_corner_cases_no_high_prioritized_traps_no_misalignment_no_dbg

        |->
        rvfi_if.rvfi_trap.exception_cause == EXC_CAUSE_STORE_FAULT
      ) else `uvm_error(info_tag, "SC.W operation outside PMA regions does not cause store fault exception.\n");

    end

    // A_EXT = A or ZALRSC:
    //TODO: krdosvik, it would be nice to have rvfi timing. Look into this when enabeling A_EXT=ATOMIC
    // atop[4:0] shall be equal to bits [31:27] of the instruction if atop[5] == 1.
    // atop compared to bits [31:27] of the instruction
    a_atomic_atop_match_instruction: assert property (
      data_obi_if.atop[5] == 1 && data_obi_if.req && data_obi_if.gnt && ex_valid
      |->
      data_obi_if.atop[4:0] == ex_stage_instr_rdata_i[31:27]
    ) else `uvm_error(info_tag, "Atop does not match the instruction.\n");

  end


endmodule : uvmt_cv32e40x_atomic_assert

`default_nettype wire
