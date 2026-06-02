// Wrapper for a CV32E40X "core" testbench,
// containing CV32E40X, Memory and virtual peripherals.
//
// Copyright 2026 Eclipse Foundation
// SPDX-License-Identifier: Apache-2.0 WITH SHL-0.51
//
// Copyright 2018 Robert Balas <balasr@student.ethz.ch>
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Wrapper for a CV32E40X testbench, containing CV32E40X, Memory and stdout peripheral
// Contributor: Robert Balas <balasr@student.ethz.ch>
// Module renamed from riscv_wrapper to cv32e40x_tb_wrapper because (1) the
// name of the core changed, and (2) the design has a cv32e40x_wrapper module.
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-0.51

module cv32e40x_tb_wrapper
    #(parameter // Parameters used by TB
                INSTR_RDATA_WIDTH = 32,
                RAM_ADDR_WIDTH    = 20,
                DM_HALTADDRESS    = 32'h1A11_0800,
                HART_ID           = 32'h0000_0000,
                IMP_ID            = 32'h0000_0000,
                // Parameters used by DUT
                NUM_MHPMCOUNTERS  = 1
    )
    (input logic         clk_i,
     input logic         rst_ni,

     input logic [31:0]  boot_addr_i,
     input logic         fetch_enable_i,
     output logic        tests_passed_o,
     output logic        tests_failed_o,
     output logic [31:0] exit_value_o,
     output logic        exit_valid_o);

    // signals connecting core to memory
    logic                         instr_req;
    logic                         instr_gnt;
    logic                         instr_rvalid;
    logic [31:0]                  instr_addr;
    logic [INSTR_RDATA_WIDTH-1:0] instr_rdata;

    logic                         data_req;
    logic                         data_gnt;
    logic                         data_rvalid;
    logic [31:0]                  data_addr;
    logic                         data_we;
    logic [3:0]                   data_be;
    logic [31:0]                  data_rdata;
    logic [31:0]                  data_wdata;
    logic [5:0]                   data_atop;
    logic                         data_exokay;

    // signals to debug unit
    logic                         debug_req;

    // irq signals
    logic [31:0]                  irq;
    logic [4:0]                   irq_id_in;
    logic                         irq_ack;
    logic [4:0]                   irq_id_out;
    logic                         irq_sec;


    // interrupts (only timer for now)
    assign irq_sec     = '0;
    // cv32e40x interrupts are level-sensitive (no core ack); tie off the legacy
    // ack/id so mm_ram's irq logic stays X-free now that irq feeds the core.
    assign irq_ack     = 1'b0;
    assign irq_id_out  = '0;

    // Platform time from mm_ram, feeding the core's time_i (time/timeh CSRs).
    logic [63:0] mtime;

   // eXtension Interface
    cv32e40x_if_xif #(
        .X_NUM_RS    ( 2  ),
        .X_MEM_WIDTH ( 32 ),
        .X_RFR_WIDTH ( 32 ),
        .X_RFW_WIDTH ( 32 ),
        .X_MISA      ( '0 )
    ) ext_if();


    // ISA extension selection. A_EXT/B_EXT are package enums, chosen from the
    // build's CV32E40X_RVA / CV32E40X_RVB compile defines (set per CV_CORE_CONFIG).
`ifdef CV32E40X_RVA
    localparam cv32e40x_pkg::a_ext_e A_EXT_CFG = cv32e40x_pkg::A;
`else
    localparam cv32e40x_pkg::a_ext_e A_EXT_CFG = cv32e40x_pkg::A_NONE;
`endif
`ifdef CV32E40X_RVB
    localparam cv32e40x_pkg::b_ext_e B_EXT_CFG = cv32e40x_pkg::ZBA_ZBB_ZBC_ZBS;
