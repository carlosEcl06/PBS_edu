#!/bin/bash
# Checks exercise 4a.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/04_job_arrays/stats"
echo "Checking exercise 4a..."
[ -s "$DATA_DIR/samples/samples.tsv" ] || { edu_fail "no samples.tsv" "run ../00_getting_started/make_samples.pbs first"; edu_summary; exit 1; }
while IFS=$'\t' read -r id _ _; do
    f="$OUT/$id.stats.tsv"
    edu_expect_file "$f" "did sub-job for $id run? qstat -xt / look at its log"
    if [ -s "$f" ]; then
        n="$(awk -F'\t' 'NR > 1 { print $4 }' "$f" | tr -d ',' | sort -u | tr '\n' ' ')"
        rows="$(awk 'END { print NR - 1 }' "$f")"
        edu_expect_eq "$id: files listed (R1 and R2)" "2" "$rows"
        edu_expect_eq "$id: reads per file" "$READS_PER_SAMPLE " "$n"
    fi
done < "$DATA_DIR/samples/samples.tsv"
edu_summary
