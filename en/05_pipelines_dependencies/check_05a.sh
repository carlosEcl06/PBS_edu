#!/bin/bash
# Checks exercise 5a (and the pipeline itself): results are correct AND the
# steps really ran in order.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/05_pipelines_dependencies"
S="$OUT/summary.tsv"
echo "Checking exercise 5a..."
edu_expect_file "$S" "step 3 has not run: is the pipeline still going (qstat -t -u \$USER)? did a step fail? read the logs of each step"
if [ -s "$S" ]; then
    n="$(wc -l < "$DATA_DIR/samples/samples.tsv")"
    edu_expect_eq "rows in summary.tsv" "$n" "$(awk 'NR > 1' "$S" | wc -l)"
    if command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
        while IFS=$'\t' read -r id total mapped pct; do
            [ "$id" = sample ] && continue
            real="$(edu_exec samtools view -c "$OUT/bam/$id.bam" 2>/dev/null)"
            edu_expect_eq "$id total records match the BAM" "$real" "$total"
            if [ "$mapped" -le "$total" ] 2>/dev/null; then edu_pass "$id mapped <= total (${pct}% mapped)"; else edu_fail "$id: mapped ($mapped) > total ($total)"; fi
        done < "$S"
    else
        edu_warn "no $CONTAINER_RUNTIME on this node: skipping the comparison with the BAM files"
    fi
fi

# Ordering: the latest end of step N must not be later than the earliest start of step N+1.
T="$OUT/timeline.tsv"
if [ -s "$T" ]; then
    order() { # order <earlier> <later>
        local e l
        e="$(awk -F'\t' -v s="$1" '$1 == s && $2 == "end" && $3 > m { m = $3 } END { print m + 0 }' "$T")"
        l="$(awk -F'\t' -v s="$2" '$1 == s && $2 == "start" && (min == 0 || $3 < min) { min = $3 } END { print min + 0 }' "$T")"
        if [ "$e" -eq 0 ] || [ "$l" -eq 0 ]; then edu_fail "no timeline entries for $1 and/or $2"
        elif [ "$e" -le "$l" ]; then edu_pass "$2 started after $1 had finished"
        else edu_fail "$2 started before $1 finished" "the dependency is missing: -W depend=afterok:<previous job id>"; fi
    }
    order step1 step2
    order step2 step3
else
    edu_fail "no timeline.tsv" "it is written by the steps themselves"
fi
edu_summary
