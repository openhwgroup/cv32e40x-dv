# CV32E40X: RISCOF RISCV-ARCH-TEST Suite Setup and Flow

Read the Documentation for Latest Requirements at [RISCOF Documentation](https://riscof.readthedocs.io/en/stable/).

## Requirements:

- **TOOLCHAIN**: riscv-gcc-toolchain or any other toolchain for riscv. This needs to be installed and path added to PATH env variable. Also the riscof/config.ini file needs to be updated with toolchain prefix for example: "unknown" or "corev" as part of riscv32-unknown-elf-gcc or riscv32-corev-elf-gcc respectively.
- **RISCOF**: Riscof tool needs to be installed on the machines and Path variable set for use of riscof command. Please refer to `Quickstart --> Install` RISCOF section of the documentation above.
- **Sail Reference Model**: Please refer to `Quickstart --> Install` Plugin Models for SAIL Reference Model installation guide in documentation above.
- **DUT Simulation Setup**: The simulation can be triggered from this sim/riscof dir in same way as sim/uvmt dir and would create a directory structure similar to other uvmt simulations. for example `xrun_results/default/` in sim/riscof directory. We need to setup the $CV_SIMULATOR based on tool that we want to use for DUT simulation.
The riscof work directory called `riscof_work` will be available inside the simulation output directory and will contain generated makefiles for both the DUT and reference.

## Steps:

- `cd core-v-verif/cv32e40x/sim/riscof`
- `make setup_riscof_sim CFG=<cfg_name>` : Run this step preferably only once to avoid doing git clone everytime. This step will do git clone for the compilance test suite - `riscv-arch-test` in vendor_lib/riscof/riscof_arch_test_suite directory and also do a sanity RTL compilation. `CFG` option here is to ensure relevant SIM RUN directory based on CFG is created, else `default` CFG will be selected to create directory path similar to uvmt simulations.
    - **Example : `make setup_riscof_sim CFG=default`**

- `make riscof_get_testlist CFG=<cfg_name> RISCOF_CONFIG_FILE=<riscof_config_ini_file>` : This is an optional step. This is basically a sanity check to validate the make scripts, flow and all riscof setup files are validated before running.

- `make riscof_run_all CFG=<cfg_name> RISCOF_CONFIG_FILE=<riscof_config_ini_file>` :  Final RUN command to trigger the complete compilance run with RISCOF. Prior to starting this this please ensure "config.ini" file in sim/riscof/ is setup correctly before triggering this.
    - **Example : `make riscof_run_all CFG=default RISCOF_CONFIG_FILE=config.ini`**
        - `CFG` : this is same as CFG argument for makefile as used in usual core-v-verif testbench for simulations to select required CORE configuration.
        - `RISCOF_CONFIG_FILE=<riscof_config_ini_file>` : Default value for this is set as config.ini if nothing is provided. This is added to support the need to be able to use and run riscof with different config.ini files in future based on needs to run compliance with different DUT versions or just run with different config files added in riscof dir with different config values for same DUT target

### Example Steps:

1. cd core-v-verif/cv32e40x/sim/riscof

2. make setup_riscof_sim CFG=default

3. make riscof_get_testlist CFG=default USE_ISS=no (Optional)

4. make riscof_run_all CFG=default RISCOF_CONFIG_FILE=config.ini

(NOTE: in case of ISS compile errors, add USE_ISS={no/yes} to the make commands above, matching config value for iss)
 
## config.ini:

- This file is default configuration file name given as input to riscof.
- It is possible to add more such files with different names to have different configurations running. Any config file added just needs to be passed to riscof command via the make argument `RISCOF_CONFIG_FILE`
- Some important things to consider for anyone using this setup, is to ensure to modify/update the existing config.ini file or add new such files with different names and as per the individual core/setup requirements and to pass the relevant file with riscof make command arguments.
    -   Some common configs to consider here:
        - **jobs** : To select number of parallel make targets to execute, or number of parallel jobs running.
        - **dut_cfg** : At this time this is the **Actual** `CFG` value that will create correct DUT compile options passed for each individual simulation's make command. And it is expected to be kept same as `CFG` argument passed for the riscof RUN make command from shell. As an example: the expectation is CFG is same at both places, which means:
            - In config.ini file:  dut_cfg=default
            - Shell make command:  make riscof_run_all CFG=default RISCOF_CONFIG_FILE=config.ini
           
        - **sw_toolchain_prefix** : to provide chosen riscv toolchain's prefix. Example: `unknown` for riscv32-unknown-elf-gcc.
        - **yaml files** : it is possible to add different ispec/pspec yaml files with needed isa/platform values and modify the path for such files in config file.
        - **docker** : for sail_cSim it is required to be set to :
            - True : indicating that docker image is used for SAIL ref model and the docker image to be used is set by the **image** config.
            - False : SAIL is installed and available directly on the machine.
            The SAIL executable path, if installed, could be added to env PATH variable or alternatively the **PATH** config of sail_cSim can be used to set it.
        - **imperas_iss** : set it to yes or no based on decision to run with imperas iss enabled for DUT simulations or not.

## NOTES:

- For debugging purposes, if required,  we can make use of the final DUT Makefile generated by plugins in riscof_work directory to run the failed tests for DUT individualy using those individual make target commands and running them directly in shell with more debugging options like WAVES, VERBOSE, USE_ISS etc. Some of the TB logs are disabled in riscof_firmware uvm test to avoid large disk space usage for regression, which may be re-enabled if required.

- signature writer for DUT is added within the uvm test uvmt_cv32e40x_riscof_firmware_test.sv. This function may be required to be updated in future.

- For subsequent rerunning of the riscof suite without doing the clone of riscv-arch-test suite again, run the below compilation command before full riscof run at any time.
    - **`make comp_dut_rtl_riscof_sim CFG=<cfg_name>`** : Only does a sanity RTL compilation for riscof DUT simulations and create the work dir for running simulations.

- This setup for CV32E40X has been validated to work for the implemented standard ISA extentions supported by this CORE default configuration and the ISA configuration used in config.ini is `RV32IMCZicsr_Zifencei_Zba_Zbb_Zbc_Zbs`.
