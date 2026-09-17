# 05 — Orchestrating multi-step pipelines with Nextflow (optional, once the basics feel natural)

Hand-rolling `qsub` dependency chains (`qsub -W depend=afterok:$jobid ...`) works for a
handful of sequential steps, but gets unwieldy fast once you have many independent
tasks that should run in parallel (e.g. "run this same analysis on 500 samples") or a
pipeline with several stages that each depend on the previous one finishing. Nextflow
handles both natively, submits each task as its own PBS job for you, and gives you
resumability (`-resume`) so a multi-day pipeline that fails partway through doesn't
mean starting over from scratch.

This section isn't a full Nextflow tutorial -- see the
[official docs](https://www.nextflow.io/docs/latest/index.html) for that. It's a
worked, minimal example of the specific pattern that matters on *this* cluster: PBS +
Apptainer together.

## The essential config

```groovy
// nextflow.config
process.executor = 'pbs'
process.queue = 'workq'
apptainer.enabled = true
apptainer.autoMounts = true

// This cluster's PBS queue-status polling has a known quirk (a "conflicting
// options" error on qstat -f -1) -- harmless, Nextflow falls back to its own
// per-job .exitcode-file tracking, but raising these two timeouts avoids
// spurious failures on long-running jobs where NFS can lag briefly:
executor.exitReadTimeout = '270 sec'
executor.pollInterval = '30 sec'
```

## A minimal fan-out process

```groovy
// main.nf
process RUN_PER_SAMPLE {
    tag "${sample_id}"
    executor 'pbs'
    // round-robin across known-good nodes -- see 04_common_pitfalls/ for why
    clusterOptions { "-q workq -l select=1:ncpus=2:mem=4gb:host=${['pne3','pne4','pne6','pne7','pne10'][task.index % 5]}" }
    time '30m'
    container 'docker://quay.io/biocontainers/sometool:1.2.3--hdfd78af_2'
    errorStrategy 'retry'
    maxRetries 2

    input:
    tuple val(sample_id), path(input_file)

    output:
    path "${sample_id}.result", emit: result

    script:
    """
    sometool --input ${input_file} --output ${sample_id}.result
    """
}

workflow {
    samples_ch = Channel.fromPath('samples/*.fasta')
        .map { f -> [f.baseName, f] }

    RUN_PER_SAMPLE(samples_ch)
}
```

Run it with:

```bash
nextflow run main.nf -resume
```

`-resume` is the reason this is worth learning even for a moderately-sized pipeline:
if task 400 of 500 fails (a node hiccup, a walltime that was too tight, whatever),
fixing the problem and re-running with `-resume` picks up exactly where it left off
instead of re-doing the 399 tasks that already succeeded.

## A note on errorStrategy

Use the **static** form (`errorStrategy 'retry'` + `maxRetries N`) rather than a
dynamic closure (`errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }`) unless you
have a specific reason to need the dynamic form — the dynamic form can throw its own
error if a task fails before its execution context is fully initialized (e.g. during
input staging), which is a confusing failure mode to debug on top of whatever your
original error was.
