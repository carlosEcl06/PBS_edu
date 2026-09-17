# 03 — Running software with Apptainer containers

Installing bioinformatics tools directly (via `conda`, `pip`, compiling from source...)
often turns into a dependency-resolution fight, and it's easy to end up with a subtly
different tool version than a labmate, which makes results hard to compare or reproduce.
The recommended default here instead: run the tool from a pre-built container.

## Why containers, and why pin an exact version

[Biocontainers](https://biocontainers.pro/) publishes a container for essentially every
common bioinformatics tool, built and versioned automatically from Bioconda. Two habits
matter:

1. **Pin the exact version tag, don't use `:latest`.** `:latest` silently changes over
   time and breaks reproducibility -- if your results depend on tool version X and
   someone reruns your pipeline six months later with whatever `:latest` has become by
   then, they may get different numbers with no obvious reason why.
2. **Get the exact tag from a trustworthy, already-checked source, don't guess it.** A
   good way: look at how an established pipeline framework
   ([nf-core/modules](https://github.com/nf-core/modules)) pins the same tool -- their
   module definitions list the exact, working `quay.io/biocontainers/<tool>:<version>`
   string, which is a real, tested pin rather than a guess.

## Pulling and running a container job

```bash
apptainer pull --force mytool.sif docker://quay.io/biocontainers/mytool:1.2.3--hdfd78af_2
apptainer exec mytool.sif mytool --version
```

`apptainer pull` downloads and converts the image once; after that, `apptainer exec
mytool.sif <command>` runs anything inside it as if it were installed locally. Do the
pull once (ideally to shared storage, not somewhere it'll be re-downloaded every job)
and reuse the `.sif` file across jobs.

## The one gotcha that will catch you: bind mounts

A container only sees the parts of the filesystem that are explicitly (or by default)
"bind-mounted" into it. Apptainer auto-mounts your home directory and current working
directory by default, but **does not reliably auto-mount arbitrary absolute paths
elsewhere on shared storage** just because you can see them from your login shell.

Concretely: if your job script does this --

```bash
apptainer exec mytool.sif mytool -i /data2/projects/SOME-OTHER-PROJECT/input.txt
```

-- and that path isn't covered by an auto-mount, `mytool` will fail with something
like "No such file or directory" for a file that very much exists and that *you* can
`cat` just fine from the same shell. This is genuinely confusing the first time it
happens, because the error looks like a missing-file problem when the file is right
there.

**The reliable fix: `cd` into your job's own working directory (inside the auto-mounted
area) and copy your inputs there first**, then reference them with relative paths:

```bash
cd /data2/projects/YOUR-PROJECT/results/my_job   # somewhere you have a real cwd
cp /data2/projects/SOME-OTHER-PROJECT/input.txt .
apptainer exec mytool.sif mytool -i input.txt     # relative path, always works
```

This costs a bit of disk I/O for the copy, but it's the difference between a job that
works every time and one that mysteriously fails depending on exactly which paths it
touches.

## Try it

`example_container_job.pbs` pulls a tiny, fast public container and runs a trivial
command in it — submit it as-is first. Then `exercise_03_run_a_tool.pbs` asks you to
pull a real bioinformatics tool's container and check its version, filling in the
container tag yourself (look it up on nf-core/modules or biocontainers.pro, don't
guess).
