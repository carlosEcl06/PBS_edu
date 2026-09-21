# Diagnoses for the six broken jobs

Fixed versions are in this directory (`fixed_0N.pbs`), each starting with an explanation.
Submit them from `07_troubleshooting/` (`qsub solutions/fixed_01.pbs`). Read them only after your own attempt.

| # | What you observed | Root cause | How to confirm it | Generic lesson |
|---|---|---|---|---|
| 1 | Exit 0, result exists, number wrong (`reads: 0`) | Relative path resolved in the wrong directory; error swallowed by a pipe | first lines of the log show `zcat: ... No such file` | Use absolute paths; validate results, not just exit status |
| 2 | Log stops abruptly, no result | Walltime shorter than the work | `qstat -xf`: `Exit_status = 271`, `resources_used.walltime` ≈ request | Measure, then request ~2× |
| 3 | qsub error, or job in `Q` forever | Request larger than any node | `qstat -f`: `comment = Can Never Run` (or similar) | Look at `pbsnodes -a`, request what fits; `qdel` stuck jobs |
| 4 | Dies after processing some inputs | One typo'd input path + `set -e` | log: which file was processing when it stopped | Validate every input at the start |
| 5 | Fails in a second, container error | `--bind` source `refs` does not exist (`ref`) | log: `FATAL: ... mount source ... doesn't exist` | Read the first error; `ls` every path |
| 6 | "unbound variable", works by hand | Login-shell variables are not passed to jobs | log: `SAMPLE: unbound variable` | Default inside the script, or `qsub -v VAR=value` |
