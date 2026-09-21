#!/bin/bash
# Check that everything the course needs is in place. Run it on the login node:
#
#   ./check_env.sh             full check, including a real 10-second test job
#   ./check_env.sh --no-job    skip the test job (checks files and commands only)
#
# It never changes anything except submitting smoke_test.pbs.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE" || exit 1
source ../lib/edu.sh || exit 1

RUN_JOB=1
[ "${1:-}" = "--no-job" ] && RUN_JOB=0

echo "== 1. PBS commands"
for c in qsub qstat qdel pbsnodes; do
    if command -v "$c" >/dev/null 2>&1; then edu_pass "$c"; else edu_fail "$c not found" "are you on the login node? try 'module avail pbs'"; fi
done

echo "== 2. Container runtime"
if command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
    edu_pass "$CONTAINER_RUNTIME on this node"
else
    edu_warn "$CONTAINER_RUNTIME not in PATH on this node (fine if only compute nodes have it; the test job checks that)"
fi

echo "== 3. Data (fetch_data.sh)"
if (cd "$DATA_DIR" 2>/dev/null && sha256sum -c --quiet "$HERE/data.sha256" >/dev/null 2>&1); then
    edu_pass "reference + real reads present and intact"
else
    edu_fail "data missing or corrupt in $DATA_DIR" "run ./fetch_data.sh"
fi

echo "== 4. Container images (pull_containers.sh)"
for tool in "${TOOLS[@]}"; do
    if [ -s "$(edu_sif "$tool")" ]; then edu_pass "$tool.sif"; else edu_fail "$tool.sif missing" "run ./pull_containers.sh"; fi
done

echo "== 5. Simulated samples (make_samples.pbs)"
sheet="$DATA_DIR/samples/samples.tsv"
if [ -s "$sheet" ]; then
    n="$(wc -l < "$sheet")"
    missing="$(awk -F'\t' '{print $2; print $3}' "$sheet" | while read -r f; do [ -s "$f" ] || echo "$f"; done | wc -l)"
    edu_expect_eq "samples in samples.tsv" "$N_SAMPLES" "$n" "re-run: qsub make_samples.pbs"
    edu_expect_eq "missing sample files" "0" "$missing" "re-run: qsub make_samples.pbs"
else
    edu_fail "no samples.tsv" "submit: qsub make_samples.pbs   (then wait for it to finish)"
fi

if [ "$RUN_JOB" -eq 1 ] && command -v qsub >/dev/null 2>&1 && [ "$EDU_FAILS" -eq 0 ]; then
    echo "== 6. Test job on a compute node"
    jid="$(edu_qsub smoke_test.pbs)" || { edu_fail "qsub failed" "if it says a queue is required, set EDU_QUEUE in site.conf"; jid=""; }
    if [ -n "$jid" ]; then
        num="${jid%%.*}"
        log="smoke_test.o$num"
        echo "  submitted $jid, waiting for $log (up to 3 minutes)..."
        for _ in $(seq 1 90); do [ -f "$log" ] && break; sleep 2; done
        if [ ! -f "$log" ]; then
            edu_fail "job did not finish in 3 minutes" "check 'qstat -u \$USER'; a busy cluster may just need longer"
        elif grep -q 'SMOKE OK' "$log"; then
            edu_pass "test job ran on $(awk '/^== host/ {print $3}' "$log") and could use containers + your data"
            rm -f "$log"
        else
            edu_fail "test job failed; its log ($log) says:" ""
            sed 's/^/        /' "$log"
        fi
    fi
elif [ "$RUN_JOB" -eq 1 ]; then
    echo "== 6. Test job skipped (fix the failures above first)"
fi

edu_summary
