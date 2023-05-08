# SV/UVM Verification Environment for the CV32E40X CORE-V processor core.
**Note**: this is not a stand-alone repoistory.  It dependends on verification components and scriptware provided by [core-v-verif](https://github.com/openhwgroup/core-v-verif).

## Directories:
- **bsp**:   the "board support package" for test-programs compiled/assembled/linked for the CV32E40X simulation environment.
- **env**:   the UVM environment class and its associated infrastrucutre.
- **sim**:   directory where you run the simulations.
- **tb**:    the Testbench module that instanitates the core.
- **tests**: this is where all the testcases are.
- **vendor_lib**: libraries obtained from external vendors.

There are README files in each directory with additional information.
