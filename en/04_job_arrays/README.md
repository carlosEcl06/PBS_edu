# 04 · Job arrays: one job per sample

**You'll learn:** run the same analysis on many samples with a single `qsub`, and re-run only the ones that failed.
**Time:** 45 minutes.
**Why it matters in bioinformatics:** nearly every project is "the same step on N samples" (QC, trimming, alignment, per-sample variant calling). Doing them one by one is slow; running them in a `for` loop inside one job is slow *and* fragile; typing 100 `qsub` commands is error-prone. A **job array** is the tool made for this.

---

## 1. Three ways to process 6 samples

| Approach | Total time | If sample 4 crashes… | Scheduler view |
|---|---|---|---|
| `for` loop in one job | sum of all samples | later samples never run | one big request |
| 6 hand-typed `qsub`s | ≈ slowest sample | only sample 4 fails | 6 requests, easy to mistype |
| **Job array** `-J 1-6` | ≈ slowest sample | only sample 4 fails | one submission, 6 independent sub-jobs |

Sub-jobs are independent and run in parallel as soon as resources are free, exactly like separate jobs, but you submit and manage them together.

## 2. How arrays work

```bash
#PBS -J 1-6
```

`qsub` creates 6 **sub-jobs** that all run the *same script*. Each gets its own `PBS_ARRAY_INDEX` (1, 2, … 6). Your script turns the index into "which sample am I?" A *sample sheet* is the simplest way:

```
sample_01   /path/sample_01_R1.fastq.gz   /path/sample_01_R2.fastq.gz     <- line 1
sample_02   ...                                                            <- line 2
```

```bash
line="$(sed -n "${PBS_ARRAY_INDEX}p" samples.tsv)"      # take line number = my index
IFS=$'\t' read -r id r1 r2 <<< "$line"                  # split it into variables
```

Look at [`example_array_qc.pbs`](example_array_qc.pbs), which runs **fastp** (the standard read trimmer and QC tool) on each sample.

### Rules of thumb
- **One sub-job = one sample = its own output files.** Never let two sub-jobs write the same file.
- **The resource request is per sub-job.** `ncpus=2:mem=2gb` with 6 sub-jobs can occupy 12 CPUs at once.
- **Match the range to the data:** `-J 1-6` for 6 samples. Use `qsub -J 1-$(wc -l < samples.tsv) script.pbs` to compute it. A command-line `-J` overrides the `#PBS -J` line.
- **Ranges accept a step:** `-J 2-5:3` means indices 2 and 5 (start-end:step).
- Torque and SLURM spell this differently (`-t`, `--array`); check your scheduler's manual.
- Some sites limit how many sub-jobs may run at once; ask your admin if yours seem to run only a few at a time.

## 3. Watching an array

```bash
qsub example_array_qc.pbs            # prints an id like 12345[].myserver
qstat -u $USER                       # the array shows as one line, state B ("begun")
qstat -t -u $USER                    # -t expands it: one line per sub-job
qstat -xf '12345[3]'                 # details of sub-job 3 (quote the brackets!)
qdel '12345[]'                       # cancel the whole array
qdel '12345[3]'                      # cancel only sub-job 3
```

Logs: every sub-job writes its own file, named like `qc_array.o12345.3`.

## 4. Try it

```bash
cd 04_job_arrays
qsub example_array_qc.pbs
qstat -t -u $USER
ls results/fastp/
```
Open one `.fastp.json` and find `before_filtering` vs `after_filtering` read counts. How many reads were removed per sample? (The reads are simulated with few errors, so not many.)

## 5. Exercises

### 4a · Fill in the blanks (15 min)
`exercise_04a_fill_in_blanks.pbs` runs `seqkit stats` for each sample. Fill in the blanks, submit, wait, then `./check_04a.sh`.

### 4b · Re-run only what failed (15 min)
In real projects a few sub-jobs always fail (a timeout, a bad file, a node hiccup). You should not recompute everything.

```bash
./prepare_04b.sh        # simulates failure: deletes the outputs of samples 2 and 5
```
Now re-run **only** sub-jobs 2 and 5 with a single `qsub`, and then `./check_04b.sh`. It verifies that samples 2 and 5 were recomputed and the other four were **not touched**. (Hint: look at the *Ranges accept a step* rule above.)

Bonus: make your script *idempotent*, so it skips a sample whose output already exists. That way you can always resubmit the whole array safely. See `solutions/exercise_04b.md` for the pattern and its one trap.

## Check yourself
- [ ] I can explain what `PBS_ARRAY_INDEX` is and how a script turns it into a sample name.
- [ ] I can list, inspect and cancel a single sub-job.
- [ ] I can re-run a subset of indices.
- [ ] `check_04a.sh` and `check_04b.sh` pass.

## If it goes wrong

| What you see | What to do |
|---|---|
| `qsub: ... -J ... invalid` | Range must be `start-end` or `start-end:step`, and needs a PBS version with array support. |
| Some sub-jobs stay `Q` while others run | Normal: the cluster starts them as resources free up. |
| Every sub-job fails identically | Test the script on one index first: `qsub -J 1-1 script.pbs`. |
| `no sample on line N` | Array range larger than the sample sheet. |
| Sub-job outputs overwrite each other | The output file name does not contain the sample id. |
| `qstat -xf 12345[3]` finds nothing | Quote it: `'12345[3]'`, and your site may not keep history. |

Next: [05 · Pipelines and dependencies](../05_pipelines_dependencies/README.md)
