#!/usr/bin/bash
# =============================================================================
# cpu-load-simulator.sh — CPU load simulator
#
# Usage:  cpu-load-simulator.sh.sh <core0_load> [core1_load] [core2_load] [core3_load]
#
# Load values: 0-100 (percent per core)
#
# Examples:
#   cpu-load-simulator.sh.sh 100          → core0=100%, all others idle
#   cpu-load-simulator.sh.sh 100 50       → core0=100%, core1=50%
#   cpu-load-simulator.sh.sh 100 100 50 0 → core0=100%, core1=100%, core2=50%, core3=0%
#
# Stop the test: Ctrl+C
# =============================================================================

set -euo pipefail

die() { echo "ERROR: $*" >&2; echo "Run with -h for usage." >&2; exit 1; }

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { sed -n '2,/^# ===/p' "$0" | sed 's/^# \?//'; exit 0; }
[[ $# -eq 0 ]] && die "At least one load value required."

command -v stress-ng &>/dev/null || die "stress-ng not found."

NUM_CORES=$(nproc)

[[ $# -gt $NUM_CORES ]] && die "Too many arguments: this system has $NUM_CORES cores."

# ---------------------------------------------------------------------------
# Parse and validate load arguments
# ---------------------------------------------------------------------------
declare -a LOADS
for (( i=0; i<NUM_CORES; i++ )); do
    val="${!i+${@:$((i+1)):1}}"
    val="${val:-0}"
    if ! [[ "$val" =~ ^[0-9]+$ ]] || (( val < 0 || val > 100 )); then
        die "Invalid load '$val' for core $i. Must be an integer 0-100."
    fi
    LOADS[i]="$val"
done

# ---------------------------------------------------------------------------
# Print plan
# ---------------------------------------------------------------------------
echo "Press Ctrl+C to stop."
echo ""
for (( i=0; i<NUM_CORES; i++ )); do
    [[ "${LOADS[$i]}" -gt 0 ]] && echo "  Core $i : ${LOADS[$i]}%" || echo "  Core $i : idle"
done
echo ""

# ---------------------------------------------------------------------------
# Cleanup on Ctrl+C
# ---------------------------------------------------------------------------
PIDS=()
cleanup() {
    echo ""
    echo "Stopping..."
    for pid in "${PIDS[@]}"; do kill "$pid" 2>/dev/null || true; done
    wait "${PIDS[@]}" 2>/dev/null || true
    echo "Done."
    exit 0
}
trap cleanup INT TERM

# ---------------------------------------------------------------------------
# Launch one stress-ng worker per active core
# ---------------------------------------------------------------------------
for (( i=0; i<NUM_CORES; i++ )); do
    [[ "${LOADS[$i]}" -eq 0 ]] && continue
    echo "core $i: stress-ng --taskset $i --cpu 1 --cpu-load ${LOADS[$i]} --cpu-method all"
    stress-ng --temp-path /tmp --taskset "$i" --cpu 1 --cpu-load "${LOADS[$i]}" --cpu-method all &>/dev/null &
    PIDS+=($!)
done

[[ ${#PIDS[@]} -eq 0 ]] && { echo "All cores idle — nothing to do."; exit 0; }

wait "${PIDS[@]}"
