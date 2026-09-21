# Exercise 3a: what to expect

There is no single right answer: your numbers depend on the cluster's hardware. This is what a
typical run looks like, and how to read it.

```
threads  seconds  speedup  efficiency
      1       52    1.00x       100%
      2       30    1.73x        87%
      4       19    2.74x        68%
      8       15    3.47x        43%
```

- **Speedup** = time with 1 CPU ÷ time with N CPUs. **Efficiency** = speedup ÷ N.
- The curve flattens: reading and decompressing input, loading the reference index, and writing the
  BAM are (mostly) single-threaded, so adding CPUs cannot speed those parts up. This limit is
  known as Amdahl's law. With such small inputs the fixed parts dominate sooner.
- A defensible choice is the largest N whose efficiency is still ≥ 60–70% (here 4). Going from 4 to 8
  CPUs saves 4 seconds but reserves 4 more CPUs for the whole run: on a busy cluster the longer wait
  for an 8-CPU slot usually costs more than it saves.
- If the timings are noisy or 1 CPU is not much slower than 8, the job is dominated by something
  other than computing (input reading, node start-up). That is also a valid finding.
- The larger your real data, the better the scaling (fixed costs matter less): re-measure on a
  representative sample of your own data before settling on numbers for a big project.
