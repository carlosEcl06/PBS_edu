# 01 · PBS basics

**You'll learn:** write, submit, monitor and debug a job.
**Time:** 45 minutes.
**Before you start:** you finished [00 · Getting started](../00_getting_started/README.md) (`check_env.sh` passes).
**Why it matters in bioinformatics:** every later step, whether trimming, aligning or calling variants, is "a script plus a resource request". Get this right and the rest is just changing the command inside.

> **Convention used in the whole course:** submit jobs *from the section directory* (`cd 01_pbs_basics; qsub something.pbs`). The scripts use `source ../lib/edu.sh` and find it through the directory you submitted from.

---

## 1. Anatomy of a job script

A job script is an ordinary shell script with special comment lines at the top that start with `#PBS`. `qsub` reads them as options; the shell ignores them as comments.

```bash
#!/bin/bash
#PBS -N count_reads
#PBS -l select=1:ncpus=1:mem=1gb
#PBS -l walltime=00:05:00
#PBS -j oe

cd "$PBS_O_WORKDIR" || exit 1
echo "hello from $(hostname)"
```

| Line | Meaning |
|---|---|
| `-N count_reads` | job **name**, shown in `qstat` and used for log file names. Start with a letter, no spaces. |
| `-l select=1:ncpus=1:mem=1gb` | the **resource request**: 1 *chunk* (a bundle of resources placed on one node) with 1 CPU core and 1 GB memory. |
| `-l walltime=00:05:00` | maximum run time, `HH:MM:SS`. **PBS kills the job when it expires**, whatever it is doing. |
| `-j oe` | **j**oin stderr (**e**) into stdout (**o**): one log file instead of two. |
| `cd "$PBS_O_WORKDIR"` | jobs **start in your home directory**, not where you ran `qsub`. This line goes back. Forgetting it is the classic first mistake. |

Optional but useful: `-o <file>` / `-e <file>` name the log files (default: `<name>.o<jobid>` and `<name>.e<jobid>`, created in the directory you submitted from).

**Comments on `#PBS` lines:** put them on their own line, never after the option (`#PBS -N x   # my job`). Some PBS versions read the rest of the line as part of the option and fail in confusing ways. All scripts here follow that rule.

**Choosing numbers:** don't guess wildly. Ask for slightly more than the job needs: too little and it is killed; too much and it waits longer in the queue and wastes shared resources. Section 03 shows how to measure.

## 2. Submit and watch

```bash
qsub example_hello_world.pbs      # prints a job id, e.g. 12345.myserver
qstat -u $USER                    # your jobs. Look at the S (state) column
qstat -f 12345                    # everything about one job
qdel 12345                        # cancel it
qstat -x -u $USER                 # include FINISHED jobs (if the site keeps history)
qstat -xf 12345                   # full details of a finished job: Exit_status, resources_used
```

States: **Q** queued · **R** running · **H** held · **E** exiting · **F** finished (only visible with `-x`).

When the job ends, PBS writes `hello.o12345` in your submit directory. Read it with `cat`. **The log appears only when the job ends**, not while it runs, so a running job's `.o` file may not exist yet. That is normal. For long jobs, write progress to your own log file on the shared filesystem.

## 3. Try it

```bash
cd 01_pbs_basics
qsub example_hello_world.pbs
qstat -u $USER            # repeat until the job is gone
cat hello.o*              # note "Directory when the job started"
qsub example_count_reads.pbs
```

`example_hello_world.pbs` prints where the job started (your home!) and where it went after `cd`. `example_count_reads.pbs` is your first bioinformatics job: it counts reads and bases in the two real FASTQ files using `zcat` and `awk`. Read it, then look at its result in `$WORKDIR/01_pbs_basics/fastq_counts.tsv`.

**Questions to answer from the logs** (no need to write them anywhere):
1. Which node did your job run on? Is it the login node?
2. What did `qstat -xf <jobid>` say for `Exit_status`, `resources_used.walltime` and `resources_used.mem`?
3. How many CPUs does the job think it has? (`NCPUS`)

## 4. Exercises

Each exercise has a **checker** that looks at the real output of your job and tells you what is wrong. Solutions are in `solutions/`: peek only after trying.

### 1a · Fill in the blanks (10 min)
Edit `exercise_01a_fill_in_blanks.pbs`, replacing each `___`. Submit it, wait for it to finish, then `./check_01a.sh`.

### 1b · Fix the broken job (15 min)
`exercise_01b_fix_the_job.pbs` has three separate bugs that show up one after another: one at submission, one when the job starts, one while it runs. Submit, read what went wrong, fix one bug, repeat. Then `./check_01b.sh`.

### 1c · Write a job from scratch (15 min)
Write `my_reference_stats.pbs` yourself. Requirements:

- 1 CPU, 1 GB, 5 minutes, a name of your choice, log files merged.
- Read `$DATA_DIR/ref/genome.fasta` (the reference genome) and write `$WORKDIR/01_pbs_basics/reference_stats.txt` with exactly these five lines:

  ```
  sequences: <number of FASTA records>
  length: <total number of bases>
  gc_percent: <percentage of G and C, 2 decimals>
  job_id: <$PBS_JOBID>
  host: <output of hostname, from inside the job>
  ```
- Hint: header lines start with `>`; `awk` can count characters; `gsub(/[GC]/, "")` returns how many it replaced. `printf "%.2f"` prints two decimals.

Then `./check_01c.sh`. GC content is a real metric: it varies by organism and helps spot contamination.

## Check yourself

You are done when you can answer "yes" to all of these:
- [ ] I can explain why my job needs `cd "$PBS_O_WORKDIR"`.
- [ ] I know what happens when a job exceeds its walltime, and where to see it (`Exit_status`).
- [ ] I can find the log of a finished job and the node it ran on.
- [ ] `check_01a.sh`, `check_01b.sh`, `check_01c.sh` pass.

## If it goes wrong

| What you see | What to do |
|---|---|
| `qsub: Unknown resource ...` / `Illegal attribute or resource value` | A `#PBS` line has a typo (`ncpu` instead of `ncpus`, missing `gb`, blank left as `___`). |
| Job stays `Q` for a long time | The cluster is busy or you asked for more than any node has. `qstat -f <id> \| grep -i comment`. |
| No `.o` file yet, job is `R` | Expected: it appears at the end. |
| Log says `No such file or directory` for `../lib/edu.sh` | You forgot `cd "$PBS_O_WORKDIR"`, or you submitted from a different directory than the section directory. |
| Log stops abruptly, `Exit_status = 271` | Killed by PBS, most likely walltime exceeded. |
| Job ended but result files are missing | Read the log to the end; the script probably failed halfway. |

Next: [02 · Containers](../02_containers/README.md)
