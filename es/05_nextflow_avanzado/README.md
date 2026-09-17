# 05 — Orquestar pipelines de varias etapas con Nextflow (opcional, una vez que lo básico se sienta natural)

Encadenar `qsub` a mano (`qsub -W depend=afterok:$jobid ...`) funciona para un puñado
de etapas secuenciales, pero se vuelve difícil de manejar en cuanto tienes muchas
tareas independientes que deberían correr en paralelo (ej. "corre este mismo análisis
en 500 muestras") o un pipeline con varias etapas donde cada una depende de que la
anterior termine. Nextflow maneja ambos casos de forma nativa, envía cada tarea como
su propio trabajo PBS por ti, y ofrece reanudación (`-resume`), de modo que un pipeline
de varios días que falla a mitad de camino no significa empezar de cero.

Esta sección no es un tutorial completo de Nextflow -- ver la
[documentación oficial](https://www.nextflow.io/docs/latest/index.html) para eso. Es
un ejemplo mínimo y funcional del patrón específico que importa en *este* clúster:
PBS + Apptainer juntos.

## La configuración esencial

```groovy
// nextflow.config
process.executor = 'pbs'
process.queue = 'workq'
apptainer.enabled = true
apptainer.autoMounts = true

// La revisión periódica del estado de la cola PBS de este clúster tiene una
// particularidad conocida (un error "conflicting options" en qstat -f -1)
// -- inofensivo, Nextflow recurre a su propio seguimiento por trabajo vía
// un archivo .exitcode, pero aumentar estos dos tiempos de espera evita
// fallos espurios en trabajos largos donde NFS puede retrasarse un poco:
executor.exitReadTimeout = '270 sec'
executor.pollInterval = '30 sec'
```

## Un process mínimo en abanico (fan-out)

```groovy
// main.nf
process RUN_PER_SAMPLE {
    tag "${sample_id}"
    executor 'pbs'
    // round-robin entre nodos conocidos como buenos -- ver 04_errores_comunes/ para entender por qué
    clusterOptions { "-q workq -l select=1:ncpus=2:mem=4gb:host=${['pne3','pne4','pne6','pne7','pne10'][task.index % 5]}" }
    time '30m'
    container 'docker://quay.io/biocontainers/algunaherramienta:1.2.3--hdfd78af_2'
    errorStrategy 'retry'
    maxRetries 2

    input:
    tuple val(sample_id), path(input_file)

    output:
    path "${sample_id}.result", emit: result

    script:
    """
    algunaherramienta --input ${input_file} --output ${sample_id}.result
    """
}

workflow {
    samples_ch = Channel.fromPath('samples/*.fasta')
        .map { f -> [f.baseName, f] }

    RUN_PER_SAMPLE(samples_ch)
}
```

Ejecuta con:

```bash
nextflow run main.nf -resume
```

`-resume` es la razón por la que vale la pena aprender esto incluso para un pipeline de
tamaño moderado: si la tarea 400 de 500 falla (un problema en un nodo, un walltime
demasiado ajustado, lo que sea), arreglar el problema y volver a correr con `-resume`
retoma exactamente donde se quedó, en vez de rehacer las 399 tareas que ya habían
tenido éxito.

## Una nota sobre errorStrategy

Usa la forma **estática** (`errorStrategy 'retry'` + `maxRetries N`) en vez de un
closure dinámico (`errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }`), a menos
que tengas una razón específica para necesitar la forma dinámica — la forma dinámica
puede generar su propio error si una tarea falla antes de que su contexto de ejecución
esté completamente inicializado (ej. durante la preparación de los archivos de
entrada), lo cual es una forma confusa de fallar encima de tu error original.
