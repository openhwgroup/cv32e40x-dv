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

module uvmt_cv32e40s_support_logic
  import uvm_pkg::*;
  import uvma_rvfi_pkg::*;
  import cv32e40s_pkg::*;
  (
    uvma_rvfi_instr_if rvfi,
    uvmt_cv32e40s_support_logic_if.write support_if
  );

    // ---------------------------------------------------------------------------
    // Local parameters
    // ---------------------------------------------------------------------------



    // ---------------------------------------------------------------------------
    // Local variables
    // ---------------------------------------------------------------------------
    logic exception_active;



    // ---------------------------------------------------------------------------
    // Support logic blocks
    // ---------------------------------------------------------------------------


    // Check if an obi data req arrives after an exception is triggered.
    // Used to verify exception timing with multiop instruction
    always @(posedge support_if.clk_i or negedge support_if.rst_ni) begin
      if (support_if.rst_ni) begin
        support_if.req_after_exception_o <= 0;
        exception_active <= 0;
      end else  begin

        if (rvfi.rvfi_valid) begin
          support_if.req_after_exception_o <= 0;
          exception_active <= 0;
        end else if (support_if.ctrl_fsm_o_i.pc_set && (support_if.ctrl_fsm_o_i.pc_mux == PC_TRAP_DBE || support_if.ctrl_fsm_o_i.pc_mux == PC_TRAP_EXC)) begin
          exception_active <= 1;
          if (support_if.data_bus_req_i) begin
            support_if.req_after_exception_o <= 1;
          end

        end else if (exception_active && support_if.data_bus_req_i)  begin
          support_if.req_after_exception_o <= 1;
        end

      end

    end //always



endmodule : uvmt_cv32e40s_support_logic
