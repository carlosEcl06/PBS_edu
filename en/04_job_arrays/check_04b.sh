#!/bin/bash
# Checks exercise 4b: all outputs exist, and ONLY samples 2 and 5 were recomputed.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/04_job_arrays/stats"
SNAP="$WORKDIR/04_job_arrays/.snapshot_04b"
echo "Checking exercise 4b..."
[ -s "$SNAP" ] || { edu_fail "no snapshot" "run ./prepare_04b.sh first"; edu_summary; exit 1; }
while IFS=$'\t' read -r i id before; do
    f="$OUT/$id.stats.tsv"
    if [ ! -s "$f" ]; then edu_fail "sub-job $i ($id): output missing" "resubmit just that index: qsub -J 2-5:3 ..."; continue; fi
    now="$(stat -c %Y "$f")"
    case "$i" in
        2|5) if [ "$now" -gt "$before" ] || [ "$before" = "" ]; then edu_pass "sample $i ($id) was recomputed"; else edu_fail "sample $i ($id) still has its old output" "was the job for that index submitted and finished?"; fi ;;
        *)   if [ "$now" = "$before" ]; then edu_pass "sample $i ($id) untouched"; else edu_fail "sample $i ($id) was recomputed" "you re-ran the whole array; select only indices 2 and 5"; fi ;;
    esac
done < "$SNAP"
edu_summary
