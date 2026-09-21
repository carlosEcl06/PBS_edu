#!/bin/bash
# Checks the results of exercise 1a. Run it after your job has finished.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/01_pbs_basics"
FASTQ="$DATA_DIR/real/test_1.fastq.gz"
exp_reads=$(( $(zcat "$FASTQ" | wc -l) / 4 ))
exp_bases=$(zcat "$FASTQ" | awk 'NR % 4 == 2 { n += length($0) } END { print n }')

echo "Checking exercise 1a..."
edu_expect_file "$OUT/read_count.txt" "no output yet: is the job finished (qstat -u \$USER)? does its log show an error?"
edu_expect_file "$OUT/base_count.txt"
[ -s "$OUT/read_count.txt" ] && edu_expect_eq "read count" "$exp_reads" "$(cat "$OUT/read_count.txt")" "a FASTQ record has 4 lines"
[ -s "$OUT/base_count.txt" ] && edu_expect_eq "base count" "$exp_bases" "$(cat "$OUT/base_count.txt")" "sum length() of line 2 of every record"
edu_summary