`else
    localparam cv32e40x_pkg::b_ext_e B_EXT_CFG = cv32e40x_pkg::B_NONE;
`endif

    // instantiate the core
    cv32e40x_core #(
                 .NUM_MHPMCOUNTERS (NUM_MHPMCOUNTERS),
                 .A_EXT            (A_EXT_CFG),
                 .B_EXT            (B_EXT_CFG)
                )
    cv32e40x_core_i
        (
         // Clock and Reset
         .clk_i                  ( clk_i                 ),
         .rst_ni                 ( rst_ni                ),

         .scan_cg_en_i           ( '0                    ),

         // Control interface: more or less static
         .boot_addr_i            ( boot_addr_i           ),
         .mtvec_addr_i           ( '0                    ),
         .dm_halt_addr_i         ( DM_HALTADDRESS        ),
         .mhartid_i              ( HART_ID               ),
         .mimpid_patch_i         ( 4'h0                  ),
         .dm_exception_addr_i    ( '0                    ),

         // Instruction memory interface
         .instr_req_o            ( instr_req             ),
         .instr_gnt_i            ( instr_gnt             ),
         .instr_rvalid_i         ( instr_rvalid          ),
         .instr_addr_o           ( instr_addr            ),
         .instr_memtype_o        (                       ), // TODO: should the core tb check this?
         .instr_prot_o           (                       ), // TODO: should the core tb check this?
         .instr_dbg_o            (                       ), // TODO: should the core tb check this?
         .instr_rdata_i          ( instr_rdata           ),
         .instr_err_i            ( 1'b0                  ),

         // Data memory interface
         .data_req_o             ( data_req              ),
         .data_gnt_i             ( data_gnt              ),
         .data_rvalid_i          ( data_rvalid           ),
         .data_we_o              ( data_we               ),
         .data_be_o              ( data_be               ),
         .data_addr_o            ( data_addr             ),
         .data_wdata_o           ( data_wdata            ),
         .data_rdata_i           ( data_rdata            ),
         .data_memtype_o         (                       ), // TODO: should the core tb check this?
         .data_prot_o            (                       ), // TODO: should the core tb check this?
         .data_dbg_o             (                       ), // TODO
         .data_err_i             ( 1'b0                  ),
         .data_atop_o            ( data_atop             ),
         .data_exokay_i          ( data_exokay           ),

         // Cycle Count
         .mcycle_o               (                       ),

         // Time input
         .time_i                 ( mtime                 ),

         // eXtension interface
         .xif_compressed_if      ( ext_if                ),
         .xif_issue_if           ( ext_if                ),
         .xif_commit_if          ( ext_if                ),
         .xif_mem_if             ( ext_if                ),
         .xif_mem_result_if      ( ext_if                ),
         .xif_result_if          ( ext_if                ),

         // Basic interrupt architecture (mm_ram CLINT MTIP + virtual timer)
         .irq_i                  ( irq                   ),

         // Event wakeup signals
         .wu_wfe_i               ( 1'b0                  ),

         // CLIC interrupt architecture
         .clic_irq_i             (  1'b0                 ),
         .clic_irq_id_i          (  '0                   ),
         .clic_irq_level_i       (  8'h0                 ),
         .clic_irq_priv_i        (  2'h0                 ),
         .clic_irq_shv_i         (  1'b0                 ),

         // Fence.i flush handshake
         .fencei_flush_req_o     (                       ),
         .fencei_flush_ack_i     ( 1'b1                  ),

         // Debug interface
         .debug_req_i            ( debug_req             ),
         .debug_havereset_o      (                       ),
         .debug_running_o        (                       ),
         .debug_halted_o         (                       ),
         .debug_pc_valid_o       (                       ),
         .debug_pc_o             (                       ),

         // CPU Control Signals
         .fetch_enable_i         ( fetch_enable_i        ),
         .core_sleep_o           ( core_sleep_o          )
       );

    // this handles read to RAM and memory mapped pseudo peripherals
    mm_ram
        #(.RAM_ADDR_WIDTH (RAM_ADDR_WIDTH),
          .INSTR_RDATA_WIDTH (INSTR_RDATA_WIDTH))
    ram_i
        (.clk_i          ( clk_i                                     ),
         .rst_ni         ( rst_ni                                    ),
         .dm_halt_addr_i ( DM_HALTADDRESS                            ),

         .instr_req_i    ( instr_req                                 ),
         .instr_addr_i   ( { {10{1'b0}},
                             instr_addr[RAM_ADDR_WIDTH-1:0]
                           }                                         ),
         .instr_rdata_o  ( instr_rdata                               ),
         .instr_rvalid_o ( instr_rvalid                              ),
         .instr_gnt_o    ( instr_gnt                                 ),

         .data_req_i     ( data_req                                  ),
         .data_addr_i    ( data_addr                                 ),
         .data_we_i      ( data_we                                   ),
         .data_be_i      ( data_be                                   ),
         .data_wdata_i   ( data_wdata                                ),
         .data_atop_i    ( data_atop                                 ),
         .data_rdata_o   ( data_rdata                                ),
         .data_exokay_o  ( data_exokay                               ),
         .data_rvalid_o  ( data_rvalid                               ),
         .data_gnt_o     ( data_gnt                                  ),

         .irq_id_i       ( irq_id_out                                ),
         .irq_ack_i      ( irq_ack                                   ),
         .irq_o          ( irq                                       ),

         .debug_req_o    ( debug_req                                 ),

         .pc_core_id_i   ( cv32e40x_core_i.if_id_pipe.pc             ),

         .tests_passed_o ( tests_passed_o                            ),
         .tests_failed_o ( tests_failed_o                            ),
         .exit_valid_o   ( exit_valid_o                              ),
         .exit_value_o   ( exit_value_o                              ),
         .mtime_o        ( mtime                                     ));

endmodule // cv32e40x_tb_wrapper
