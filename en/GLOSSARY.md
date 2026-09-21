# Glossary

Words you will meet in this course, in plain language.

**Cluster** — several computers (nodes) sharing storage, used together through a scheduler.

**Node** — one computer in the cluster. *Login node*: where you log in and submit work. *Compute node*: where jobs run.

**Scheduler** — the program deciding which job runs where and when. Here: **PBS** (OpenPBS or PBS Professional).

**Job** — a script plus a resource request, submitted with `qsub`.

**Queue** — a waiting line with its own limits (max walltime, allowed users…). Many clusters have one default queue, so you never name it.

**Job state** — `Q` queued, `R` running, `H` held, `E` exiting, `F` finished (visible with `qstat -x`).

**Walltime** — how long the job may run *on the clock* (not CPU time). PBS kills the job when it is over, no matter what it is doing. Format `HH:MM:SS`.

**ncpus / select / chunk** — `select=1:ncpus=4:mem=8gb` requests **one chunk** (a bundle of resources on one node) containing 4 CPU cores and 8 GB of memory. `select=2:ncpus=4` would be two such chunks.

**Thread** — one stream of work inside a program. A tool run with `--threads 4` can use 4 cores. Requesting more cores than the tool uses wastes them; using more threads than you requested slows other people's jobs.

**Job array** — many copies of one job, each with a different index (`$PBS_ARRAY_INDEX`). The natural way to run one analysis per sample.

**Dependency** — "start job B only after job A finished OK" (`-W depend=afterok:<A>`). Chains steps into a pipeline.

**Interactive job** — `qsub -I`: PBS gives you a shell on a compute node, for testing.

**Shared filesystem** — storage visible from the login node *and* all compute nodes (often NFS or Lustre). Things in a node's local `/tmp` are not shared.

**Container / image / SIF** — a program packaged with all its dependencies. An *image* is the file; Apptainer/Singularity images end in `.sif`. Running one gives the same tool version everywhere.

**Apptainer / Singularity** — the container runtime common on clusters (Singularity was renamed Apptainer). Unlike Docker it needs no root rights.

**Bind mount** — making a host directory visible inside a container (`--bind /host/dir`). Files that are not bound are invisible to the tool.

**Biocontainers / bioconda** — a public collection of ready-made containers for bioinformatics tools (`quay.io/biocontainers/<tool>:<tag>`).

**Tag** — the version label of an image (`seqkit:2.13.0--he881be0_0`). Always pin one; `latest` changes without warning.

**Reference genome** — the known sequence you compare reads against (FASTA).

**FASTQ** — reads with per-base qualities, 4 lines per read. **R1/R2**: the two ends of paired-end reads.

**Alignment / mapping** — finding where each read belongs on the reference. Output: **SAM/BAM** (BAM is the compressed binary form; *sorted* BAMs are what downstream tools want).

**QC (quality control)** — inspecting and trimming reads before analysis (FastQC, fastp).

**Workflow manager** — software such as **Nextflow** or Snakemake that runs a multi-step pipeline for you, submitting each step as a PBS job and handling dependencies and reruns.
