#!/bin/bash
# Submit the same alignment job with different numbers of CPUs, to measure how
# well it scales. Run on the login node (it only submits jobs):
#
#   ./scaling_experiment.sh            # 1, 2, 4 and 8 CPUs
#   ./scaling_experiment.sh 1 3 6      # your own list
#
# Options given to qsub on the command line override the #PBS lines in the script.
# Results accumulate in $WORKDIR/03_resources_threads/timings.tsv

cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

counts=("$@")
[ ${#counts[@]} -eq 0 ] && counts=(1 2 4 8)

for n in "${counts[@]}"; do
    jid="$(edu_qsub -N "align_${n}cpu" -l "select=1:ncpus=$n:mem=4gb" example_align_threads.pbs)" || exit 1
    echo "submitted $n CPU(s): $jid"
done

echo
echo "Watch with:   qstat -u \$USER"
echo "When all are finished:   column -t $WORKDIR/03_resources_threads/timings.tsv"
echo "(a job asking for more CPUs than any node has would wait forever: qdel it)"
