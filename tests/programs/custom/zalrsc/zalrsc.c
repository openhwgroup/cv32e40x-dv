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
// ZALRSC directed tests
//
/////////////////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#define LR_W 0
#define SC_W 1

typedef enum {
  MISALIGNED_LRW,
  MISALIGNED_SCW,
  NONATOMIC_REGION,
  UNEXPECTED_IRQ_BEH
} trap_behavior_t;

// trap handler behavior definitions
volatile trap_behavior_t trap_handler_beh;
volatile uint32_t misaligned_LRW_trapped;
volatile uint32_t misaligned_SCW_trapped;
volatile uint32_t zalrsc_nonatomic_region_trapped;
volatile uint32_t unexpected_irq_beh;


int test_LR_SC_sequence_success(void);
int test_LR_SC_sequence_failure_address_mismatch(void);
int test_LR_SC_sequence_failure_additional_SC_access(void);
int test_LRW_misaligned_access(void);
int test_SCW_misaligned_access(void);
int test_zalrsc_to_non_atomic_region(uint8_t is_scw);


// Checks the mepc for compressed instructions and increments appropriately
void increment_mepc(void){
  volatile uint32_t insn, mepc;

  // read the mepc
  __asm__ volatile("csrrs %[mepc], mepc, x0" : [mepc]"=r"(mepc));

  // read the contents of the mepc pc.
  __asm__ volatile("lw %[insn], (%[mepc])" : [insn]"=r"(insn) : [mepc]"r"(mepc));

  // check for compressed instruction before increment.
  if ((insn & 0x3) == 0x3) {
    mepc += 4;
  } else {
    mepc += 2;
  }

  // write to the mepc
  __asm__ volatile("csrrw x0, mepc, %[mepc]" :: [mepc]"r"(mepc));
}

// Rewritten interrupt handler
void trap_handler(void) {

  switch(trap_handler_beh) {

    case MISALIGNED_LRW :
      misaligned_LRW_trapped = 1;
      trap_handler_beh = UNEXPECTED_IRQ_BEH;
      increment_mepc();
      break;

    case MISALIGNED_SCW :
      misaligned_SCW_trapped = 1;
      trap_handler_beh = UNEXPECTED_IRQ_BEH;
      increment_mepc();
      break;

    case NONATOMIC_REGION :
      zalrsc_nonatomic_region_trapped = 1;
      trap_handler_beh = UNEXPECTED_IRQ_BEH;
      increment_mepc();
      break;

    default:
      unexpected_irq_beh += 1;
      increment_mepc();
  }
}

__attribute__((interrupt ("machine")))
void  u_sw_irq_handler(void) {
  __asm__ volatile (R"(
    # Backup "sp", use debug's own stack
    # csrw dscratch0, sp
    # la sp, __debugger_stack_start

    # Backup all GPRs
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

    # Call the handler actual
    call ra, trap_handler

    # Restore all GPRs
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

    # Restore "sp"
    # csrr sp, dscratch0

    # Done
    mret
  )");
}


int main(int argc, char *argv[])
{
  volatile uint32_t failures=0;

  misaligned_LRW_trapped = 0;
  misaligned_SCW_trapped = 0;
  unexpected_irq_beh = 0;
  trap_handler_beh = UNEXPECTED_IRQ_BEH;

  failures += test_LR_SC_sequence_success();
  failures += test_LR_SC_sequence_failure_address_mismatch();
  failures += test_LR_SC_sequence_failure_additional_SC_access();
  failures += test_LRW_misaligned_access();
  failures += test_SCW_misaligned_access();
  failures += test_zalrsc_to_non_atomic_region(LR_W);
  failures += test_zalrsc_to_non_atomic_region(SC_W);
  failures += unexpected_irq_beh;

  if(failures == 0){
    return EXIT_SUCCESS;

  } else if (unexpected_irq_beh) {
    printf("\n\nTest run fails due to unexpected traps.\n\n");
    return EXIT_FAILURE;

  } else {
    return EXIT_FAILURE;
  }
}

int test_LR_SC_sequence_success(void)
{
  printf("\n\nTest LR.W SC.W sequence constructed to succeed.\n\n");

  volatile uint32_t mem_addr = 0;
  volatile uint32_t is_failure = 0;
  volatile uint32_t random = 0;

  mem_addr = (uint32_t)&mem_addr;

  __asm__ volatile("lr.w %[random], (%[mem_addr])"
  : [random]"=r"(random)
  : [mem_addr]"r"(mem_addr));

  __asm__ volatile("sc.w %[is_failure], %[random], (%[mem_addr])"
  : [is_failure]"=r"(is_failure)
  : [random] "r"(random), [mem_addr]"r"(mem_addr));

  if (is_failure) {
    printf("Expected sequence to succeed. However, it did not.\n");
    return 1;
  }

  return 0;
}

