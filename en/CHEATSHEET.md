# PBS cheat sheet

Values in `<angle brackets>` are yours to fill in. Commands are for OpenPBS / PBS Professional; Torque/SLURM differ.

## Submit, watch, cancel

| Task | Command |
|---|---|
| Submit a script | `qsub script.pbs` (prints the job id) |
| Submit with different resources | `qsub -l select=1:ncpus=8:mem=16gb -l walltime=02:00:00 script.pbs` (command line beats `#PBS` lines in the script) |
| Pass a variable into the job | `qsub -v SAMPLE=sample_03 script.pbs` |
| Submit to a specific queue | `qsub -q <queue> script.pbs` |
| My jobs | `qstat -u $USER` |
| One job in detail | `qstat -f <jobid>` |
| Finished jobs (history) | `qstat -x -u $USER` · `qstat -xf <jobid>` |
| Why is it still `Q`? | `qstat -f <jobid> \| grep -i comment` |
| Cancel | `qdel <jobid>` (arrays: `qdel '<jobid>[]'`) |
| Interactive shell on a compute node | `qsub -I -l select=1:ncpus=2:mem=4gb -l walltime=01:00:00` |
| Queues and their limits | `qstat -Q` · `qstat -Qf <queue>` |
| Nodes and how busy they are | `pbsnodes -aSj` (summary) · `pbsnodes -a` (everything) |

## Anatomy of a job script

```bash
#!/bin/bash
# name of the job
#PBS -N my_job
# one chunk: 4 cores and 8 GB of memory
#PBS -l select=1:ncpus=4:mem=8gb
# hard limit of 2 hours
#PBS -l walltime=02:00:00
# merge stderr into stdout: one log file
#PBS -j oe

# jobs start in $HOME: go back to where you ran qsub
cd "$PBS_O_WORKDIR"
# (this course) load site settings and helpers
source ../lib/edu.sh
my_tool --threads "$NCPUS" ...
```

> **Note:** never put a `# comment` at the end of a `#PBS` line. Some PBS versions treat the rest of the line as part of the option and reject or misread it. Put comments on their own line, as above. For a job array add `#PBS -J 1-6`.

## Variables available inside a job

| Variable | Meaning |
|---|---|
| `$PBS_O_WORKDIR` | directory you ran `qsub` from |
| `$PBS_JOBID` | job id (`12345.server`, arrays: `12345[3].server`) |
| `$PBS_ARRAY_INDEX` | index of this array sub-job |
| `$NCPUS` | CPUs allocated to the job (use this for `--threads`) |
| `$TMPDIR` | per-job scratch directory on the node (if your site provides one) |

## Files PBS writes

Default log names, in the directory you submitted from: `<jobname>.o<id>` (stdout) and `<jobname>.e<id>` (stderr). They appear **when the job ends**, not while it runs. Tail a running job's output from inside the script by writing your own log to the shared filesystem.

## Arrays and dependencies

```bash
qsub -J 1-6 array.pbs                       # 6 sub-jobs
qsub -J 2-5:3 array.pbs                     # indices 2 and 5 only (start-end:step)
jid=$(qsub step1.pbs)                       # capture the id
qsub -W depend=afterok:$jid step2.pbs       # run only if step1 exited 0
qsub -W depend=afterany:$jid cleanup.pbs    # run whatever happened to step1
```

## Reading exit statuses (`qstat -xf <id>` → `Exit_status`)

| Value | Usually means |
|---|---|
| `0` | success |
| `1`–`255` | your script/tool returned that error code |
| `256+N` (e.g. `271`) | PBS killed the job with signal N (271 = SIGTERM, 265 = SIGKILL): typically walltime or memory exceeded |

## Containers (Apptainer/Singularity)

```bash
apptainer pull tool.sif docker://quay.io/biocontainers/<tool>:<tag>
apptainer exec --bind /data,/scratch tool.sif <command> <args>
```

## Golden rules

1. Never run analyses on the login node. Submit a job (or use `qsub -I`).
2. Start small: test a script on one sample with a short walltime before scaling up.
3. Ask for what you measured, plus a margin, not for "as much as possible".
4. Pin container versions. Validate inputs at the start of a job.
