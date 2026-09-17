# 05 — Orquestrando pipelines com várias etapas usando Nextflow (opcional, depois que o básico estiver natural)

Encadear `qsub` manualmente (`qsub -W depend=afterok:$jobid ...`) funciona para
algumas poucas etapas sequenciais, mas logo fica difícil de gerenciar assim que você
tem muitas tarefas independentes que deveriam rodar em paralelo (ex.: "rode esta mesma
análise em 500 amostras") ou um pipeline com várias etapas, cada uma dependendo da
anterior terminar. O Nextflow lida com os dois casos nativamente, submete cada tarefa
como seu próprio job PBS para você, e oferece retomada (`-resume`), de forma que um
pipeline de vários dias que falha no meio não significa recomeçar do zero.

Esta seção não é um tutorial completo de Nextflow -- veja a
[documentação oficial](https://www.nextflow.io/docs/latest/index.html) para isso. É um
exemplo mínimo e funcional do padrão específico que importa *neste* cluster: PBS +
Apptainer juntos.

## A configuração essencial

```groovy
// nextflow.config
process.executor = 'pbs'
process.queue = 'workq'
apptainer.enabled = true
apptainer.autoMounts = true

// A checagem periódica de status da fila PBS deste cluster tem uma
// particularidade conhecida (um erro "conflicting options" no qstat -f -1)
// -- inofensivo, o Nextflow recorre ao seu próprio rastreamento por job via
// arquivo .exitcode, mas aumentar estes dois timeouts evita falhas
// espúrias em jobs longos onde o NFS pode atrasar brevemente:
executor.exitReadTimeout = '270 sec'
executor.pollInterval = '30 sec'
```

## Um process mínimo com fan-out

```groovy
// main.nf
process RUN_PER_SAMPLE {
    tag "${sample_id}"
    executor 'pbs'
    // round-robin entre nós conhecidamente bons -- veja 04_problemas_comuns/ para entender o porquê
    clusterOptions { "-q workq -l select=1:ncpus=2:mem=4gb:host=${['pne3','pne4','pne6','pne7','pne10'][task.index % 5]}" }
    time '30m'
    container 'docker://quay.io/biocontainers/algumaferramenta:1.2.3--hdfd78af_2'
    errorStrategy 'retry'
    maxRetries 2

    input:
    tuple val(sample_id), path(input_file)

    output:
    path "${sample_id}.result", emit: result

    script:
    """
    algumaferramenta --input ${input_file} --output ${sample_id}.result
    """
}

workflow {
    samples_ch = Channel.fromPath('samples/*.fasta')
        .map { f -> [f.baseName, f] }

    RUN_PER_SAMPLE(samples_ch)
}
```

Rode com:

```bash
nextflow run main.nf -resume
```

`-resume` é o motivo pelo qual vale a pena aprender isso mesmo para um pipeline de
tamanho moderado: se a tarefa 400 de 500 falhar (um soluço num nó, um walltime curto
demais, o que for), corrigir o problema e rodar de novo com `-resume` continua
exatamente de onde parou, em vez de refazer as 399 tarefas que já tinham dado certo.

## Uma nota sobre errorStrategy

Use a forma **estática** (`errorStrategy 'retry'` + `maxRetries N`) em vez de um
closure dinâmico (`errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }`), a menos
que você tenha um motivo específico para precisar da forma dinâmica — a forma dinâmica
pode gerar seu próprio erro se uma tarefa falhar antes que seu contexto de execução
esteja totalmente inicializado (ex.: durante o preparo dos arquivos de entrada), o que
é um jeito confuso de falhar em cima do erro original que você já tinha.
