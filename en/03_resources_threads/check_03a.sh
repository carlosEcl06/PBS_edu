#!/bin/bash
# Checks exercise 3a and prints your scaling table.
#
# Before running: pick how many CPUs you would request for this job, and write it down:
#   echo 4 > my_choice.txt        (in this directory)
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

T="$WORKDIR/03_resources_threads/timings.tsv"
echo "Checking exercise 3a..."
edu_expect_file "$T" "run ./scaling_experiment.sh and wait for the jobs to finish"
if [ -s "$T" ]; then
    echo
    echo "  threads  seconds  speedup  efficiency"
    awk -F'\t' 'NR > 1 { t[$1] = $2 } END { base = t[1]; for (n in t) if (n + 0 > 0) { sp = (base && t[n] > 0 ? base / t[n] : 0); printf "  %7d  %7d  %6.2fx  %8.0f%%\n", n, t[n], sp, (base ? 100 * sp / n : 0) } }' "$T" | sort -n
    echo
    distinct="$(awk -F'\t' 'NR > 1 { print $1 }' "$T" | sort -un | wc -l)"
    if [ "$distinct" -ge 3 ]; then edu_pass "measured $distinct different CPU counts"; else edu_fail "only $distinct CPU count(s) measured" "run ./scaling_experiment.sh with at least 3 different values"; fi
    if [ -s my_choice.txt ]; then
        choice="$(tr -d '[:space:]' < my_choice.txt)"
        eff="$(awk -F'\t' -v c="$choice" 'NR > 1 { t[$1] = $2 } END { if (c in t && t[c] > 0 && (1 in t)) printf "%.0f", 100 * (t[1] / t[c]) / c }' "$T")"
        if [ -z "$eff" ]; then
            edu_fail "your choice ($choice) was not measured, or 1 CPU was not measured" "choose one of the thread counts in the table, and include 1 in the experiment"
        elif [ "$eff" -lt 50 ]; then
            edu_warn "with $choice CPUs, efficiency is ${eff}%: over half of the CPUs you would reserve sit idle. Is a smaller request nearly as fast?"
            edu_pass "choice recorded ($choice CPUs)"
        else
            edu_pass "choice recorded: $choice CPUs at ${eff}% efficiency"
        fi
    else
        edu_fail "no my_choice.txt" "look at the table, then: echo <cpus> > my_choice.txt"
    fi
fi
edu_summary
