# 06 · Interactive jobs and choosing nodes

**You'll learn:** get a shell on a compute node to test commands, see which nodes are busy, and (rarely) ask for a specific node.
**Time:** 30–40 minutes.
**Why it matters in bioinformatics:** a new pipeline rarely works the first time. Debugging by submitting a job, waiting, reading the log, and repeating is slow. An *interactive job* lets you try commands live, with real resources, without abusing the login node.

---

## 1. Interactive jobs

```bash
qsub -I -l select=1:ncpus=2:mem=4gb -l walltime=00:30:00
```

`-I` means interactive. PBS queues the request like any other job; when resources are free, your terminal turns into a shell **on a compute node**. Anything you run there uses the resources you asked for. Typing `exit` (or hitting the walltime) ends the job.

Inside the session:
```bash
cd "$PBS_O_WORKDIR"            # the directory you ran qsub -I from
source ../lib/edu.sh           # (this course) settings + helpers
edu_exec seqkit stats ...      # try commands until they work, then paste them into a script
```

**Etiquette:**
- The resources are reserved *even while you are thinking or away*. Ask for the minimum, keep the walltime short, and **`exit` when done**.
- Interactive is for *testing on small inputs*, not for running the real analysis: close your laptop and the session dies. Real work goes in a batch job.
- Expect to wait in the queue like any other job. If it seems stuck, `qstat -f <id> | grep comment`.

## 2. Seeing the nodes

```bash
pbsnodes -aSj          # one-line summary per node (on OpenPBS / PBS Pro)
pbsnodes -a            # everything about every node (long)
pbsnodes <node>        # everything about one node
./check_free_nodes.sh          # this section's readable table, works on any PBS
./check_free_nodes.sh 4 8      # only nodes with >= 4 free CPUs and >= 8 GB free
```

| Node state | Meaning |
|---|---|
| `free` | accepting jobs (it may already run some: look at the free/all columns) |
| `job-busy` / `job-exclusive` | full, or reserved by one job |
| `offline` | an admin turned it off on purpose (maintenance, suspected problem) |
| `down` / `state-unknown` | not responding |

`check_free_nodes.sh` computes free = `resources_available` − `resources_assigned` from `pbsnodes -a`. Read the script: it is 30 lines of `awk`.

## 3. Who chooses the node? Usually PBS

You describe *what* you need (CPUs, memory, time); the scheduler finds *where*. That is almost always what you want, because it spreads the load and starts your job as soon as any node fits.

Ask for a specific node only for a reason:
- reproducing a problem you saw on one node;
- using something only that node has (a GPU, a license, big local disk);
- comparing timings on identical hardware.

```bash
#PBS -l select=1:ncpus=2:mem=4gb:host=node07
```

**Costs:** your job will wait for *that* node even if ten others are idle. And hard-coding a node name into a script makes it break when the node is renamed, retired or busy.

### What if one node is bad?
Occasionally a node misbehaves (a filesystem not mounted, a missing tool, a full disk), and jobs that land there die in seconds while the same script works elsewhere. What to do:

1. **Confirm it is the node:** compare the `host:` line in the logs of failed and successful jobs (`edu_banner` prints it).
2. **Fail fast and loudly:** start scripts with `edu_preflight || exit 1` (see `lib/edu.sh`). The log then says exactly what is wrong on which node.
3. **Report it** to your admins: they can set the node `offline` (`pbsnodes -o`) until fixed. This is the real fix.
4. **Work around it** meanwhile by resubmitting (often lands elsewhere) or by pinning to a known-good node with `host=`.

Note that *excluding* a node (`host!=node05`) is **not** supported by every PBS setup: some reject it ("Illegal attribute or resource value"). Ask your admins whether your site offers a queue, a custom resource or a node group for that.

### Exclusive nodes
`-l place=excl` asks for a node to yourself. Sometimes justified (benchmarks, very memory-hungry jobs), but it blocks everyone else from that node's idle CPUs: use rarely.

## 4. Try it

```bash
cd 06_interactive_and_nodes
./check_free_nodes.sh
qsub -I -l select=1:ncpus=1:mem=1gb -l walltime=00:10:00
#   inside:  hostname ; echo $PBS_JOBID ; echo $NCPUS ; exit
```

## 5. Exercises

### 6a · Pin a job to a node (10 min)
1. `./check_free_nodes.sh 1 1` and choose a node.
2. Edit `exercise_06a_pin_to_node.pbs`: replace `___` in `host=___`.
3. `qsub` it, wait, and `./check_06a.sh`: it compares where the job ran with what you asked for.

### 6b · An interactive session (15 min)
1. Start a session with **2 CPUs, 4 GB**: `qsub -I -l select=1:ncpus=2:mem=4gb -l walltime=00:30:00`.
2. Inside it, run seqkit on the two real read files and save the table to `$WORKDIR/06_interactive_and_nodes/interactive_stats.tsv`.
3. Still inside, write a file `$WORKDIR/06_interactive_and_nodes/interactive_proof.txt` containing three lines: `job_id: ...` (`$PBS_JOBID`), `host: ...` (`hostname`), `ncpus: ...` (`$NCPUS`).
4. `exit`, then `./check_06b.sh`.

Solutions: [`solutions/exercise_06.md`](solutions/exercise_06.md).

## Check yourself
- [ ] I can start an interactive session, run commands in it, and leave it properly.
- [ ] I can tell from `pbsnodes` whether a node has free CPUs and memory.
- [ ] I can say when pinning a node is justified and what it costs.
- [ ] `check_06a.sh` and `check_06b.sh` pass.

## If it goes wrong

| What you see | What to do |
|---|---|
| `qsub: waiting for job ... to start` for a long time | Same as any queued job. Ask for less, or wait. `Ctrl-C` cancels the request. |
| Session dropped and prompt is back | Walltime reached, or your connection broke. Interactive sessions do not survive a lost SSH connection. |
| Job with `host=` stays `Q` | That node is full, or the name is wrong (`pbsnodes -a` lists exact names). |
| `Unknown resource: host` | Your PBS may call it `vnode`: `select=1:ncpus=1:vnode=node07`. |
| `check_free_nodes.sh` shows nothing | `pbsnodes -a` prints nothing for you (some sites restrict it), ask your admin. |

Next: [07 · Troubleshooting](../07_troubleshooting/README.md)
