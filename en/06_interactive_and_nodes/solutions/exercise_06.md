# Solutions for exercise 6

## 6a: pinning
Run `./check_free_nodes.sh 1 1`, pick a node from the list (say `node07`), and edit the line to

```
#PBS -l select=1:ncpus=1:mem=1gb:host=node07
```

Submit it. If the job stays queued, that node is full right now: PBS will wait for *that* node
even when others are idle. That is the price of pinning.

## 6b: interactive session
```bash
cd 06_interactive_and_nodes
qsub -I -l select=1:ncpus=2:mem=4gb -l walltime=00:30:00
# ... wait for the prompt, you are now on a compute node ...
cd "$PBS_O_WORKDIR"
source ../lib/edu.sh
mkdir -p "$WORKDIR/06_interactive_and_nodes"
edu_exec seqkit stats -T "$DATA_DIR/real/test_1.fastq.gz" "$DATA_DIR/real/test_2.fastq.gz" \
    > "$WORKDIR/06_interactive_and_nodes/interactive_stats.tsv"
{ echo "job_id: $PBS_JOBID"; echo "host: $(hostname)"; echo "ncpus: $NCPUS"; } \
    > "$WORKDIR/06_interactive_and_nodes/interactive_proof.txt"
exit        # IMPORTANT: leaving the shell ends the job and frees the CPUs
```
