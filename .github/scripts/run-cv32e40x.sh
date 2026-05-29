#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# run-cv32e40x.sh - run one cv32e40x-dv Verilator ACT4 certification ELF
#
# Selects the per-config Verilator binary built by
# `make certify CV_CORE_CONFIG=<CFG>` and runs a single ELF through it. The
# testbench reads the ELF header for its entry point (boot_addr) and loads the
# sibling <base>.hex via $readmemh, so this wrapper regenerates the .hex (via
# objcopy) first. Intended to be called once per ELF by the ACT4 run harness,
# which appends the ELF path as the final argument.
#
# Usage:
#   run-cv32e40x.sh --cfg <CV_CORE_CONFIG> [--elf] <elf-file>
#
# Environment:
#   CVE40X_DV_ROOT  - path to the cv32e40x-dv checkout (default: derived from
#                     this script's location, two levels up from .github/scripts/)
#   CERT_SW_PREFIX  - RISC-V toolchain prefix for objcopy (default:
#                     riscv64-unknown-elf-)
#   CERT_MAXCYCLES  - per-test cycle bound (default: 200000)
#   SIM_TIMEOUT     - wall-clock cap passed to coreutils `timeout` (default:
#                     120s; hung tests exit 124 instead of blocking the harness)
set -euo pipefail

CFG=""
ELF=""

usage() { echo "Usage: run-cv32e40x.sh --cfg <CV_CORE_CONFIG> [--elf] <elf-file>" >&2; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --cfg) [[ $# -ge 2 ]] || { usage; exit 2; }; CFG="$2"; shift 2 ;;
        --elf) [[ $# -ge 2 ]] || { usage; exit 2; }; ELF="$2"; shift 2 ;;
        -*)    echo "Unknown argument: $1" >&2; usage; exit 2 ;;
        *)     ELF="$1"; shift ;;
    esac
done

: "${CFG:?--cfg <CV_CORE_CONFIG> is required (e.g. rv32imc, rv32imcab)}"
: "${ELF:?ELF file is required (pass --elf <file> or as final positional argument)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CVE40X_DV_ROOT="${CVE40X_DV_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
CERT_SW_PREFIX="${CERT_SW_PREFIX:-riscv64-unknown-elf-}"
CERT_MAXCYCLES="${CERT_MAXCYCLES:-200000}"
SIM_TIMEOUT="${SIM_TIMEOUT:-120s}"

[[ -f "$CVE40X_DV_ROOT/sim/core/Makefile" ]] || {
    echo "CVE40X_DV_ROOT does not look like a cv32e40x-dv checkout: $CVE40X_DV_ROOT" >&2
    echo "Set CVE40X_DV_ROOT explicitly." >&2
    exit 2
}

SIM="$CVE40X_DV_ROOT/sim/core/simulation_results/certification_${CFG}/verilator_executable"

[[ -x "$SIM" ]] || {
    echo "verilator_executable not found for cfg=$CFG at $SIM" >&2
    echo "Build it with: make certify CV_CORE_CONFIG=$CFG (in $CVE40X_DV_ROOT/sim/core/)" >&2
    exit 2
}

# Generate <base>.hex if missing or older than the ELF; the testbench loads it.
# Split the path before stripping the extension so a dot in a directory
# component does not truncate the name.
ELF_DIR="${ELF%/*}"
ELF_BASE="${ELF##*/}"
HEX="$ELF_DIR/${ELF_BASE%.*}.hex"
if [[ ! -f "$HEX" || "$ELF" -nt "$HEX" ]]; then
    "${CERT_SW_PREFIX}objcopy" -O verilog "$ELF" "$HEX"
fi

exec timeout "$SIM_TIMEOUT" "$SIM" "+maxcycles=$CERT_MAXCYCLES" "+elf_file=$ELF"
