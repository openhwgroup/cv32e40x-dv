#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# run-cv32e40x.sh — run a cv32e40x-dv Verilator certification ELF
#
# Selects the per-config Verilator binary built by `make certify CV_CORE_CONFIG=<CFG>`
# (mirrors cv32e40p-dv's run-cve4.sh) and runs one ELF through it. The testbench
# reads the ELF header for the entry point (boot_addr) and loads the sibling
# <base>.hex via $readmemh, so this wrapper generates the .hex (via objcopy) first.
# It is called once per ELF by the ACT4 run_tests.py harness, which appends the
# ELF path as the final argument. RVCP-SUMMARY output comes from the test itself,
# printed through the testbench virtual printer (mm_ram 0x1000_0000).
#
# Usage:
#   run-cv32e40x.sh --cfg <CV_CORE_CONFIG> --elf <elf-file>
#
# Environment:
#   CVE40X_DV_ROOT  — path to the cv32e40x-dv checkout (default: derived from this
#                     script's location, two levels up from .github/scripts/)
#   CV_SW_PREFIX    — RISC-V toolchain prefix (default: riscv64-unknown-elf-)
#   CERT_MAXCYCLES  — per-test cycle bound (default: 200000)
set -euo pipefail

CFG=""
ELF=""

usage() {
    echo "Usage: run-cv32e40x.sh --cfg <CV_CORE_CONFIG> --elf <elf-file>" >&2
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --cfg) CFG="$2"; shift 2 ;;
        --elf) ELF="$2"; shift 2 ;;
        -*)    echo "Unknown argument: $1" >&2; usage; exit 2 ;;
        *)     ELF="$1"; shift ;;
    esac
done

: "${CFG:?--cfg <CV_CORE_CONFIG> is required}"
: "${ELF:?ELF file is required (pass --elf <file> or as final positional argument)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CVE40X_DV_ROOT="${CVE40X_DV_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
SIM="$CVE40X_DV_ROOT/sim/core/simulation_results/certification_${CFG}/verilator_executable"
CV_SW_PREFIX="${CV_SW_PREFIX:-riscv64-unknown-elf-}"
CERT_MAXCYCLES="${CERT_MAXCYCLES:-200000}"

[[ -x "$SIM" ]] || {
    echo "verilator_executable not found for cfg=$CFG at $SIM" >&2
    echo "Build it with: make certify CV_CORE_CONFIG=$CFG (in $CVE40X_DV_ROOT/sim/core/)" >&2
    exit 2
}

# Generate <base>.hex if missing or older than the ELF; the testbench loads it.
HEX="${ELF%.*}.hex"
if [[ ! -f "$HEX" || "$ELF" -nt "$HEX" ]]; then
    "${CV_SW_PREFIX}objcopy" -O verilog "$ELF" "$HEX"
fi

exec "$SIM" "+maxcycles=$CERT_MAXCYCLES" "+elf_file=$ELF"
