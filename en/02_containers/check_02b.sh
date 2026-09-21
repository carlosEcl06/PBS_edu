#!/bin/bash
# Checks exercise 2b (FastQC written from scratch).
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/02_containers/fastqc"
echo "Checking exercise 2b..."
for s in test_1 test_2; do
    edu_expect_file "$OUT/${s}_fastqc.html" "FastQC writes <name>_fastqc.html and .zip into the directory given with -o"
    edu_expect_file "$OUT/${s}_fastqc.zip"
done
if [ -s "$OUT/test_1_fastqc.zip" ] && command -v unzip >/dev/null 2>&1; then
    total="$(unzip -p "$OUT/test_1_fastqc.zip" test_1_fastqc/fastqc_data.txt 2>/dev/null | awk -F'\t' '$1 == "Total Sequences" { print $2 }')"
    edu_expect_eq "FastQC counted the reads of test_1" "100" "$total"
fi
edu_summary
