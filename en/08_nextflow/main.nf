// main.nf: alignment pipeline as a Nextflow workflow
//
// A small pipeline for the simulated samples:
//   FASTP -> MINIMAP2 -> SAMTOOLS_SORT -> SAMTOOLS_FLAGSTAT
//
// Run it with:   nextflow run main.nf -resume
// (first create nextflow.config with ./make_config.sh)
//
// Every process declares what it needs (cpus, memory, time). With the "pbspro"
// executor, Nextflow turns that into a qsub request like
//   qsub -l select=1:ncpus=2:mem=2gb -l walltime=00:15:00 ...
// and submits one PBS job per task. Containers and paths come from nextflow.config.

nextflow.enable.dsl = 2

process FASTP {
    tag "$id"
    publishDir "${params.outdir}/fastp", mode: 'copy', pattern: '*.json'
    cpus 2
    memory '2 GB'
    time '15m'

    input:
    tuple val(id), path(r1), path(r2)

    output:
    tuple val(id), path("${id}_R1.clean.fastq.gz"), path("${id}_R2.clean.fastq.gz")
    path "${id}.fastp.json"

    script:
    """
    fastp -i $r1 -I $r2 \
        -o ${id}_R1.clean.fastq.gz -O ${id}_R2.clean.fastq.gz \
        -j ${id}.fastp.json -h ${id}.fastp.html --thread $task.cpus
    """
}

process MINIMAP2 {
    tag "$id"
    cpus 2
    memory '3 GB'
    time '20m'

    input:
    tuple val(id), path(r1), path(r2)
    path ref

    output:
    tuple val(id), path("${id}.sam")

    script:
    """
    minimap2 -t $task.cpus -ax sr $ref $r1 $r2 > ${id}.sam
    """
}

process SAMTOOLS_SORT {
    tag "$id"
    publishDir "${params.outdir}/bam", mode: 'copy'
    cpus 2
    memory '2 GB'
    time '15m'

    input:
    tuple val(id), path(sam)

    output:
    tuple val(id), path("${id}.bam")

    script:
    """
    samtools sort -@ ${task.cpus - 1} -m 256M -o ${id}.bam $sam
    """
}

process SAMTOOLS_FLAGSTAT {
    tag "$id"
    publishDir "${params.outdir}/flagstat", mode: 'copy'
    cpus 1
    memory '1 GB'
    time '10m'

    input:
    tuple val(id), path(bam)

    output:
    path "${id}.flagstat.txt"

    script:
    """
    samtools flagstat $bam > ${id}.flagstat.txt
    """
}

workflow {
    // one row per sample: id <TAB> R1 <TAB> R2, limited to the first params.n_samples
    samples = Channel.fromPath(params.samples)
        .splitCsv(sep: '\t')
        .map { row -> tuple(row[0], file(row[1]), file(row[2])) }
        .take(params.n_samples)

    FASTP(samples)
    MINIMAP2(FASTP.out[0], file(params.ref))
    SAMTOOLS_SORT(MINIMAP2.out)
    SAMTOOLS_FLAGSTAT(SAMTOOLS_SORT.out)
}