int test_LR_SC_sequence_failure_address_mismatch(void)
{
  printf("\n\nTest LR.W SC.W sequence constructed to fail due to SC.W address mismatch.\n\n");

  volatile uint32_t mem_addr_LRW = 0;
  volatile uint32_t mem_addr_SCW = 0;
  volatile uint32_t is_failure = 0;
  volatile uint32_t random = 0;

  mem_addr_LRW = (uint32_t)&mem_addr_LRW;
  mem_addr_SCW = (uint32_t)&mem_addr_SCW;

  __asm__ volatile("lr.w %[random], (%[mem_addr_LRW])"
  : [random]"=r"(random)
  : [mem_addr_LRW]"r"(mem_addr_LRW));

  __asm__ volatile("sc.w %[is_failure], %[random], (%[mem_addr_SCW])"
  : [is_failure]"=r"(is_failure)
  : [random] "r"(random), [mem_addr_SCW]"r"(mem_addr_SCW));

  if (!is_failure) {
    printf("Expected sequence to fail. However, it did not.\n");
    return 1;
  }

  return 0;
}

int test_LR_SC_sequence_failure_additional_SC_access(void)
{
  printf("\n\nTest LR.W SC.W sequence constructed to fail due to additional SC.W access, before SC.W access the address LR.W original reserved.\n\n");

  volatile uint32_t mem_addr;
  volatile uint32_t mem_addr_additional_SCW;
  volatile uint32_t is_failure_additional_SCW;
  volatile uint32_t is_failure;
  volatile uint32_t random;

  mem_addr                = (uint32_t)&mem_addr;
  mem_addr_additional_SCW = (uint32_t)&mem_addr_additional_SCW;

  __asm__ volatile("lr.w %[random], (%[mem_addr])"
  : [random]"=r"(random)
  : [mem_addr]"r"(mem_addr));

  __asm__ volatile("sc.w %[is_failure_additional_SCW], %[random], (%[mem_addr_additional_SCW])"
  : [is_failure_additional_SCW]"=r"(is_failure_additional_SCW)
  : [random]"r"(random), [mem_addr_additional_SCW]"r"(mem_addr_additional_SCW));

  __asm__ volatile("sc.w %[is_failure], %[random], (%[mem_addr])"
  : [is_failure]"=r"(is_failure)
  : [random] "r"(random), [mem_addr]"r"(mem_addr));

  if (!is_failure_additional_SCW) {
    printf("Expected SCW instruction to fail. However, it did not.\n");
    return 1;
  } else if (!is_failure) {
    printf("Expected sequence to fail. However, it did not.\n");
    return 1;
  }

  return 0;
}

int test_LRW_misaligned_access(void)
{
  printf("\n\nTest that a misaligned LR.W instruction fails.\n\n");

  volatile uint32_t mem_addr_misaligned;
  volatile uint32_t random;

  mem_addr_misaligned = ((uint32_t)&mem_addr_misaligned) +1;
  trap_handler_beh = MISALIGNED_LRW;

  __asm__ volatile("lr.w %[random], (%[mem_addr_misaligned])" : [random]"=r"(random) : [mem_addr_misaligned]"r"(mem_addr_misaligned));

  //(Execute exception handler)

  if (misaligned_LRW_trapped != 1) {
    printf("Expected LRW to trap due to misaligned address. However, it did not.\n");
    return 1;
  }

  misaligned_LRW_trapped = 0;
  return 0;
}

int test_SCW_misaligned_access(void)
{
  printf("\n\nTest that a misaligned SC.W instruction fails.\n\n");

  volatile uint32_t mem_addr_misaligned;
  volatile uint32_t is_failure;
  volatile uint32_t random;

  mem_addr_misaligned = ((uint32_t)&mem_addr_misaligned) +1;
  trap_handler_beh = MISALIGNED_SCW;

  __asm__ volatile("sc.w %[is_failure], %[random], (%[mem_addr_misaligned])" : [is_failure]"=r"(is_failure) : [random]"r"(random), [mem_addr_misaligned]"r"(mem_addr_misaligned));

  //(Execute exception handler)

  if (misaligned_SCW_trapped != 1) {
    printf("Expected SCW to trap due to misaligned address. However, it did not.\n");
    return 1;
  }

  misaligned_SCW_trapped = 0;
  return 0;
}

int test_zalrsc_to_non_atomic_region(uint8_t is_scw)
{
  printf("\n\nTest using LR.W on non atomic memory region.\n\n");

  volatile uint32_t nonatomic_region_addr = 0xFFFFFFFE;
  volatile uint32_t is_failure = 0;
  volatile uint32_t random = 0;
  trap_handler_beh = NONATOMIC_REGION;

  if (is_scw) {
    __asm__ volatile("sc.w %[is_failure], %[random], (%[nonatomic_region_addr])"
    : [is_failure]"=r"(is_failure)
    : [random] "r"(random), [nonatomic_region_addr]"r"(nonatomic_region_addr));

  } else {
    __asm__ volatile("lr.w %[random], (%[nonatomic_region_addr])"
    : [random]"=r"(random)
    : [nonatomic_region_addr]"r"(nonatomic_region_addr));
  }

  //(Execute exception handler)

  if (!zalrsc_nonatomic_region_trapped) {
    printf("Expected the zalrsc operation to trap due to pma error for accessing non atomic region. However, it did not.\n");
    return 1;
  }

  zalrsc_nonatomic_region_trapped = 0;
  return 0;
}

