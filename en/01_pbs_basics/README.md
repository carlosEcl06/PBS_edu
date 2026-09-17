# 01 — PBS basics: submit, check, cancel

PBS (this cluster runs OpenPBS) schedules your job onto a compute node and runs it
there, instead of on whatever node you happen to be logged into. A PBS job is just a
shell script with some special `#PBS` comment lines at the top telling the scheduler
what resources you need.

## The three commands you'll use constantly

```bash
qsub my_job.pbs          # submit a job, prints its job ID (e.g. "3120.pne2")
qstat -u $(whoami)       # list your jobs and their state
qdel 3120.pne2            # cancel a job (running or queued)
```

Job states you'll see in `qstat`: `Q` (queued, waiting for resources), `R` (running),
and once it finishes the job simply disappears from the default `qstat` listing (use
`qstat -x 3120.pne2` to see a finished job's accounting info, or `qstat -xf` for the
full detail including its exit status).

## Anatomy of a minimal job script

```bash
#!/bin/bash
#PBS -N my_first_job          # a name for the job (shows up in qstat)
#PBS -q workq                 # the queue -- workq is the standard one here
#PBS -l select=1:ncpus=1:mem=1gb   # 1 node, 1 CPU, 1GB RAM
#PBS -l walltime=00:05:00     # kill the job if it's still running after 5 minutes
#PBS -o my_job.out            # where stdout goes (written when the job finishes)
#PBS -e my_job.err            # where stderr goes

echo "Hello from $(hostname), running as job $PBS_JOBID"
date
sleep 10
echo "Done."
```

Save that as `my_job.pbs` and submit it with `qsub my_job.pbs`. A few things worth
knowing before you do:

- **`walltime` is a hard cap.** If your job is still running when it's reached, PBS
  kills it. Always leave real headroom above what you expect the job to actually take
  — a killed job partway through can leave partial/corrupt output, which is a much
  worse debugging experience than a job that just finishes a bit early.
- **`-o`/`-e` are usually only written once the job finishes**, not streamed live, on
  this particular PBS setup. Don't be alarmed if the output file doesn't exist yet
  while `qstat` shows the job as `R` — that's normal here, not a sign anything's wrong.
- **The script runs on whichever compute node PBS assigns**, starting from wherever
  `qsub` was run from as its working directory context (paths in your script should
  generally be absolute, or explicitly `cd` first, to avoid ambiguity).
- **`#PBS` directive lines don't support trailing inline comments** on this setup —
  `#PBS -l ncpus=2  # my comment` will fail with a `directive error`, because the
  parser treats everything after `-l` as directive text, not shell-style
  comment-stripped. Put explanatory comments on their own line above the directive
  instead. (Found this the first time by actually submitting the exercise scripts
  below to check they work — worth doing yourself whenever you write a new script,
  not just trusting it looks right.)

## Try it

Run the working example first, exactly as-is, to see the full submit → wait → check
cycle:

```bash
qsub example_hello_world.pbs
qstat -u $(whoami)
# wait a few seconds, then:
cat example_hello_world.out
```

Then open `exercise_01_fill_in_blanks.pbs`, fill in the blanks (marked `___`), and
submit your own version. If you get stuck, `exercise_01_ANSWER.pbs` has a worked
solution — but try it yourself first, that's the point.
