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
///////////////////////////////////////////////////////////////////////////////
//
// Author: Kristine Døsvik
//
// DCSR STOPCOUNT test
//
/////////////////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "corev_uvmt.h"

#define DEBUG_STATUS_NOT_ENTERED  0
#define DEBUG_STATUS_ENTERED_OK   1

#define DEBUG_SET_DCSR_STOPCOUNT 0
#define DEBUG_CLEAR_DCSR_STOPCOUNT 1
#define DEBUG_RUN_COUNTER_CHECK 2
#define DEBUG_UNEXPECTED_ENTRY 3

#define DEBUG_REQ_CONTROL_REG *(volatile int *) CV_VP_DEBUG_CONTROL_BASE

#define DCSR_STOPCOUNT_BIT_POS 10
#define MHPMEVENT_INSTR_BIT_POS 1




volatile int g_debug_sel;
volatile int g_debug_entry_status;
volatile int g_is_failure;
volatile int g_unexpected_debug_entry;
volatile int g_is_dcsr_stopcount;


void _debugger_start(void)           __attribute__((section(".debugger"), naked));
void _debug_handler(void)            __attribute__((section(".debugger")));
void execute_debug_command(uint32_t dbg_cmd);

int counter3_minstret_tests(int is_dcsr_stopcount);
int clear_counter3 (void);


/*
 * debugger_start
 *
 * Debug handler wrapper
 *
 * Saves registers, calls debug handler and then restores the registers again.
 *
 */
void _debugger_start(void) {
  __asm__ volatile (R"(
    # Store return address and saved registers

      sw a0, -4(sp)
      sw a1, -8(sp)
      sw a2, -12(sp)
      sw a3, -16(sp)
      sw a4, -20(sp)
      sw a5, -24(sp)
      sw a6, -28(sp)
      sw a7, -32(sp)
      sw t0, -36(sp)
      sw t1, -40(sp)
      sw t2, -44(sp)
      sw t3, -48(sp)
      sw t4, -52(sp)
      sw t5, -56(sp)
      sw t6, -60(sp)
      addi sp, sp, -64

      cm.push {ra, s0-s11}, -64

    # Execute _debug_handler() function
      call ra, _debug_handler

    # Restore return address and saved registers
      cm.pop {ra, s0-s11}, 64

      addi sp, sp, 64
      lw a0, -4(sp)
      lw a1, -8(sp)
      lw a2, -12(sp)
      lw a3, -16(sp)
      lw a4, -20(sp)
      lw a5, -24(sp)
      lw a6, -28(sp)
      lw a7, -32(sp)
      lw t0, -36(sp)
      lw t1, -40(sp)
      lw t2, -44(sp)
      lw t3, -48(sp)
      lw t4, -52(sp)
      lw t5, -56(sp)
      lw t6, -60(sp)

    # Exit debug mode
      dret
  )");
}

/*
 * _debug_handler
 *
 * Debug Handler
 *
 * Handles all actions needed in debug mode.
 *
 */
void _debug_handler(void) {

  g_debug_entry_status = DEBUG_STATUS_ENTERED_OK;
  int set_dcsr_stopcount = (1 << DCSR_STOPCOUNT_BIT_POS);

  switch (g_debug_sel) {

    case DEBUG_SET_DCSR_STOPCOUNT:
      __asm__ volatile ("csrrs x0, dcsr, %[set_dcsr_stopcount]" :: [set_dcsr_stopcount]"r"(set_dcsr_stopcount));
      g_is_dcsr_stopcount = 1;
      g_debug_sel = DEBUG_UNEXPECTED_ENTRY;
      break;

    case DEBUG_CLEAR_DCSR_STOPCOUNT:
      __asm__ volatile ("csrrc x0, dcsr, %[set_dcsr_stopcount]" :: [set_dcsr_stopcount]"r"(set_dcsr_stopcount));
      g_is_dcsr_stopcount = 0;
      g_debug_sel = DEBUG_UNEXPECTED_ENTRY;
      break;

    case DEBUG_RUN_COUNTER_CHECK:
      g_is_failure += counter3_minstret_tests(g_is_dcsr_stopcount);
      g_debug_sel = DEBUG_UNEXPECTED_ENTRY;
      break;

    case DEBUG_UNEXPECTED_ENTRY:
    default:
      g_unexpected_debug_entry += 1;
      break;
  }
  return;
}

