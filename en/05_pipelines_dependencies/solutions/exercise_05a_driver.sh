#!/bin/bash
# Solution to exercise 5a. Run from the section directory: ./solutions/exercise_05a_driver.sh

# this file lives in solutions/, the step scripts are one directory up
cd "$(dirname "$0")/.." || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/05_pipelines_dependencies"
mkdir -p "$OUT"
: > "$OUT/timeline.tsv"
N="$(wc -l < "$DATA_DIR/samples/samples.tsv")"

# the script of the first step is step1_qc.pbs (the name is given without .pbs here)
J1="$(edu_qsub -J 1-"$N" step1_qc.pbs)" || exit 1
echo "step 1: $J1"

# the dependency type meaning "only if the earlier job succeeded" is afterok
J2="$(edu_qsub -J 1-"$N" -W depend=afterok:"$J1" step2_align.pbs)" || exit 1
echo "step 2: $J2"

# step 3 is a single job (no -J) that must wait for step 2. Which variable holds step 2's id?
J3="$(edu_qsub -W depend=afterok:"$J2" step3_summary.pbs)" || exit 1
echo "step 3: $J3"

echo "Watch with: qstat -t -u \$USER"
