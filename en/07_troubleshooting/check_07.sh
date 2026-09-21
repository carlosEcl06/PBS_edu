#!/bin/bash
# Checks the fixed broken jobs.
#   ./check_07.sh        all six
#   ./check_07.sh 3      only job 3
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/07_troubleshooting"
which="${1:-1 2 3 4 5 6}"
echo "Checking exercise 7..."
for n in $which; do
    f="$OUT/broken_0$n.ok"
    case "$n" in
        1) want="reads: 100"; hint="the count is wrong: was the file really read? look at the log's FIRST lines";;
        2) want="aligned: 2 samples"; hint="the job never reached its last line: qstat -xf <jobid> -> Exit_status and resources_used.walltime";;
        3) want=""; hint="the job never ran: qstat -f <jobid> | grep -i comment; is the request possible on this cluster?";;
        4) want="processed: 4"; hint="one of the input files does not exist: compare the names with ls \$DATA_DIR/samples";;
        5) want=""; hint="the container failed to start: read the first error in the log";;
        6) want=""; hint="the variable is not defined inside the job: jobs do not inherit your interactive shell's variables";;
    esac
    if [ ! -s "$f" ]; then
        edu_fail "broken job $n: not fixed yet (no $f)" "$hint"
    elif [ -n "$want" ] && ! grep -qx "$want" "$f"; then
        edu_fail "broken job $n: result is '$(cat "$f")', expected '$want'" "$hint"
    else
        edu_pass "broken job $n fixed. Compare your diagnosis with solutions/README.md"
    fi
done
edu_summary