/*
 * execute_debug_command
 *
 * Sends commands debug handler
 *
 * Needed to execute commands that require to run with debug privelege
 *
 */
void execute_debug_command(uint32_t dbg_cmd) {

  g_debug_sel = dbg_cmd;

  g_debug_entry_status = DEBUG_STATUS_NOT_ENTERED;
  // Assert debug req
  DEBUG_REQ_CONTROL_REG = (CV_VP_DEBUG_CONTROL_DBG_REQ(0x1)        |
                           CV_VP_DEBUG_CONTROL_REQ_MODE(0x1)       |
                           CV_VP_DEBUG_CONTROL_PULSE_DURATION(0x8) |
                           CV_VP_DEBUG_CONTROL_START_DELAY(0xc8));
  // Wait for debug entry
  while (g_debug_entry_status == DEBUG_STATUS_NOT_ENTERED);
}

/*
 * clear_counter3
 *
 * Clear mhpmcounter nr.  and verify that the counter is cleared
 *
 */
int clear_counter3 (void) {

  int counter = 0;

  //Deactivate the counter
  __asm__ volatile(R"(
    mv t0, x0
    not t0, t0
    csrw mcountinhibit, t0
  )"::: "t0");

  //Clear the counter
  __asm__ volatile(R"(
    mv t0, x0
    csrw mhpmcounter3, t0
  )"::: "t0");

  //Read the counter's value
  __asm__ volatile("csrr %[counter], mhpmcounter3" : [counter]"=r"(counter));

  if (counter != 0){
    return 1;
  } else {
    return 0;
  }

}

/*
 * counter3_minstret_tests
 *
 * Configure the counter to count number of retired instructions,
 *
 * run a sequence with an expected number of instructions,
 *
 * and verify that mhpmcounter nr.  has counted, or not counted, the instructions according to DCSR's stopcount value.
 *
 */
int counter3_minstret_tests (int g_is_dcsr_stopcount)
  {
  int is_failure = 0;
  int counter = 0;
  int cnt_retired_instr = (1 << MHPMEVENT_INSTR_BIT_POS);
  int expected_minstret = 3 + 1; //3 nop instructions and 1 instruction to deactivate counter

  //Make the counter count number of retired instructions
  __asm__ volatile("csrw mhpmevent3, %0 " :: "r"(cnt_retired_instr));

  //Activate the counter, run some instructions, deactivate the counter
  __asm__ volatile(R"(
    mv t0, x0
    not t1, t0
    csrw mcountinhibit, t0
    nop
    nop
    nop
    csrw mcountinhibit, t1
  )"::: "t0", "t1");

  //Read the counter's value
  __asm__ volatile("csrr %[counter], mhpmcounter3" : [counter]"=r"(counter));

  if(g_is_dcsr_stopcount) {
    is_failure = counter != 0;
  } else {
    is_failure = counter != expected_minstret;
  }

  return is_failure;

}


int main(int argc, char *argv[])
{

  g_is_failure = 0;
  g_is_dcsr_stopcount = 0;
  g_unexpected_debug_entry = 0;
  g_debug_sel = DEBUG_UNEXPECTED_ENTRY;

  execute_debug_command(DEBUG_CLEAR_DCSR_STOPCOUNT);
  g_is_failure += clear_counter3();
  g_is_failure += counter3_minstret_tests(g_is_dcsr_stopcount);

  execute_debug_command(DEBUG_SET_DCSR_STOPCOUNT);
  g_is_failure += clear_counter3();
  execute_debug_command(DEBUG_RUN_COUNTER_CHECK);

  if(g_unexpected_debug_entry){
    printf("\ng_unexpected_debug_entry\n");
  }

  if(g_is_failure) {
    return EXIT_FAILURE;
  } else {
    return EXIT_SUCCESS;
  }

}

