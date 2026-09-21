#!/bin/bash
# Shared helpers for the PBS_edu scripts. Source this file, do not run it:
#
#   cd "$PBS_O_WORKDIR"        # job scripts start in $HOME, not where you ran qsub
#   source ../lib/edu.sh       # works when submitted from a section directory
#
# It loads your cluster settings (site.conf), the pinned container images
# (containers.conf) and a few small helpers. Read it -- it is short on purpose.

# Percentages and decimals must use "." on every machine (some locales use ",").
export LC_ALL=C

EDU_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -f "$EDU_ROOT/site.conf" ]; then
    echo "PBS_edu: $EDU_ROOT/site.conf not found." >&2
    echo "         Run 00_getting_started/setup.sh first (see 00_getting_started/README.md)." >&2
    return 1 2>/dev/null || exit 1
fi
# shellcheck disable=SC1091
source "$EDU_ROOT/site.conf"
# shellcheck disable=SC1091
source "$EDU_ROOT/containers.conf"

# ---------------------------------------------------------------- running tools

# Path of the .sif image for a tool name listed in containers.conf.
edu_sif() { echo "$SIF_CACHE/$1.sif"; }

# Comma-separated list of host directories made visible inside containers.
edu_binds() {
    local b="$EDU_ROOT,$DATA_DIR,$WORKDIR"
    [ -n "${BIND_PATHS:-}" ] && b="$b,$BIND_PATHS"
    echo "$b"
}

# Run a tool inside its container:   edu_exec samtools view -H x.bam
# The first word is BOTH the image name (samtools.sif) and the program to run in it.
# It is just a short way to write:
#   apptainer exec --bind <dirs> samtools.sif samtools view -H x.bam
edu_exec() {
    local tool="$1" sif
    sif="$(edu_sif "$tool")"
    if [ ! -f "$sif" ]; then
        echo "PBS_edu: image $sif is missing. Run 00_getting_started/pull_containers.sh" >&2
        return 127
    fi
    "$CONTAINER_RUNTIME" exec --bind "$(edu_binds)" "$sif" "$@"
}

# Wrapper around qsub that adds -q only when site.conf says a queue is required.
edu_qsub() {
    if [ -n "${EDU_QUEUE:-}" ]; then qsub -q "$EDU_QUEUE" "$@"; else qsub "$@"; fi
}

# ---------------------------------------------------------------- job hygiene

# Number of CPUs PBS gave this job. NCPUS is set by PBS inside jobs; do not use
# `nproc` here, on many clusters it reports every core of the node.
edu_threads() { echo "${NCPUS:-1}"; }

edu_banner() {
    echo "== job:   ${PBS_JOBID:-<not running under PBS>}"
    echo "== host:  $(hostname)"
    echo "== start: $(date)"
    echo "== cpus:  ${NCPUS:-unknown}"
}

# Fail early, with a clear message, if this node cannot do the work. A node
# with a missing runtime or an unmounted filesystem is a classic cause of jobs
# that die in the first second.
edu_preflight() {
    local bad=0
    if ! command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
        echo "PREFLIGHT FAIL on $(hostname): '$CONTAINER_RUNTIME' is not in PATH" >&2
        bad=1
    fi
    for d in "$DATA_DIR" "$SIF_CACHE"; do
        if [ ! -d "$d" ]; then
            echo "PREFLIGHT FAIL on $(hostname): directory not visible: $d" >&2
            bad=1
        fi
    done
    return $bad
}

# Append "<step> <start|end> <epoch-seconds>" to $EDU_TIMELINE (used in section 05).
edu_stamp() { printf '%s\t%s\t%s\n' "$1" "$2" "$(date +%s)" >> "${EDU_TIMELINE:?set EDU_TIMELINE first}"; }

# ---------------------------------------------------------------- exercise checks

EDU_FAILS=0
if [ -t 1 ]; then _G=$'\033[32m'; _R=$'\033[31m'; _Y=$'\033[33m'; _N=$'\033[0m'; else _G=""; _R=""; _Y=""; _N=""; fi

edu_pass() { printf '  %sPASS%s  %s\n' "$_G" "$_N" "$1"; }
edu_warn() { printf '  %sWARN%s  %s\n' "$_Y" "$_N" "$1"; }
edu_fail() {
    printf '  %sFAIL%s  %s\n' "$_R" "$_N" "$1"
    [ -n "${2:-}" ] && printf '        hint: %s\n' "$2"
    EDU_FAILS=$((EDU_FAILS + 1))
}

# edu_expect_file <path> [hint]
edu_expect_file() {
    if [ -s "$1" ]; then edu_pass "found $1"; else edu_fail "missing or empty: $1" "${2:-}"; fi
}

# edu_expect_eq <description> <expected> <actual> [hint]
edu_expect_eq() {
    if [ "$2" = "$3" ]; then edu_pass "$1 ($3)"; else edu_fail "$1: expected '$2', got '${3:-<nothing>}'" "${4:-}"; fi
}

# Exit status of a finished job, from PBS history (empty if history is disabled).
edu_job_exit_status() { qstat -xf "$1" 2>/dev/null | awk -F' = ' '/Exit_status/ {print $2}'; }

edu_summary() {
    echo
    if [ "$EDU_FAILS" -eq 0 ]; then echo "All checks passed. Nice work!"; else echo "$EDU_FAILS check(s) failed -- read the hints above and try again."; fi
    return "$EDU_FAILS"
}
