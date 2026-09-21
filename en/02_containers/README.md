# 02 · Containers: real tools, no installation

**You'll learn:** run bioinformatics tools from container images, pin versions, and make your data visible inside them.
**Time:** 45 minutes.
**Why it matters in bioinformatics:** tools have fragile dependencies (a specific Python, Java, a C library). Installing them on a shared cluster without admin rights is painful, and two people rarely end up with the same versions. A container packages one tool with everything it needs: you download one file and everyone gets identical behaviour, months later too.

---

## 1. The idea in one picture

```
 host node (OS, your files, PBS)            container image  (seqkit.sif = one read-only file)
 ┌───────────────────────────────┐          ┌────────────────────────────────┐
 │ apptainer exec seqkit.sif  ───┼─────────▶│ its own /usr, /bin, libraries  │
 │            seqkit stats x.fq  │          │ + the seqkit program           │
 │ files you --bind are shared ◀─┼─────────▶│ sees only what you bind        │
 └───────────────────────────────┘          └────────────────────────────────┘
```

- **Apptainer** (older name: *Singularity*) is the container runtime made for clusters: no root required, works with PBS. Your `site.conf` says which command your cluster has (`CONTAINER_RUNTIME`).
- An **image** is a file (`.sif`). You can copy it, `ls` it, delete it, like any file.
- Unlike Docker, the container shares your user, your hostname and the network. It only *isolates the software*.

## 2. Getting an image

Most bioinformatics tools already have public images from **BioContainers** (the containers behind bioconda), hosted at `quay.io/biocontainers/<tool>:<tag>`.

```bash
apptainer pull seqkit.sif docker://quay.io/biocontainers/seqkit:2.13.0--he881be0_0
```

- **Pin the tag** (`2.13.0--he881be0_0`), never `latest`: `latest` changes silently and your results stop being reproducible.
- **Finding a tag:** search the tool at <https://biocontainers.pro/registry> or browse `https://quay.io/repository/biocontainers/<tool>?tab=tags`. Pick a version deliberately (the newest is usually fine for a new project; keep the same one within a project).
- The course pins its tools in [`../containers.conf`](../containers.conf); `00_getting_started/pull_containers.sh` downloaded them into `$SIF_CACHE`.
- **Pull once, on a node with internet**, and reuse the `.sif` afterwards. Jobs should not download things: many compute nodes have no internet, and 100 array tasks pulling the same image is wasteful.
- Pulls store cache data under `~/.apptainer` by default, which can fill a small home quota. `pull_containers.sh` sets `APPTAINER_CACHEDIR` to avoid that.

## 3. Running a tool

```bash
apptainer exec tool.sif <command> <arguments>
```

`exec` runs the command *inside* the container. Example: `apptainer exec seqkit.sif seqkit stats reads.fastq.gz`.

### Bind mounts: the source of most container errors

The container only sees what you give it. Depending on how your site configured Apptainer, your home directory and current directory may be shared automatically, and other locations (`/data`, `/scratch`, your project area) may not. If a tool says *file not found* for a file that exists, this is the first suspect.

```bash
apptainer exec --bind /project/mine,/scratch tool.sif tool /project/mine/reads.fq
# or with a different path inside:  --bind /host/path:/path/in/container
```

**Good habit:** always bind what you need explicitly. Then the script works on any cluster, whatever its defaults. Remember that output written *by the tool* needs a bound, writable directory; output redirected by the shell (`> file`) does not, because the shell runs outside the container.

### The course helper

From section 03 on, scripts call `edu_exec seqkit stats x.fq.gz`, defined in [`../lib/edu.sh`](../lib/edu.sh). It is only shorthand for
`$CONTAINER_RUNTIME exec --bind <EDU_ROOT,DATA_DIR,WORKDIR,BIND_PATHS> $SIF_CACHE/seqkit.sif seqkit stats x.fq.gz`. Read the function: 6 lines.

## 4. Try it

```bash
cd 02_containers
qsub example_container_job.pbs
cat example_container.o*
```

The log shows: the tool version inside, proof that the node itself has no `seqkit`, the operating system inside vs outside, real read statistics, and the helper doing the same call.

## 5. Exercises

### 2a · Fill in the blanks (10 min)
`exercise_02a_fill_in_blanks.pbs` runs `seqkit stats` on the real reads. Fill each `___`, submit, then `./check_02a.sh`.

### 2b · Write it yourself: FastQC (15 min)
**FastQC** is the standard first look at sequencing reads. Write `my_fastqc.pbs` that:
- requests 2 CPUs, 2 GB, 10 minutes;
- runs `fastqc` from `$SIF_CACHE/fastqc.sif` on both real FASTQ files (`$DATA_DIR/real/test_1.fastq.gz`, `test_2.fastq.gz`) with 2 threads (`-t 2`);
- writes its output to `$WORKDIR/02_containers/fastqc/` (use `-o`; the directory must exist first).

Then `./check_02b.sh`. When it passes, copy the `.html` files to your laptop with `scp`/`rsync` and open them in a browser. Which module would you look at first to spot adapter contamination?

### 2c · Bind mounts (10 min)
`exercise_02c_bind_mounts.pbs` runs with `--containall` (a strict mode where nothing is shared automatically). Decide what to bind, fill the blank, then `./check_02c.sh`. *Experiment:* remove the `--bind` and resubmit: what error do you get? (On some sites the data may still be visible because the admin binds it for everyone. That is exactly why explicit binds are good practice.)

## Check yourself
- [ ] I can explain the difference between an image, a tag and a container run.
- [ ] I know why `latest` should not be used.
- [ ] A tool says a file is missing but `ls` shows it: I know to check `--bind`.
- [ ] `check_02a.sh`, `check_02b.sh`, `check_02c.sh` pass.

## If it goes wrong

| What you see | Likely cause and fix |
|---|---|
| `FATAL: ... mount source ... doesn't exist` | A path in `--bind` is misspelled or absent on this node. Check with `ls`. |
| Tool: `No such file or directory` on an existing file | Directory not bound. Add it to `--bind`. |
| Tool: `Permission denied` writing output | Output directory is not bound, or is read-only (image contents are always read-only). |
| `image ... is missing` from `edu_exec` | Run `00_getting_started/pull_containers.sh`. |
| `apptainer: command not found` inside the job only | The runtime is available only via `module load`. Add the `module load ...` line to the script, before its first use. |
| `FATAL: ... no space left` while pulling | Cache/tmp are in a small quota. Set `APPTAINER_CACHEDIR` and `APPTAINER_TMPDIR` to roomier directories. |

Next: [03 · Resources and threads](../03_resources_threads/README.md)
