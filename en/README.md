# PBS for bioinformatics: a hands-on course

Learn to run real analyses on a shared compute cluster with PBS, by doing it. Every exercise is a job you
submit, run on real (or realistically simulated) sequencing data with real tools, and verify with an
automatic checker.

**Who it's for:** biologists, students and analysts who know basic Linux (`cd`, `ls`, `nano`) and have just
received an account on a cluster.
**What you'll be able to do afterwards:** write and submit job scripts, choose CPU/memory/time sensibly,
process many samples in parallel, chain steps into a pipeline, run tools from containers, and work out why a
job failed.
**Time:** about 6–8 hours in total; each section stands on its own (45–60 min) and builds on the previous one.

---

## Why a course? The one-paragraph version

A cluster is shared by many people. You log in to a **login node** to prepare work, and submit **jobs** to a
scheduler (PBS), which runs them on **compute nodes** when resources are free. Analyses that need real CPU or
memory go in jobs, never on the login node. That single rule, plus a handful of commands (`qsub`, `qstat`,
`qdel`), covers 90% of daily use. The rest of this course is the other 10%: doing it efficiently and fixing it
when it breaks.

## The route

| # | Section | You will | Data / tools |
|---|---|---|---|
| 00 | [Getting started](00_getting_started/README.md) | connect, run the setup, submit your first job | SARS-CoV-2 reference + real reads |
| 01 | [PBS basics](01_pbs_basics/README.md) | write, submit, monitor, debug a job | zcat, awk |
| 02 | [Containers](02_containers/README.md) | run bioinformatics tools without installing them | seqkit, FastQC |
| 03 | [Resources and threads](03_resources_threads/README.md) | measure a job and request the right CPUs, memory, time | minimap2, samtools |
| 04 | [Job arrays](04_job_arrays/README.md) | one job per sample, re-run only failures | fastp, seqkit |
| 05 | [Pipelines and dependencies](05_pipelines_dependencies/README.md) | chain QC → align → summary | fastp, minimap2, samtools |
| 06 | [Interactive jobs and nodes](06_interactive_and_nodes/README.md) | test live on a compute node, read node status | pbsnodes |
| 07 | [Troubleshooting](07_troubleshooting/README.md) | diagnose six broken jobs | logs, qstat |
| 08 | [Nextflow](08_nextflow/README.md) (optional) | run and extend a workflow manager pipeline | Nextflow |

Do 00 first, then 01–05 in order. 06 and 07 can be done any time after 01. 08 is optional.

## What you need

- An account on a PBS cluster (OpenPBS or PBS Professional) and a terminal with `ssh`.
- `git` (or a way to copy this folder to the cluster), `bash`.
- Apptainer or Singularity on the cluster (usual on academic clusters; the setup script tells you if it is missing).
- About 1 GB of disk in a directory the compute nodes can see, and internet access from the login node for
  the one-time downloads.

You do **not** need admin rights, bioinformatics tools installed, or prior scheduler experience.

## How each section works

1. Read the section's `README.md` (learning goals, concepts, "if it goes wrong" table).
2. Run the **examples** (`example_*.pbs`): they work as-is. Read their comments.
3. Do the **exercises**: `exercise_*.pbs` (fill in blanks, fix a broken job, or write one from scratch).
4. Run the section's **checker** (`check_*.sh`). It inspects the real outputs of your jobs and tells you what
   is wrong and where to look. Checkers never change anything.
5. Compare with `solutions/` only after trying.

**Conventions to remember**
- Submit jobs **from the section directory**: `cd 03_resources_threads; qsub example_align_threads.pbs`.
- Your cluster's specifics live in `site.conf` (written by `00_getting_started/setup.sh`). No script hard-codes
  a queue, node or path. See `examples/site.pne.conf` for a filled-in example.
- `lib/edu.sh` holds small shared helpers (short, readable, worth reading).
- Job logs appear in the submit directory, named `<jobname>.o<jobid>`, when the job ends.

## Extras

- [Cheat sheet](CHEATSHEET.md): the commands and script anatomy on one page.
- [Glossary](GLOSSARY.md): every term used, in plain language.

## Notes for instructors and maintainers

- Checkers compute expected values from the data themselves (nothing is hard-coded to one dataset).
- Data: the reference genome and 100 real read pairs come from the public nf-core test-datasets
  (checksummed in `00_getting_started/data.sha256`); larger samples are simulated with `wgsim` by a job.
- Container versions are pinned in `containers.conf`.
- `tests/lint.sh` runs static checks (no cluster needed); run it before committing changes.
