# 08 · Workflow managers: Nextflow (optional, advanced)

**You'll learn:** what a workflow manager does that a hand-written driver (section 05) cannot, and how to run and extend a small Nextflow pipeline on PBS.
**Time:** 45–60 minutes. **Optional:** you can be productive on a cluster without it, but most published pipelines use it.
**Before you start:** sections 01–05. You also need **Java 17+** and **Nextflow** (below).
**Why it matters in bioinformatics:** community pipelines (nf-core: RNA-seq, variant calling, assembly…) run on any cluster with one command. Knowing how a workflow manager talks to PBS lets you use them, and debug them when a task fails.

---

## 1. Why not just bash drivers?

The driver of section 05 works for 3 steps. Real pipelines have dozens of steps and hundreds of samples, and you want:

| Need | Hand-written `qsub -W depend` | Nextflow |
|---|---|---|
| Dependencies between hundreds of tasks | you track ids by hand | automatic, from data flow |
| Re-run after a failure, skipping finished work | you write skip logic | `-resume` (results are cached by input hash) |
| Resource request per step | separate `#PBS` headers | `cpus`, `memory`, `time` in each process |
| Different tools/containers per step | manual | `container` per process |
| Retry on transient errors | manual | `errorStrategy 'retry'` |
| Move to a bigger cluster or the cloud | rewrite | change the executor in the config |

Underneath, on PBS it is still `qsub` and `qstat`: Nextflow submits one PBS job for each *task* (one process run on one input). Everything you learned applies.

## 2. Install Nextflow

```bash
java -version                              # need 17 or newer; try: module avail java
curl -s https://get.nextflow.io | bash     # downloads a 'nextflow' launcher into the current dir
mkdir -p ~/bin && mv nextflow ~/bin/       # and make sure ~/bin is in your PATH
nextflow -version
```
(No internet on the login node? Download on your laptop and `scp` it, or ask your admin: many sites have `module load nextflow`.)

## 3. This section's pipeline

[`main.nf`](main.nf) has four **processes** (the steps) and a **workflow** block (the wiring):

```
samples.tsv ─▶ FASTP ─▶ MINIMAP2 ─▶ SAMTOOLS_SORT ─▶ SAMTOOLS_FLAGSTAT
                (trim)   (align)      (sort → BAM)     (mapping stats)
```

Read `main.nf` top to bottom; the ideas:
- A **process** declares `input:`, `output:` and a `script:` (the shell command). `$task.cpus` is what the process was given.
- Channels connect processes: `FASTP.out[0]` is FASTP's first output, fed into MINIMAP2. Nextflow starts each task when its inputs exist: that is the dependency logic you wrote by hand before.
- Samples flow as `tuple(id, R1, R2)`, so each task knows which sample it belongs to and all samples run in parallel, like an array.
- `publishDir` copies chosen outputs from the (hashed, temporary) work directory to a tidy results folder.

### Configuration: what is cluster-specific stays out of the pipeline

`./make_config.sh` writes `nextflow.config` from your `site.conf`: the PBS executor (`pbspro`, also right for OpenPBS), the queue if one is required, paths, container images, and bind mounts. Open it: the pipeline itself never mentions PBS or your paths. That is what makes Nextflow pipelines portable.

```bash
cd 08_nextflow
./make_config.sh
nextflow run main.nf -resume
```
In another terminal: `qstat -u $USER`. You will see jobs named like `nf-FASTP_sample_01` appear and vanish. Results end up in `$WORKDIR/08_nextflow/results/`.

**Where does the `nextflow run` process itself live?** It is a long-running "head" process that submits and watches the others. It is light, and many sites allow it on the login node inside `tmux`/`screen`; others don't. `qsub run_nextflow.pbs` runs it as a PBS job instead. Ask your admin which is expected.

### `-resume`
Run the same command again: finished tasks are skipped, only new or changed ones run. Change one parameter or one process script and only what depends on it re-runs. Delete `nf_work/` under `$WORKDIR/08_nextflow` (and results) to start clean.

### Reading failures
When a task fails, Nextflow prints its **work directory** (`.../nf_work/ab/cd1234...`). Go there:
```bash
cd <that directory>
cat .command.sh      # exactly what ran
cat .command.err     # its stderr
cat .exitcode        # its exit status
```
You can re-run `.command.run` in `qsub -I` to debug like in section 06.

## 4. Exercise 8a · Add a step (15 min)

`exercise_08a_add_stats.nf` is `main.nf` plus a new `SEQKIT_STATS` process that summarises the *cleaned* reads of each sample, with three blanks (`___`): the output file extension, the seqkit subcommand, and the call in the workflow. Fill them in, then:

```bash
nextflow run exercise_08a_add_stats.nf -resume
./check_08a.sh
```
Notice with `-resume` that FASTP and the alignment steps are **not** run again. Solution: `solutions/exercise_08a_add_stats.nf`.

## Check yourself
- [ ] I can explain what `-resume` does and why it is safe.
- [ ] I know where a failed task's command, stderr and exit code are.
- [ ] I can point at the lines that make Nextflow use PBS, and at what would change for another scheduler.
- [ ] `check_08a.sh` passes.

## If it goes wrong

| What you see | What to do |
|---|---|
| `nextflow: command not found` / Java error | Install Nextflow and Java 17+ (section 2). |
| `Unknown ... executor pbspro` | Very old Nextflow: upgrade (`nextflow self-update`). Torque sites use `executor = 'pbs'`. |
| Jobs are submitted but Nextflow says they failed while the work directory has correct output | Slow shared filesystem: raise `executor.exitReadTimeout` in `nextflow.config` (a commented line is there). |
| Nextflow complains about `qstat` output | Some PBS versions print extra fields. Update Nextflow first; then ask on the Nextflow Slack/forum with your `qstat -f` output. |
| `Process ... terminated with an error exit status (127)` | Command not found inside the container: wrong `container` for that process in `nextflow.config`. |
| `.sif` not found | Run `00_getting_started/pull_containers.sh`; check `sif_dir` in the config. |
| Tasks keep waiting in `Q` | Same as any PBS job: `qstat -f <id> \| grep comment`. Reduce `cpus`/`memory` in the process. |
| Work directory fills your quota | `nextflow clean -f` (after a successful run) or delete `nf_work/`. |

**Next steps:** try a community pipeline (<https://nf-co.re>) with `-profile singularity` (or `apptainer`) plus a small config file with `process.executor = 'pbspro'`; every one documents this.

You have finished the course. Keep the [cheat sheet](../CHEATSHEET.md) handy, and go run something real.
