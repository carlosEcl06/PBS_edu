#!/bin/bash
# Exercise 5a -- complete the pipeline driver (fill each ___), then run it on the
# login node:   ./exercise_05a_complete_the_driver.sh
#
# Goal: QC (step1_qc.pbs) -> align (step2_align.pbs) -> summary (step3_summary.pbs),
# each step starting only after the previous one succeeded.
# Afterwards, when all jobs are finished:   ./check_05a.sh

cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/05_pipelines_dependencies"
mkdir -p "$OUT"
: > "$OUT/timeline.tsv"
N="$(wc -l < "$DATA_DIR/samples/samples.tsv")"

# the script of the first step is step1_qc.pbs (the name is given without .pbs here)
J1="$(edu_qsub -J 1-"$N" ___.pbs)" || exit 1
echo "step 1: $J1"

# the dependency type meaning "only if the earlier job succeeded" is afterok
J2="$(edu_qsub -J 1-"$N" -W depend=___:"$J1" step2_align.pbs)" || exit 1
echo "step 2: $J2"

# step 3 is a single job (no -J) that must wait for step 2. Which variable holds step 2's id?
J3="$(edu_qsub -W depend=afterok:"$___" step3_summary.pbs)" || exit 1
echo "step 3: $J3"

echo "Watch with: qstat -t -u \$USER"
