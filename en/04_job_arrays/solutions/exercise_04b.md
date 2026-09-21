# Solution to exercise 4b

Array indices can be a range with a step: `start-end:step`. Indices 2 and 5 are `2-5:3`:

```bash
qsub -J 2-5:3 exercise_04a_fill_in_blanks.pbs
```

A `-J` given on the command line overrides the `#PBS -J` line in the script. The same
script runs, and `PBS_ARRAY_INDEX` takes only the values 2 and 5.

If the failed indices are not evenly spaced (say 2, 3 and 7) either submit several small
arrays, or make the script skip finished work so you can simply resubmit everything:

```bash
if [ -s "$OUT/$id.stats.tsv" ]; then echo "$id already done, skipping"; exit 0; fi
```

That "skip if the output already exists" pattern is called making a job **idempotent**.
One caveat: a crash halfway can leave a half-written output that looks finished. The robust
form writes to a temporary name and renames only at the end (`mv` within one filesystem is atomic):

```bash
tool ... > "$OUT/$id.tsv.tmp" && mv "$OUT/$id.tsv.tmp" "$OUT/$id.tsv"
```
