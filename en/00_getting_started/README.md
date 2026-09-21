# 00 · Getting started

**You'll learn:** what a cluster is, how to get this course running on yours, and how to prove it works.
**Time:** 20–30 minutes (most of it waiting for downloads and one small job).
**You need:** an account on a PBS cluster and a terminal. Basic shell skills (`cd`, `ls`, `cat`, editing a file with `nano` or `vim`).

---

## 1. The 2-minute mental model

A **cluster** is a group of computers ("**nodes**") sharing storage, managed by a **scheduler**. PBS is that scheduler.

```
   you ──ssh──▶  login node ──qsub──▶  scheduler (PBS) ──▶ compute node 1
                 (shared, light                          ├─▶ compute node 2
                  work only)                             └─▶ compute node …
                        └──────── shared filesystem: everyone sees the same files ────────┘
```

| Place | What you do there | What you must not do there |
|---|---|---|
| **Login node** | log in, edit files, submit and monitor jobs, move data | run analyses. It is shared by everyone; a heavy command slows down all your colleagues |
| **Compute nodes** | *jobs* run here, started for you by PBS | log in directly (you reach them through PBS) |

A **job** is just a shell script plus a request: *"give me 4 CPUs and 8 GB of memory for up to 2 hours, then run this."* PBS queues the request, finds a node with room, runs the script there, and saves its output. That is the whole idea; everything else in this course is detail on top.

**Why bioinformatics needs this:** aligning 100 samples, or one sample against a big genome, needs more CPUs and memory than a laptop has, and you want it to keep running after you close your laptop.

## 2. Connect and get the material

```bash
ssh <your-username>@<login-node-address>      # ask your cluster admin for the address
git clone <this-repository-url> PBS_edu       # or copy the folder with: scp -r PBS_edu <you>@<login-node>:~/
cd PBS_edu/en
```

Moving files between your laptop and the cluster:

```bash
scp results.tsv <you>@<login-node>:~/            # laptop -> cluster
rsync -avP <you>@<login-node>:~/results/ ./results/   # cluster -> laptop, resumable
```

## 3. Set up (three commands and one job)

Run these from `00_getting_started/`:

```bash
./setup.sh              # 1. discovers your queue, container tool, and asks where to store data
./fetch_data.sh         # 2. downloads a tiny real dataset (about 60 KB)
./pull_containers.sh    # 3. downloads the bioinformatics tools as container images (a few minutes)
qsub make_samples.pbs   # 4. YOUR FIRST JOB: simulates 6 samples of sequencing reads
```

`qsub` prints a **job id** like `12345.myserver`. Watch it with `qstat -u $USER`: state `Q` (queued) turns into `R` (running), then it disappears (finished). It takes a minute or two. Then:

```bash
./check_env.sh          # verifies everything, including a 10-second test job on a compute node
```

You want to see `All checks passed.` at the end.

### What did those commands do?

- **`setup.sh`** wrote `../site.conf`: a small file with your cluster's specifics (queue name, where data lives, whether the tool is `apptainer` or `singularity`). Every script in the course reads it, so *nothing in the exercises is hard-coded to one cluster*. Open it and read it.
- **`fetch_data.sh`** downloaded a 29.8 kb SARS-CoV-2 genome and 100 real read pairs. Tiny on purpose: sections 01 and 02 finish in seconds.
- **`pull_containers.sh`** downloaded the tools (seqkit, FastQC, fastp, minimap2, samtools, wgsim) as **container images**. A container bundles a program with everything it needs, so there is nothing to install and everyone runs identical versions. Section 02 explains this properly.
- **`make_samples.pbs`** is a real job: it runs `wgsim` to simulate 6 samples × 300,000 read pairs. Sections 03–05 use them because they are large enough to make CPU, memory and time visible.

## 4. A 60-second FASTQ primer

Sequencers produce **FASTQ** files: 4 lines per read.

```
@read_1              <- name
GATTTGGGGTTCAAAGCAG  <- the DNA sequence
+
IIIIIIIIIIIIIIIIIII  <- a quality score per base (I = very good)
```

Paired-end sequencing gives two files per sample (`_R1`, `_R2`), read *n* in one pairs with read *n* in the other. `.gz` means gzip-compressed; read it with `zcat file.fastq.gz | head`. A **reference genome** is a FASTA file (`>name` line, then sequence). *Aligning* reads to a reference (section 03) is the classic heavy step that motivates clusters.

## If it goes wrong

| Symptom | Likely cause and fix |
|---|---|
| `qsub: command not found` | Not on the login node, or PBS needs `module load`. Ask your admin / try `module avail pbs`. |
| `qsub: ... queue ... required` or "no default queue" | Put the queue name in `EDU_QUEUE` in `site.conf` (`qstat -Q` lists queues) and use `edu_qsub` or `qsub -q <queue>`. |
| `apptainer: command not found` | Try `module avail apptainer` (or `singularity`) and `module load` it; or run `pull_containers.sh` as a job (`qsub pull_containers.sh`). |
| Image pull fails / times out | The node may have no internet or a proxy is needed. Ask your admin; images can be pulled elsewhere and copied into `sif/` as `<tool>.sif`. |
| `make_samples` job stays in `Q` | The cluster is busy. `qstat -f <jobid> \| grep -i comment` says why. |
| `check_env.sh` says the test job failed | Read the log it prints. Typical cause: `DATA_DIR` is on a disk compute nodes cannot see. Re-run `setup.sh` with a shared directory. |
| `No space left` / quota errors | Point setup at a bigger area, or lower `READS_PER_SAMPLE` in `site.conf`. |

Ready? Go to [01 · PBS basics](../01_pbs_basics/README.md). Stuck on a word? See the [glossary](../GLOSSARY.md).
