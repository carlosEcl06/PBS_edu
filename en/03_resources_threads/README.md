# 03 · Resources and threads: asking for the right amount

**You'll learn:** what CPUs, memory and walltime really mean, how to measure a job, and how to choose the numbers.
**Time:** 45–60 minutes (the experiment jobs run in the background while you read).
**Why it matters in bioinformatics:** aligners, assemblers and variant callers are the heavy tools. Request too little and PBS kills your job halfway; request too much and you wait longer in the queue and block colleagues. Almost every real cluster problem is "wrong resource request".

---

## 1. The three resources

| Resource | Request | What happens if you exceed it |
|---|---|---|
| **CPUs** `ncpus=N` | cores reserved for you | Nothing stops a program using more threads than you asked for, but it competes with other users' jobs on the same node (and some sites throttle it). Be a good citizen: threads ≤ ncpus. |
| **Memory** `mem=Xgb` | RAM reserved for you | The job is usually **killed** the moment it goes over (on sites that enforce it). Log often ends with `Killed`. |
| **Walltime** `walltime=HH:MM:SS` | wall-clock time | The job is **killed** when the time runs out, mid-computation, all unsaved work lost. |

The scheduler treats your request as a reservation: the bigger it is, the fewer nodes can host it, and the longer it waits. Short, small jobs often slip into gaps ("backfilling") and start almost immediately.

## 2. Using the CPUs you asked for

Requesting `ncpus=4` does **not** make your program faster. The program must be told to use 4 threads:

```bash
minimap2 -t "$NCPUS" ...        # aligner
samtools sort -@ 3 ...          # -@ counts EXTRA threads
fastp --thread "$NCPUS" ...
```

PBS sets `$NCPUS` to what you were given. Use it instead of a hard-coded number, so changing the request changes the threads. **Don't use `nproc`:** on many clusters it reports all cores of the node, not yours.

Two subtleties you will meet in `example_align_threads.pbs`:
- In a pipe (`minimap2 ... | samtools sort ...`) both programs run *at once*, each with its own threads.
- **More threads is not proportionally faster.** Input reading, index building and I/O run on one thread; small inputs finish before extra threads pay off. The relationship is *speedup* = time(1 CPU) / time(N CPUs); *efficiency* = speedup / N. 100% is perfect; 50% means half the reserved CPUs are wasted.

## 3. Measuring what a job used

After a job finishes (if your site keeps history):

```bash
qstat -xf <jobid> | grep -E 'Exit_status|resources_used|Resource_List'
```

| Field | Read it as |
|---|---|
| `Exit_status` | `0` fine; `1`–`255` your program failed; `256+N` PBS killed it with signal N (271 = SIGTERM, 265 = SIGKILL): walltime or memory |
| `resources_used.walltime` | how long it really took → set your request to about 1.5–2× this |
| `resources_used.mem` | peak memory → request about 1.2–1.5× this |
| `resources_used.cput` | CPU-seconds actually used. `cput / (walltime × ncpus)` is your CPU efficiency |
| `resources_used.ncpus`, `cpupercent` | CPUs granted and how busy they were |

Workflow: run **once with generous limits on a small sample**, read these numbers, then set the real request for the full dataset. Never guess "24 hours and 64 GB, just in case".

If `qstat -x` shows nothing (no history), measure inside the script: `date` before and after, or `/usr/bin/time -v <command>` (reports "Maximum resident set size").

## 4. Try it

```bash
cd 03_resources_threads
qsub example_align_threads.pbs     # aligns all 6 samples with 2 CPUs
```

Read the script: it loops over the sample sheet, aligns each sample to the reference genome, sorts the reads into a BAM file and appends the time taken to `results/timings.tsv`.

## 5. Exercises

### 3a · The scaling experiment (20 min)
```bash
./scaling_experiment.sh            # submits the same job with 1, 2, 4, 8 CPUs
qstat -u $USER                     # wait until all finish
```
Then decide how many CPUs you would request for this job and record it:
```bash
echo 4 > my_choice.txt
./check_03a.sh                     # prints your speedup/efficiency table
```
Discussion (no right answer, but be ready to justify): where does efficiency drop below 70%? Would you request 8 CPUs if the cluster is busy and each CPU costs you wait time? If your cluster's nodes have fewer than 8 CPUs, use `./scaling_experiment.sh 1 2 4`.

### 3b · Right-size a job (15 min)
`exercise_03b_right_size.pbs` is a deliberately undersized job (10 s walltime, blank memory). Use your 3a numbers to fix it, submit, then `./check_03b.sh`. After it finishes, look at `qstat -xf <jobid>`: how close was your walltime request to the real usage?

*Optional:* deliberately request `walltime=00:00:05` for `example_align_threads.pbs` and observe: the log stops mid-way, `Exit_status = 271`.

## Check yourself
- [ ] I use `$NCPUS` rather than a fixed number of threads.
- [ ] I can say what `Exit_status = 271` means and where to see it.
- [ ] I know why "more CPUs" is not always "faster", and can compute efficiency.
- [ ] `check_03a.sh` and `check_03b.sh` pass.

## If it goes wrong

| What you see | What to do |
|---|---|
| Scaling job with 8 CPUs never starts | No node has 8 free CPUs (or at all). `qstat -f <id> \| grep comment`, `qdel` it, use a lower count. |
| All timings are almost the same | Expected for small inputs. That is the lesson: extra CPUs did not help. |
| `samtools sort: ... out of memory` / `Killed` | Raise `mem=`, or lower samtools' `-m` (per-thread buffer). |
| Job killed, log ends abruptly | `qstat -xf`: `Exit_status` ≥ 256 → walltime or memory limit. |
| `timings.tsv` has old rows | It appends forever. `rm results/timings.tsv` to start fresh. |

Next: [04 · Job arrays](../04_job_arrays/README.md)
