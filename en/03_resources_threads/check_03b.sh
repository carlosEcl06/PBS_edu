#!/bin/bash
# Checks exercise 3b.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/03_resources_threads"
echo "Checking exercise 3b..."
edu_expect_file "$OUT/right_size.done" "the job did not finish: killed at the walltime? Check qstat -xf <jobid> (Exit_status 271) and the tail of the log"

wall="$(sed -n 's/^#PBS -l walltime=\([0-9:]*\).*/\1/p' exercise_03b_right_size.pbs | head -1)"
mem="$(sed -n 's/^#PBS -l select=.*mem=\([0-9]*\)gb.*/\1/p' exercise_03b_right_size.pbs | head -1)"
secs="$(echo "$wall" | awk -F: '{ print $1 * 3600 + $2 * 60 + $3 }')"
if [ -z "$mem" ]; then
    edu_fail "could not read mem=... from the script" "it must look like mem=4gb"
elif [ "$mem" -gt 8 ]; then
    edu_fail "you asked for ${mem} GB" "this job needs a few GB at most; requesting more delays it in the queue"
else
    edu_pass "memory request is reasonable (${mem} GB)"
fi
if [ -z "$secs" ]; then
    edu_fail "could not read the walltime"
elif [ "$secs" -gt 600 ]; then
    edu_fail "walltime is $wall" "the job takes about a minute or less; 10 minutes is already generous"
else
    edu_pass "walltime is reasonable ($wall)"
fi
[ -s "$OUT/right_size.done" ] && { echo "  job report: $(cat "$OUT/right_size.done")"; }
edu_summary
