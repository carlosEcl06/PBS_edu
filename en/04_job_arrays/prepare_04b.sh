#!/bin/bash
# Set up exercise 4b: pretend two array sub-jobs (samples 2 and 5) failed.
# Requires the six outputs of exercise 4a. Run on the login node:  ./prepare_04b.sh
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/04_job_arrays/stats"
SNAP="$WORKDIR/04_job_arrays/.snapshot_04b"
n=0
: > "$SNAP"
while IFS=$'\t' read -r id _ _; do
    n=$((n + 1))
    f="$OUT/$id.stats.tsv"
    [ -s "$f" ] || { echo "missing $f: finish exercise 4a first" >&2; exit 1; }
    printf '%s\t%s\t%s\n' "$n" "$id" "$(stat -c %Y "$f")" >> "$SNAP"
done < "$DATA_DIR/samples/samples.tsv"

for i in 2 5; do
    id="$(awk -F'\t' -v i="$i" '$1 == i { print $2 }' "$SNAP")"
    rm -f "$OUT/$id.stats.tsv"
    echo "removed output of sub-job $i ($id)"
done
echo
echo "Now re-run ONLY sub-jobs 2 and 5 (see README, exercise 4b), then ./check_04b.sh"
