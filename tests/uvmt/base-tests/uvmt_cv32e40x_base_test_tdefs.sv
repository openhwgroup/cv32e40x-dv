//
// Copyright 2023 Silicon Labs, Inc.
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


`ifndef __UVMT_CV32E40X_BASE_TEST_TDEFS_SV__
`define __UVMT_CV32E40X_BASE_TEST_TDEFS_SV__


/**
 * Test Program Type.  See the Verification Strategy for a discussion of this.
 */
typedef enum {
  PREEXISTING_SELFCHECKING,
  PREEXISTING_NOTSELFCHECKING,
  GENERATED_SELFCHECKING,
  GENERATED_NOTSELFCHECKING,
  NO_TEST_PROGRAM
} test_program_type;

typedef enum {
    FETCH_CONSTANT,
    FETCH_INITIAL_DELAY_CONSTANT,
    FETCH_RANDOM_TOGGLE
} fetch_toggle_t;


/**
 * PMA Status
 */
typedef struct packed {
  logic                        allow;
  logic                        main;
  logic                        bufferable;
  logic                        cacheable;
  logic                        atomic;
  logic                        override_dm;
  logic [PMA_MAX_REGIONS-1:0]  match_list;
  logic [31:0]                 match_idx;
  logic                        have_match;
  logic                        accesses_dmregion;
  logic                        accesses_jvt;
} pma_status_t;

typedef struct packed {
  obi_data_req_t  req;
  obi_data_resp_t resp;
  logic           valid;
} obi_data_packet_t;

typedef struct packed {
  obi_inst_req_t  req;
  obi_inst_resp_t resp;
  logic           valid;
} obi_instr_packet_t;


`endif // __UVMT_CV32E40X_BASE_TEST_TDEFS_SV__
