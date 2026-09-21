# 07 · Troubleshooting: when jobs go wrong

**You'll learn:** a repeatable routine for finding out why a job failed, the most common causes, and habits that prevent them.
**Time:** 60 minutes (mostly the exercises).
**Why it matters in bioinformatics:** jobs fail. Pipelines have many steps, hundreds of samples and heavy tools, so something will always misbehave: a typo in one sample name, a file on a disk the node can't see, a job killed at the walltime. The difference between a beginner and an experienced user is not fewer failures but how fast they find the cause.

---

## 1. The debugging routine

Follow these in order. Most problems are solved by step 2.

1. **Did it run at all?**
   `qstat -u $USER` (running/queued) · `qstat -x -u $USER` (finished, if the site keeps history). Never ran and is in `Q`/`H`? → step 5.
2. **Read the log, from the top.** `<jobname>.o<jobid>` (and `.e<jobid>` if not merged with `-j oe`). The *first* error is usually the cause; everything after it is fallout.
3. **How did it end?** `qstat -xf <jobid> | grep -E 'Exit_status|resources_used|comment'`

   | `Exit_status` | Meaning |
   |---|---|
   | `0` | The script ended successfully. If the *result* is wrong, the bug is in the script's logic |
   | `1`–`255` | Your script or tool returned an error code: read the log |
   | `256+N` (`271`, `265`) | PBS killed it with signal N: most often **walltime** (compare `resources_used.walltime` with the request) or **memory** (`resources_used.mem`) |

4. **Where did it run?** The `host:` line in the log (`edu_banner` prints it). Same script, different node, different result → suspect that node (see section 06).
5. **Stuck in the queue?** `qstat -f <jobid> | grep -i comment`: PBS writes why. Common messages: not enough free resources (wait), `Can Never Run` (your request is impossible: too many CPUs/memory/walltime for the queue), job held by a dependency.
6. **Reproduce it small and interactive.** `qsub -I` with the same resources, run the failing command by hand on one small input (section 06).
7. **Ask for help with facts.** Give your admin or colleague: the job id, the script, the log, the `qstat -xf` output, and what you already tried. "It doesn't work" cannot be answered; "job 12345, Exit_status 271, walltime request 00:10:00, used 00:10:02" can.

## 2. Symptom → likely cause → fix

| Symptom | Likely cause | How to confirm | Fix |
|---|---|---|---|
| `qsub` refuses the script | Typo in a `#PBS` line; trailing `# comment` on a `#PBS` line; request beyond queue limits | the error message names the problem; `qstat -Qf <queue>` shows limits | Fix the line; comments on their own lines |
| Job stays `Q` for a very long time | Cluster busy; or the request is too big to fit anywhere | `qstat -f` → `comment` | Wait; or ask for less; `qdel` if `Can Never Run` |
| Ends at the same moment as the walltime; log stops abruptly | Walltime too short | `Exit_status` 271, `resources_used.walltime` ≈ request | Measure a small run, then request ~2× |
| `Killed` in the log; `Exit_status` ≥ 256; memory near the request | Memory limit exceeded | `resources_used.mem` | Raise `mem=`; reduce tool memory/threads |
| `No such file or directory` on a file that exists | Relative path resolved from the wrong directory (jobs start in `$HOME`), or the directory is not visible inside the container | `pwd` in the log; `ls` the path | Absolute paths; `cd "$PBS_O_WORKDIR"`; `--bind` |
| `command not found` | Tool is only on your login shell (`module load`, conda) or absent on the node | `edu_banner` shows the node; check on that node with `qsub -I` | Load it inside the script; better, use a container |
| `unbound variable` / empty variable | Variables from your shell are not passed to jobs | log | Set it in the script, or `qsub -v NAME=value` |
| Fails in the first second, container error | Bad `--bind` source, missing image, runtime not in `PATH` | first line of the log | Check paths; run `pull_containers.sh`; `module load` |
| Result exists but is wrong or empty; exit status 0 | A failed command inside a pipe or a loop went unnoticed | Read the whole log | `set -o pipefail`; check outputs at the end |
| Job dies after partial work | One bad input in a batch | which file was being processed | Validate all inputs at the start |
| Works for one sample, fails for others | Data problem (corrupt or truncated FASTQ, unexpected characters), or a resource peak on a larger sample | log of the failing sample; `zcat file \| tail`; `seqkit stats` | Validate inputs; size resources for the largest sample |
| Same script fails on one node only | Node problem (filesystem not mounted, missing runtime, full disk) | compare `host:` in good vs bad logs | `edu_preflight`; report to admins (see 06) |
| Log file does not exist while job is `R` | Normal: the log is written when the job ends | | Write your own progress log to the shared filesystem |
| `Disk quota exceeded` / `No space left` | Home quota; container cache; huge intermediate files | `df -h`, `quota`, `du -sh ~/* \| sort -h` | Clean up; point caches (`APPTAINER_CACHEDIR`, `TMPDIR`) to a roomy area |

## 3. Never compute on the login node

The login node is a shared entrance hall. A heavy command there (aligning reads, sorting a big BAM, `gzip` on tens of GB, opening a huge file in an editor) slows everyone's logins and file listings, and administrators may kill it without warning. **Rule of thumb:** if it takes longer than a few seconds or more than one core, it is a job. If you are unsure whether a command is heavy, run it in `qsub -I` first. Fine on the login node: editing scripts, `qsub`/`qstat`, `ls`, `less`, small `grep`s, transferring modest files.

If you notice you launched something heavy: stop it (`Ctrl-C`, or `kill <pid>` after `ps -u $USER`) immediately and resubmit it properly.

## 4. Habits that prevent most failures

- **Test small, then scale.** One sample, short walltime, first. Then the array.
- **Start scripts defensively:** `cd "$PBS_O_WORKDIR" || exit 1`, `set -o pipefail`, `edu_preflight || exit 1`.
- **Validate inputs at the start** (exist? non-empty? right format?), all of them, and report every problem at once.
- **Check outputs, not only exit codes:** non-empty file, expected number of records.
- **Make jobs restartable**: write to a temporary name and rename at the end; skip work whose output exists.
- **Pin versions** (container tags), and keep the logs: they are your record of what ran.
- **Log where you ran:** the node name and the job id belong at the top of every log.
- **Request measured resources with a margin**, not maximum values "just in case".

## 5. Exercise 7 · Six broken jobs

The scripts in `broken_jobs/` are each broken in a different, realistic way (their header describes only the **symptom**). For each:

1. `qsub broken_jobs/broken_0N.pbs` (from this directory).
2. Investigate with the routine above. Do not look at `solutions/` yet.
3. Fix the script in place, resubmit, and `./check_07.sh N`.
4. Write down in one sentence what the cause was; then compare with `solutions/README.md`.

Job 3 may never start: use `qstat -f` to find out why, then `qdel` it. To restore a script you broke: `git checkout broken_jobs/broken_0N.pbs`.

When all six pass: `./check_07.sh`.

## Check yourself
- [ ] I can say what `Exit_status = 271` means and how to confirm it was the walltime.
- [ ] I know where PBS says why a job is still queued.
- [ ] I know why variables, working directory and PATH can differ between my shell and a job.
- [ ] `./check_07.sh` passes for all six.

Next: [08 · Workflow managers (Nextflow)](../08_nextflow/README.md)
