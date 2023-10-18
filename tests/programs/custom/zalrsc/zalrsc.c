
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

typedef enum {
  MISALIGNED_LRW,
  MISALIGNED_SCW,
  UNEXPECTED_IRQ_BEH
} trap_behavior_t;

// trap handler behavior definitions
volatile trap_behavior_t trap_handler_beh; //TODO, krdosvik, why volatile?
volatile uint32_t num_misaligned_LRW_trapped;
volatile uint32_t num_misaligned_SCW_trapped;
volatile uint32_t unexpected_irq_beh;


int test_LR_SC_sequence_success(void);
int test_LR_SC_sequence_failure_address_mismatch(void);
int test_LR_SC_sequence_failure_additional_SC_access(void);
int test_LRW_misaligned_access(void);
int test_SCW_misaligned_access(void);

// Checks the mepc for compressed instructions and increments appropriately
void increment_mepc(void){
  volatile uint32_t insn, mepc;

  // read the mepc
  __asm__ volatile("csrrs %0, mepc, x0" : "=r"(mepc));

  // read the contents of the mepc pc.
  __asm__ volatile("lw %0, (%1)" : "=r"(insn) : "r"(mepc));

  // check for compressed instruction before increment.
  if ((insn & 0x3) == 0x3) {
    mepc += 4;
  } else {
    mepc += 2;
  }

  // write to the mepc
  __asm__ volatile("csrrw x0, mepc, %0" :: "r"(mepc));
}

// Rewritten interrupt handler
__attribute__ ((interrupt ("machine")))
void u_sw_irq_handler(void) {

  switch(trap_handler_beh) {

    case MISALIGNED_LRW :
      num_misaligned_LRW_trapped += 1;
      trap_handler_beh = UNEXPECTED_IRQ_BEH;
      increment_mepc();
      break;

    case MISALIGNED_SCW :
      num_misaligned_SCW_trapped += 1;
      trap_handler_beh = UNEXPECTED_IRQ_BEH;
      increment_mepc();
      break;

    default:
      unexpected_irq_beh += 1;
      increment_mepc();
  }

}

//TODO: krdosvik, understand where the flags to the simulator is comming from, and how to use them.

int main(int argc, char *argv[])
{
  volatile uint32_t failures=0;

  num_misaligned_LRW_trapped = 0;
  num_misaligned_SCW_trapped = 0;
  unexpected_irq_beh = 0;
  trap_handler_beh = UNEXPECTED_IRQ_BEH;

  failures += test_LR_SC_sequence_success();
  failures += test_LR_SC_sequence_failure_address_mismatch();
  failures += test_LR_SC_sequence_failure_additional_SC_access();
  failures += test_LRW_misaligned_access();
  failures += test_SCW_misaligned_access();
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

  __asm__ volatile("lr.w %0, (%1)"     : "=r" (random)     : "r" (mem_addr));
  __asm__ volatile("sc.w %0, %1, (%2)" : "=r" (is_failure) : "r" (random), "r" (mem_addr));

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

  __asm__ volatile("lr.w %0, (%1)"     : "=r" (random)      : "r" (mem_addr_LRW));
  __asm__ volatile("sc.w %0, %1, (%2)" : "=r" (is_failure)  : "r" (random), "r" (mem_addr_SCW));

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

  __asm__ volatile("lr.w %0, (%1)"     : "=r" (random)                    : "r" (mem_addr));
  __asm__ volatile("sc.w %0, %1, (%2)" : "=r" (is_failure_additional_SCW) : "r" (random), "r" (mem_addr_additional_SCW)); //TODO: krdosvik, not 100% sure if this should fail?
  __asm__ volatile("sc.w %0, %1, (%2)" : "=r" (is_failure)                : "r" (random), "r" (mem_addr));

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

  __asm__ volatile("lr.w %[random], (%[mem_addr_misaligned])" : [random]"=r" (random) : [mem_addr_misaligned]"r" (mem_addr_misaligned));

  //(Execute exception handler)

  if (num_misaligned_LRW_trapped != 1) {
    printf("Expected LRW to trap due to misaligned address. However, it did not.\n");
    return 1;
  }

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

  __asm__ volatile("sc.w %[is_failure], %[random], (%[mem_addr_misaligned])" : [is_failure]"=r" (is_failure) : [random]"r" (random), [mem_addr_misaligned]"r" (mem_addr_misaligned));

  //(Execute exception handler)

  if (num_misaligned_SCW_trapped != 1) {
    printf("Expected SCW to trap due to misaligned address. However, it did not.\n");
    return 1;
  }

  return 0;
}
