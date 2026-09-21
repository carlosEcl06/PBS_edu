#!/bin/bash
# Checks exercise 6a.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

RES="$WORKDIR/06_interactive_and_nodes/pinned.txt"
echo "Checking exercise 6a..."
wanted="$(sed -n 's/^#PBS -l select=.*host=\([^:# ]*\).*/\1/p' exercise_06a_pin_to_node.pbs | head -1)"
if [ -z "$wanted" ] || [ "$wanted" = "___" ]; then
    edu_fail "no node name in exercise_06a_pin_to_node.pbs" "replace ___ in the #PBS select line by a node name from ./check_free_nodes.sh"
else
    edu_expect_file "$RES" "submit the job and wait for it to finish; if it stays Q the node may be full or the name wrong: qstat -f <id> | grep comment"
    if [ -s "$RES" ]; then
        actual="$(awk -F': ' '$1 == "host" { print $2 }' "$RES")"
        if [ "${actual%%.*}" = "${wanted%%.*}" ]; then
            edu_pass "asked for $wanted, ran on $actual"
        else
            edu_fail "asked for $wanted but the last run happened on $actual" "resubmit after fixing the script (old results are overwritten only by a new run)"
        fi
    fi
fi
edu_summary
