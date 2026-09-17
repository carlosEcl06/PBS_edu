# 04 — Real pitfalls hit on this cluster (and how they were diagnosed)

Generic PBS tutorials tend to stop at "here's how you submit a job." These are real
problems, hit while building an actual pipeline on this exact server, with the
reasoning that led to each fix — because the reasoning is the reusable part, not the
specific fix.

## 1. A compute node silently missing required software

**Symptom:** a pipeline fanning out ~550 near-identical jobs across several compute
nodes ran fine for the first couple hundred, then started failing with
`apptainer: No such file or directory` (exit code 127) on a subset of tasks, with no
obvious pattern from the error message alone.

**Wrong instinct:** just retry the failed tasks and hope it was a transient fluke.

**What actually worked:** submit a handful of tiny, single-purpose diagnostic jobs,
each pinned to exactly one candidate node (`host=pneN`), each just checking
`ls /usr/bin/apptainer`. This isolated the problem to a single node that was, for
whatever reason, missing the Apptainer binary entirely — every other node had it.

**The fix:** since this PBS setup doesn't support *excluding* a node
(`host!=pneN` fails outright), the fix was to explicitly enumerate the known-good
nodes and round-robin across them:

```groovy
// example: inside a Nextflow process's clusterOptions
def good_nodes = ['pne3', 'pne4', 'pne6', 'pne7', 'pne10']
clusterOptions { "-l select=1:ncpus=2:mem=4gb:host=${good_nodes[task.index % good_nodes.size()]}" }
```

**The lesson:** when a batch of jobs fails inconsistently (some nodes, not others),
don't guess and retry — write the smallest possible reproduction (one job, one node,
one check) for each suspect and let the evidence tell you which one it is.

## 2. A container can't see a file that's right there

**Symptom:** a job calling `apptainer exec sometool.sif ... /data2/path/to/input.gff`
failed with `FileNotFoundError`, even though `cat /data2/path/to/input.gff` from an
interactive shell worked fine, and the file was confirmed to exist with `ls`.

**Wrong instinct:** assume the file transfer/copy step earlier in the pipeline was
somehow incomplete or corrupted, and re-run it.

**What actually worked:** reading the failing tool's own source code (it's open source
— the traceback pointed to an exact line) confirmed it really was doing a plain
`open(path)` on the exact path that had been passed in. That ruled out a bug in the
tool itself and pointed at the container boundary: Apptainer's default bind-mount
behavior doesn't guarantee arbitrary absolute paths on shared storage are visible
inside the container, only your home directory and current working directory.

**The fix:** `cd` into the job's own working directory first and `cp` the needed
inputs there, then reference them by relative path instead of the original absolute
one. (Full explanation and example in `03_apptainer_containers/README.md`.)

**The lesson:** "the file doesn't exist" from inside a container job doesn't always
mean the file doesn't exist — check whether it's a bind-mount problem before assuming
a data problem, especially if the same path works fine outside the container.

## 3. A tool crashing on real biological data isn't always a bug

**Symptom:** a pangenome-analysis tool crashed partway through a real dataset with
`ValueError: Invalid gene sequence!` on some of the input genomes.

**Wrong instinct:** assume the input files were malformed and start re-deriving them.

**What actually worked:** reading the tool's own validation logic showed it was
rejecting genes with in-frame stop codons, non-multiple-of-3 lengths, or frameshifts —
exactly the kind of annotation you'd expect from real pseudogenes in a genome, not
necessarily a sign of corrupted input. The tool's own `--help` output listed a flag
(`--remove-invalid-genes`) specifically for this situation.

**The fix:** pass the flag the tool provides for this — it exists because real
biological data legitimately contains this, not as a workaround for a data bug.

**The lesson:** before assuming your input is broken, check whether the tool has a
documented option for the exact failure you're seeing — a purpose-built flag is a much
stronger signal than a generic try/except that the failure mode is expected, not a bug.

## 4. Never, not even briefly, compute on the login node

**Symptom:** none, really — this is a discipline note, not a debugging story. But
worth stating plainly: it's very easy, mid-debugging-session, to run "just one quick
command" directly over SSH on the login node instead of wrapping it in a PBS job,
especially for something that feels trivially cheap (checking a tool's `--help` output,
say). It happened once while building the pipeline this guide is drawn from — caught
within about a minute, the stray process killed, no lasting harm, but it shouldn't have
happened at all.

**The habit to build:** if a command needs to execute *anything* beyond trivial shell
scripting (any real program, any container, any actual computation), it goes through
`qsub`, full stop — even for something that feels like it'll take two seconds. The
login node is shared orchestration space for everyone; treat it that way consistently,
not just when it's convenient.
