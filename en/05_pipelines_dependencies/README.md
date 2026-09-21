# 05 · Pipelines: chaining jobs with dependencies

**You'll learn:** run steps in order (QC → align → summarise) so each starts only when the previous one succeeded, and what happens when one fails.
**Time:** 45–60 minutes.
**Why it matters in bioinformatics:** an analysis is never one command. It is trimming, then alignment, then sorting, then variant calling, then a report, each needing the previous output. You do not want to sit watching `qstat` to launch step 2 by hand at 3 am.

---

## 1. Dependencies

`qsub` prints the new job's id. You can hand that id to the next `qsub`:

```bash
J1=$(qsub step1.pbs)                          # e.g. 12345.myserver
J2=$(qsub -W depend=afterok:$J1 step2.pbs)    # runs only if J1 exited with status 0
J3=$(qsub -W depend=afterok:$J2 step3.pbs)
```

The dependent job waits in the queue (state `H`, held) until its condition is met.

| Condition | Starts the job when… |
|---|---|
| `afterok:<id>` | `<id>` finished with exit status 0 (**the normal choice**) |
| `afternotok:<id>` | `<id>` failed (for cleanup or notification jobs) |
| `afterany:<id>` | `<id>` finished, whatever happened (for cleanup that must always run) |
| `after:<id>` | `<id>` has *started* |

Several ids are joined with colons: `afterok:$J1:$J2`. For an **array** id (`12345[].server`), `afterok` waits for *all* sub-jobs.

**A script that ends with a failing command must return a non-zero exit status**, otherwise PBS thinks it succeeded and starts the next step on broken data. That is why the step scripts here end each critical command with `|| exit 1` and use `set -o pipefail` for pipes.

## 2. The pipeline in this section

```
 step1_qc.pbs  (array, fastp trim + QC)      one sub-job per sample
        │  afterok  (waits for the whole array)
 step2_align.pbs (array, minimap2 + samtools sort/index)
        │  afterok
 step3_summary.pbs (one job: samtools flagstat of all samples -> summary.tsv)
```

Each step stamps its start and end times in `$WORKDIR/05_pipelines_dependencies/timeline.tsv` (via `edu_stamp`, in `lib/edu.sh`). This makes ordering *provable*: the checkers use it to verify that a later step really did not start before the earlier one ended.

`example_two_step_driver.sh` submits steps 1 and 2. A **driver** is a plain shell script run on the login node: it computes nothing, only submits jobs, so it is fast and safe there.

## 3. Try it

```bash
cd 05_pipelines_dependencies
./example_two_step_driver.sh
qstat -t -u $USER          # step 2's sub-jobs are held (H) while step 1 runs
```

Read the two driver lines that matter, then read `step2_align.pbs`: it refuses to run if step 1's output is missing.

### Experiment: a failure in the middle
```bash
EDU_INJECT_FAILURE=step2 ./example_two_step_driver.sh
```
Sub-job 3 of step 2 exits with an error on purpose. Watch `qstat`. What happens to the other five? Now imagine step 3 had been submitted with `afterok`: it can never be satisfied. Depending on the PBS version it stays held forever or is removed; **check with `qstat` and `qdel` anything that is stuck**. With `afterany` it would run on incomplete data, which is usually *worse*. (Nothing to submit here: just reason about which one you want for a summary step.)

Run the good pipeline again afterwards to clean up: `./example_two_step_driver.sh`.

## 4. Exercises

### 5a · Complete the driver (15 min)
`exercise_05a_complete_the_driver.sh` is missing three pieces (the first script name, the dependency type, the variable holding step 2's id). Fill them in, run it, wait for everything to finish, then `./check_05a.sh`. The checker verifies the summary numbers against the BAM files **and** that step 2 started after step 1 ended, and step 3 after step 2.

### 5b · Write your own final step (20 min)
Write `my_step4.pbs` (1 CPU, 1 GB, 5 min) that reads `summary.tsv` and writes `$WORKDIR/05_pipelines_dependencies/report.txt` with two lines:

```
samples: <number of samples>
well_mapped: <number of samples with mapped_pct >= 95>
```

Requirements:
- inside the script, record its timing so it can be verified:
  ```bash
  EDU_TIMELINE="$WORKDIR/05_pipelines_dependencies/timeline.tsv"
  edu_stamp step4 start      # first thing
  edu_stamp step4 end        # last thing
  ```
- add it to your driver as step 4, depending on step 3 (`afterok`).

Run the pipeline and then `./check_05b.sh`.

## Check yourself
- [ ] I can capture a job id and use it in `-W depend=...`.
- [ ] I can explain the difference between `afterok` and `afterany`, and when I want each.
- [ ] I know why a script must exit non-zero when something fails.
- [ ] `check_05a.sh` and `check_05b.sh` pass.

## If it goes wrong

| What you see | What to do |
|---|---|
| A step is held (`H`) forever | Its dependency failed or is still running. `qstat -f <id> \| grep -i depend`, look at the previous step's logs, `qdel` it. |
| `qsub: illegal ... depend` | Wrong syntax: `-W depend=afterok:<id>` (no spaces). Quote arrays if your shell complains: `"$J1"`. |
| Step 2 says "step 1 output missing" | Step 1 failed for that sample. Read step 1's log for that sub-job. |
| Checker: "started before" | The dependency was not applied to that step. |
| Checker: "no timeline entries" | The steps write it themselves; the pipeline has not run, or `$WORKDIR` changed since. |
| Pipeline succeeded but numbers look off | Delete `$WORKDIR/05_pipelines_dependencies` and re-run everything for a clean start. |

For pipelines with dozens of steps and hundreds of samples, hand-written drivers get unwieldy: that is what workflow managers like Nextflow solve. See [08](../08_nextflow/README.md).

Next: [06 · Interactive jobs and choosing nodes](../06_interactive_and_nodes/README.md)
