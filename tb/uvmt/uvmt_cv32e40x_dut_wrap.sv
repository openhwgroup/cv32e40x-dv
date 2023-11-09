//
// Copyright 2020 OpenHW Group
// Copyright 2020 Datum Technology Corporation
// Copyright 2020 Silicon Labs, Inc.
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
///////////////////////////////////////////////////////////////////////////////
//
// Modified version of the wrapper for a RI5CY testbench, containing RI5CY,
// plus Memory and stdout virtual peripherals.
// Contributor: Robert Balas <balasr@student.ethz.ch>
// Copyright 2018 Robert Balas <balasr@student.ethz.ch>
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//


`ifndef __UVMT_CV32E40X_DUT_WRAP_SV__
`define __UVMT_CV32E40X_DUT_WRAP_SV__

`default_nettype none


/**
 * Module wrapper for CV32E40X RTL DUT.
 */

module uvmt_cv32e40x_dut_wrap
#(
    parameter INSTR_ADDR_WIDTH,
    parameter INSTR_RDATA_WIDTH,
    parameter RAM_ADDR_WIDTH
  )
  (
    uvma_clknrst_if_t               clknrst_if,
    uvma_interrupt_if_t             interrupt_if,
    uvma_clic_if_t                  clic_if,
    uvma_wfe_wu_if_t                wfe_wu_if,
    uvme_cv32e40x_core_cntrl_if_t   core_cntrl_if,
    uvmt_cv32e40x_core_status_if_t  core_status_if,
    uvmt_cv32e40x_vp_status_if_t    vp_status_if,
    uvma_obi_memory_if_t            obi_instr_if,
    uvma_obi_memory_if_t            obi_data_if,
    uvma_fencei_if_t                fencei_if
  );

    // eXtension interface
    // todo: Connect to TB when implemented.
    // Included to allow core-v-verif to compile with RTL including
    // interface definition.
    cv32e40x_if_xif xif();

    logic         debug_havereset;
    logic         debug_running;
    logic         debug_halted;
    logic         debug_pc_valid;
    logic [31:0]  debug_pc;

    logic  alert_major;
    logic  alert_minor;

    logic [63:0]  mcycle;

    // instantiate the core

    cv32e40x_wrapper #(
      .A_EXT            (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_A_EXT),
      .B_EXT            (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_B_EXT),
      .CLIC             (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_CLIC),
      .CLIC_ID_WIDTH    (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_CLIC_ID_WIDTH),
      .DBG_NUM_TRIGGERS (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_DBG_NUM_TRIGGERS),
      .DM_REGION_END    (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_DM_REGION_END),
      .DM_REGION_START  (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_DM_REGION_START),
      .M_EXT            (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_M_EXT),
      .NUM_MHPMCOUNTERS (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_NUM_MHPMCOUNTERS),
      .PMA_CFG          (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_PMA_CFG),
      .PMA_NUM_REGIONS  (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_PMA_NUM_REGIONS),
      .RV32             (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_RV32),
      .X_ECS_XS         (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_X_ECS_XS),
      .X_EXT            (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_X_EXT),
      .X_ID_WIDTH       (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_X_ID_WIDTH),
      .X_MEM_WIDTH      (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_X_MEM_WIDTH),
      .X_MISA           (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_X_MISA),
      .X_NUM_RS         (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_X_NUM_RS),
      .X_RFR_WIDTH      (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_X_RFR_WIDTH),
      .X_RFW_WIDTH      (uvmt_cv32e40x_base_test_pkg::CORE_PARAM_X_RFW_WIDTH)
    ) cv32e40x_wrapper_i (
         .clk_i                  ( clknrst_if.clk                 ),
         .rst_ni                 ( clknrst_if.reset_n             ),

         .scan_cg_en_i           ( core_cntrl_if.scan_cg_en       ),

         .boot_addr_i            ( core_cntrl_if.boot_addr        ),
         .mtvec_addr_i           ( core_cntrl_if.mtvec_addr       ),
         .dm_halt_addr_i         ( core_cntrl_if.dm_halt_addr     ),
         .mhartid_i              ( core_cntrl_if.mhartid          ),
         .mimpid_patch_i         ( core_cntrl_if.mimpid_patch     ),
         .dm_exception_addr_i    ( core_cntrl_if.dm_exception_addr),

         .instr_req_o            ( obi_instr_if.req               ),
         .instr_gnt_i            ( obi_instr_if.gnt               ),
         .instr_addr_o           ( obi_instr_if.addr              ),
         .instr_prot_o           ( obi_instr_if.prot              ),
         .instr_dbg_o            ( obi_instr_if.dbg               ),
         .instr_memtype_o        ( obi_instr_if.memtype           ),
         .instr_rdata_i          ( obi_instr_if.rdata             ),
         .instr_rvalid_i         ( obi_instr_if.rvalid            ),
         .instr_err_i            ( obi_instr_if.err               ),

         .data_req_o             ( obi_data_if.req                ),
         .data_gnt_i             ( obi_data_if.gnt                ),
         .data_rvalid_i          ( obi_data_if.rvalid             ),
         .data_we_o              ( obi_data_if.we                 ),
         .data_be_o              ( obi_data_if.be                 ),
         .data_addr_o            ( obi_data_if.addr               ),
         .data_wdata_o           ( obi_data_if.wdata              ),
         .data_prot_o            ( obi_data_if.prot               ),
         .data_dbg_o             ( obi_data_if.dbg                ),
         .data_memtype_o         ( obi_data_if.memtype            ),
         .data_rdata_i           ( obi_data_if.rdata              ),
         .data_atop_o            ( obi_data_if.atop               ),
         .data_err_i             ( obi_data_if.err                ),
         .data_exokay_i          ( obi_data_if.exokay             ),
         .xif_compressed_if      ( xif.cpu_compressed             ),
         .xif_issue_if           ( xif.cpu_issue                  ),
         .xif_commit_if          ( xif.cpu_commit                 ),
         .xif_mem_if             ( xif.cpu_mem                    ),
         .xif_mem_result_if      ( xif.cpu_mem_result             ),
         .xif_result_if          ( xif.cpu_result                 ),

         .mcycle_o               ( mcycle                         ),
         .time_i                 ( mcycle                         ),

         .irq_i                  ( interrupt_if.irq               ),
         .wu_wfe_i               ( wfe_wu_if.wfe_wu               ),
         .clic_irq_i             ( clic_if.clic_irq               ),
         .clic_irq_id_i          ( clic_if.clic_irq_id            ),
         .clic_irq_level_i       ( clic_if.clic_irq_level         ),
         .clic_irq_priv_i        ( clic_if.clic_irq_priv          ),
         .clic_irq_shv_i         ( clic_if.clic_irq_shv           ),


         .fencei_flush_req_o     ( fencei_if.flush_req            ),
         .fencei_flush_ack_i     ( fencei_if.flush_ack            ),

         .debug_req_i            ( debug_if.debug_req             ),
         .debug_havereset_o      ( debug_havereset                ),
         .debug_running_o        ( debug_running                  ),
         .debug_halted_o         ( debug_halted                   ),
         .debug_pc_valid_o       ( debug_pc_valid                 ),
         .debug_pc_o             ( debug_pc                       ),

         .fetch_enable_i         ( core_cntrl_if.fetch_en         ),
         .core_sleep_o           ( core_status_if.core_busy       )
        );

endmodule : uvmt_cv32e40x_dut_wrap

`default_nettype wire

`endif // __UVMT_CV32E40X_DUT_WRAP_SV__
