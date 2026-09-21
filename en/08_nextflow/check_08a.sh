#!/bin/bash
# Checks exercise 8a.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/08_nextflow/results"
echo "Checking exercise 8a..."
n="$(sed -n 's/^ *n_samples *= *\([0-9]*\).*/\1/p' nextflow.config 2>/dev/null | head -1)"
[ -n "$n" ] || { edu_fail "no nextflow.config" "run ./make_config.sh"; edu_summary; exit 1; }
edu_expect_eq "SEQKIT_STATS outputs" "$n" "$(ls "$OUT"/seqkit/*.stats.tsv 2>/dev/null | wc -l)" "run: nextflow run exercise_08a_add_stats.nf -resume"
for f in "$OUT"/seqkit/*.stats.tsv; do
    [ -s "$f" ] || continue
    reads="$(awk -F'\t' 'NR == 2 { gsub(",", "", $4); print $4 }' "$f")"
    if [ "$reads" -gt 0 ] 2>/dev/null && [ "$reads" -le "$READS_PER_SAMPLE" ]; then edu_pass "$(basename "$f"): $reads cleaned reads"; else edu_fail "$(basename "$f"): unexpected read count '$reads'"; fi
done
edu_expect_eq "flagstat outputs (the rest of the pipeline)" "$n" "$(ls "$OUT"/flagstat/*.flagstat.txt 2>/dev/null | wc -l)"
edu_summary
