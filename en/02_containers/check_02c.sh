#!/bin/bash
# Checks exercise 2c.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

RES="$WORKDIR/02_containers/bind_ok.tsv"
echo "Checking exercise 2c..."
if [ ! -s "$DATA_DIR/samples/samples.tsv" ]; then
    edu_fail "the simulated samples do not exist yet" "run: qsub ../00_getting_started/make_samples.pbs"
else
    edu_expect_file "$RES" "the job failed or has not finished; a 'No such file' error in its log means the data directory was not bound"
    if [ -s "$RES" ]; then
        for r in R1 R2; do
            n="$(awk -F'\t' -v f="sample_01_$r" '$1 ~ f { print $4 }' "$RES" | tr -d ',')"
            edu_expect_eq "reads in sample_01_$r" "$READS_PER_SAMPLE" "$n" "seqkit should have read the file"
        done
    fi
fi
edu_summary
