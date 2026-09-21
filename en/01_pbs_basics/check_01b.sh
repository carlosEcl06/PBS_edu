#!/bin/bash
# Checks the results of exercise 1b.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/01_pbs_basics"
FASTQ="$DATA_DIR/real/test_1.fastq.gz"

echo "Checking exercise 1b..."
edu_expect_file "$OUT/length_histogram.tsv" "the script never got as far as writing it: what does the log say?"
if [ -s "$OUT/length_histogram.tsv" ]; then
    expected="$(zcat "$FASTQ" | awk 'NR % 4 == 2 { print length($0) }' | sort -n | uniq -c | awk '{ print $2 "\t" $1 }')"
    edu_expect_eq "histogram content" "$(echo "$expected" | md5sum | cut -c1-8)" "$(md5sum < "$OUT/length_histogram.tsv" | cut -c1-8)" "the histogram differs from the expected one"
fi
edu_expect_file "$OUT/length_hist.done" "the job did not reach its last line: was it killed? (qstat -xf <jobid> -> Exit_status; 271 = killed by PBS)"
edu_summary
