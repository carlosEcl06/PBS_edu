#!/bin/bash
# Checks exercise 6b (the interactive session).
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

RES="$WORKDIR/06_interactive_and_nodes/interactive_proof.txt"
echo "Checking exercise 6b..."
edu_expect_file "$RES" "create it from INSIDE the interactive session (see README)"
if [ -s "$RES" ]; then
    get() { awk -F': ' -v k="$1" '$1 == k { print $2 }' "$RES"; }
    [ -n "$(get job_id)" ] && edu_pass "job_id recorded ($(get job_id))" || edu_fail "job_id is empty" "inside the session, \$PBS_JOBID is set; outside it is not"
    [ -n "$(get host)" ] && edu_pass "host recorded ($(get host))" || edu_fail "host is empty"
    edu_expect_eq "CPUs of the session" "2" "$(get ncpus)" "request the session with select=1:ncpus=2:mem=4gb"
    [ -s "$(dirname "$RES")/interactive_stats.tsv" ] && edu_pass "seqkit output saved" || edu_fail "interactive_stats.tsv missing" "run the seqkit command from the README inside the session"
fi
edu_summary
