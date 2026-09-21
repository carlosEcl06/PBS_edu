#!/bin/bash
# A tiny pipeline driver: submits step 1 (QC) and step 2 (alignment) so that step 2
# starts only when step 1 has finished successfully. Run it on the LOGIN node; it
# does not compute anything, it only submits jobs.
#
#   ./example_two_step_driver.sh
#   qstat -u $USER            # step 2 waits in state H (held) until step 1 is done
#
# Try the failure experiment from the README:
#   EDU_INJECT_FAILURE=step2 ./example_two_step_driver.sh

cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/05_pipelines_dependencies"
mkdir -p "$OUT"
: > "$OUT/timeline.tsv"

N="$(wc -l < "$DATA_DIR/samples/samples.tsv")"

# qsub prints the new job's id on stdout: capture it in a variable
J1="$(edu_qsub -J 1-"$N" step1_qc.pbs)" || exit 1
echo "step 1 (QC, array of $N):     $J1"

# -W depend=afterok:<id>  ==  "start only if <id> finished with exit status 0".
# For an array id, PBS waits for ALL its sub-jobs.
J2="$(edu_qsub -J 1-"$N" -W depend=afterok:"$J1" -v EDU_INJECT_FAILURE="${EDU_INJECT_FAILURE:-none}" step2_align.pbs)" || exit 1
echo "step 2 (align, array of $N):  $J2   (waits for $J1)"

echo
echo "Watch:  qstat -t -u \$USER"
echo "Clean up if something is stuck:  qdel '$J1' '$J2'"
