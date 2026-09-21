#!/bin/bash
# Checks exercise 2a.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

RES="$WORKDIR/02_containers/seqkit_stats.tsv"
echo "Checking exercise 2a..."
edu_expect_file "$RES" "did the job finish? read its log (ex02a.o<jobid>)"
if [ -s "$RES" ]; then
    for f in test_1.fastq.gz test_2.fastq.gz; do
        n="$(awk -F'\t' -v f="$f" '$1 ~ f { print $4 }' "$RES" | tr -d ',')"
        edu_expect_eq "reads in $f" "100" "$n" "the file should list both inputs with num_seqs = 100"
    done
fi
edu_summary
