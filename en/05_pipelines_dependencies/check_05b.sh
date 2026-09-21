#!/bin/bash
# Checks exercise 5b: your own step 4, chained after step 3.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/05_pipelines_dependencies"
R="$OUT/report.txt"
S="$OUT/summary.tsv"
T="$OUT/timeline.tsv"
echo "Checking exercise 5b..."
edu_expect_file "$S" "run the whole pipeline (exercise 5a) first"
edu_expect_file "$R" "your step 4 must write $R"
if [ -s "$R" ] && [ -s "$S" ]; then
    get() { awk -F': ' -v k="$1" '$1 == k { print $2 }' "$R"; }
    edu_expect_eq "samples" "$(awk 'NR > 1' "$S" | wc -l)" "$(get samples)"
    edu_expect_eq "well_mapped (mapped_pct >= 95)" "$(awk -F'\t' 'NR > 1 && $4 >= 95' "$S" | wc -l)" "$(get well_mapped)"
    s3="$(awk -F'\t' '$1 == "step3" && $2 == "end" { print $3 }' "$T" | sort -n | tail -1)"
    s4="$(awk -F'\t' '$1 == "step4" && $2 == "start" { print $3 }' "$T" | sort -n | head -1)"
    if [ -z "$s4" ]; then edu_fail "no 'step4 start' in timeline.tsv" "call edu_stamp step4 start / end in your script"
    elif [ "$s4" -ge "$s3" ]; then edu_pass "step 4 started after step 3 ended"
    else edu_fail "step 4 started before step 3 finished" "chain it: -W depend=afterok:<step 3 job id>"; fi
    [ -n "$(awk -F'\t' '$1 == "step4" && $2 == "end"' "$T")" ] && edu_pass "step 4 recorded its end" || edu_fail "no 'step4 end' in timeline.tsv"
fi
edu_summary
