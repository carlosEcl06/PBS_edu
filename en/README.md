# PBS_edu — job scheduling on this shared cluster

A short, hands-on guide to running compute on this server the way it's meant to be
used: through the PBS scheduler, never on the login node, with containers pinned to
exact versions. Everything here was worked out (and, in a couple of places, debugged
the hard way) while building a real phylogenomics pipeline on this same server — the
examples are grounded in actual mistakes, not hypotheticals.

## Why this exists

This is a shared, multi-tenant server. The login node (`pne2`) is for editing files,
submitting jobs, and light orchestration — **not for running anything that uses real
CPU or memory**. Everyone's jobs go through PBS, which schedules them onto the compute
nodes (`pne3` through `pne10`, availability varies). If you run your analysis directly
on `pne2` instead of submitting it as a job, you're not just breaking a rule — you're
using CPU that belongs to the shared login/orchestration node, which everyone
(including people just trying to `cd` and check on their jobs) depends on staying
responsive.

The good news: once you've done it two or three times, submitting a PBS job is not
harder than running a command directly. This guide gets you there.

## How to use this folder

Work through the numbered directories in order. Each one has:
- a `README.md` explaining the concept,
- one or more **working examples** you can submit as-is to see what a real job looks
  like end to end,
- one or more **exercises** — the same kind of script with key parts blanked out
  (`___`), for you to fill in and submit yourself.

Nothing here touches real project data. Every exercise submits a trivial job (runs in
seconds, uses minimal resources) so you can iterate quickly without worrying about
using up shared resources while you're still learning.

1. **`01_pbs_basics/`** — submitting, checking, and cancelling a job. Start here even
   if you've used PBS/Slurm elsewhere — the flags and quirks differ per cluster.
2. **`02_node_selection/`** — checking which compute nodes are actually free, and
   pinning your job to one explicitly. Matters more here than on some clusters, for
   reasons explained in that section.
3. **`03_apptainer_containers/`** — running software from a container instead of
   fighting with `conda`/`module load` dependency resolution. This is the recommended
   default for any tool that isn't trivial to install.
4. **`04_common_pitfalls/`** — real bugs hit while building a production pipeline on
   this exact server, written up as lessons rather than left as tribal knowledge.
5. **`05_advanced_nextflow/`** (optional, once the basics feel natural) — orchestrating
   a multi-step pipeline (many jobs, dependencies between them) with Nextflow's PBS
   executor instead of hand-rolled `qsub` chaining.

## The one-paragraph version, if you read nothing else

Never run real compute on `pne2`. Before submitting a job, check which compute nodes
are actually free (`pbsnodes <node>`) rather than assuming — this server doesn't always
support excluding a specific node, only pinning *to* one, so if you don't check first
you can end up stuck queued behind someone else's job or silently scheduled onto a node
with a known problem. Prefer Apptainer containers pinned to an exact version over
`conda`/system packages for anything beyond a one-line script. And when a container-based
job can't find a file that's visible from your login shell, check whether the path is
actually bind-mounted inside the container before assuming your data is missing — see
`04_common_pitfalls/`.
