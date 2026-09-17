# 02 — Checking node availability and pinning your job to a node

By default, PBS picks which compute node runs your job for you, based on what's free.
That's usually fine. Two situations on this cluster where you'll want to check and pin
explicitly instead of trusting the default:

1. **A node is occupied by someone else's job.** If you request more resources than
   are currently free anywhere, your job sits queued (`Q`) rather than running, even if
   *other* nodes are completely idle — PBS doesn't automatically try a different node
   for you mid-request the way some schedulers do. Checking first saves you from
   wondering why a job that should take 5 minutes has been queued for an hour.
2. **A specific node has a known problem.** As of writing, one of the compute nodes
   is missing a piece of software (Apptainer) that most real pipelines need — a job
   landing there fails immediately and confusingly. Pinning away from a known-bad node
   avoids this. **Important cluster-specific quirk:** this PBS setup does not support
   *excluding* a node (`host!=pne5`-style syntax fails with "Illegal attribute or
   resource value") — you can only pin *to* a specific node. So the workaround is to
   explicitly list only the good nodes and pick one yourself.

## Checking what's free

```bash
pbsnodes pne3        # replace pne3 with any compute node name
```

Look for two things in the output: `state = free` (vs. `busy`/`down`/`offline`), and
whether a `jobs = ...` line is present (if it's absent or empty, nothing is currently
running there). A node can show `state = free` while still having some jobs running on
it if not all of its CPUs are in use yet — check the `jobs` line, not just `state`.

To check several nodes at once:

```bash
for n in pne3 pne4 pne6 pne7 pne10; do
    echo -n "$n: "
    pbsnodes $n | grep -i '^ *jobs' || echo 'free'
done
```

(Ask around / check with whoever maintains the cluster for the current full list of
compute node names and which ones, if any, currently have known issues — the specific
node names and problems will drift over time, this guide won't keep itself updated.)

## Pinning your job to a specific node

Add `host=<nodename>` inside your `select` resource request:

```bash
#PBS -l select=1:ncpus=4:mem=8gb:host=pne3
```

## A pattern worth knowing: round-robin across several good nodes

If you're submitting many independent small jobs (common with tools like Nextflow that
fan a pipeline out across many parallel tasks), hardcoding all of them to the *same*
node wastes the other free ones. A simple round-robin — cycling through a list of known-
good nodes by task index — spreads the load without needing PBS's own (occasionally
unreliable, on this setup) automatic placement. See `05_advanced_nextflow/` for a real
example of this pattern in a Nextflow `clusterOptions` directive.

## Try it

`check_free_nodes.sh` is a ready-to-run version of the loop above — try it now to see
the current state of the cluster. Then do `exercise_02_pin_to_free_node.pbs`: check
which nodes are free yourself, fill in the node name, and submit.
