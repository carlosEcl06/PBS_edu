#!/bin/bash
# Checks the results of exercise 1c (the job you wrote from scratch).
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/01_pbs_basics"
RES="$OUT/reference_stats.txt"
REF="$DATA_DIR/ref/genome.fasta"

echo "Checking exercise 1c..."
edu_expect_file "$RES" "your job must write $RES; check its log file"
if [ -s "$RES" ]; then
    read -r exp_seqs exp_len exp_gc < <(awk '/^>/ { n++; next } { len += length($0); gc += gsub(/[GCgc]/, "") } END { printf "%d %d %.2f\n", n, len, 100 * gc / len }' "$REF")
    get() { awk -F': ' -v k="$1" '$1 == k { print $2 }' "$RES"; }
    edu_expect_eq "sequences" "$exp_seqs" "$(get sequences)" "count the '>' header lines"
    edu_expect_eq "length" "$exp_len" "$(get length)" "sum the length of the non-header lines"
    edu_expect_eq "gc_percent" "$exp_gc" "$(get gc_percent)" "G and C, upper or lower case, over total length; 2 decimals"
    jid="$(get job_id)"
    case "$jid" in
        "" ) edu_fail "job_id line is empty" "write \"job_id: \$PBS_JOBID\" from INSIDE the job" ;;
        * ) edu_pass "job_id recorded ($jid)" ;;
    esac
    node="$(get host)"
    if [ -z "$node" ]; then
        edu_fail "host line is missing" "write \"host: \$(hostname)\""
    elif [ "$node" = "$(hostname)" ]; then
        edu_warn "host is '$node', the same machine you are on now. Did this run on the login node? (Fine on a single-machine cluster.)"
    else
        edu_pass "ran on a different machine than the login node ($node)"
    fi
fi
edu_summary
