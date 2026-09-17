# 05 — Orchestrer des pipelines à plusieurs étapes avec Nextflow (optionnel, une fois les bases naturelles)

Enchaîner des `qsub` à la main (`qsub -W depend=afterok:$jobid ...`) fonctionne pour
une poignée d'étapes séquentielles, mais devient vite ingérable dès que vous avez de
nombreuses tâches indépendantes qui devraient s'exécuter en parallèle (ex. "lance cette
même analyse sur 500 échantillons") ou un pipeline avec plusieurs étapes dépendant
chacune de la précédente. Nextflow gère les deux nativement, soumet chaque tâche comme
son propre job PBS pour vous, et offre la reprise (`-resume`), de sorte qu'un pipeline
de plusieurs jours qui échoue en cours de route ne signifie pas repartir de zéro.

Cette section n'est pas un tutoriel Nextflow complet -- voir la
[documentation officielle](https://www.nextflow.io/docs/latest/index.html) pour cela.
C'est un exemple minimal et fonctionnel du motif spécifique qui compte sur *ce*
cluster : PBS + Apptainer ensemble.

## La configuration essentielle

```groovy
// nextflow.config
process.executor = 'pbs'
process.queue = 'workq'
apptainer.enabled = true
apptainer.autoMounts = true

// La vérification périodique de l'état de la file PBS de ce cluster a une
// particularité connue (une erreur "conflicting options" sur qstat -f -1)
// -- inoffensive, Nextflow se rabat sur son propre suivi par job via un
// fichier .exitcode, mais augmenter ces deux délais évite des échecs
// intempestifs sur les jobs longs où NFS peut accuser un léger retard :
executor.exitReadTimeout = '270 sec'
executor.pollInterval = '30 sec'
```

## Un process minimal en éventail (fan-out)

```groovy
// main.nf
process RUN_PER_SAMPLE {
    tag "${sample_id}"
    executor 'pbs'
    // round-robin entre nœuds connus comme bons -- voir 04_pieges_courants/ pour comprendre pourquoi
    clusterOptions { "-q workq -l select=1:ncpus=2:mem=4gb:host=${['pne3','pne4','pne6','pne7','pne10'][task.index % 5]}" }
    time '30m'
    container 'docker://quay.io/biocontainers/unoutil:1.2.3--hdfd78af_2'
    errorStrategy 'retry'
    maxRetries 2

    input:
    tuple val(sample_id), path(input_file)

    output:
    path "${sample_id}.result", emit: result

    script:
    """
    unoutil --input ${input_file} --output ${sample_id}.result
    """
}

workflow {
    samples_ch = Channel.fromPath('samples/*.fasta')
        .map { f -> [f.baseName, f] }

    RUN_PER_SAMPLE(samples_ch)
}
```

Exécutez avec :

```bash
nextflow run main.nf -resume
```

`-resume` est la raison pour laquelle cela vaut la peine d'être appris même pour un
pipeline de taille modérée : si la tâche 400 sur 500 échoue (un souci sur un nœud, un
walltime trop serré, peu importe), corriger le problème et relancer avec `-resume`
reprend exactement là où c'était arrêté, au lieu de refaire les 399 tâches déjà
réussies.

## Une remarque sur errorStrategy

Utilisez la forme **statique** (`errorStrategy 'retry'` + `maxRetries N`) plutôt qu'une
closure dynamique (`errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }`), sauf si
vous avez une raison spécifique de nécessiter la forme dynamique — la forme dynamique
peut générer sa propre erreur si une tâche échoue avant que son contexte d'exécution ne
soit entièrement initialisé (ex. pendant la préparation des fichiers d'entrée), ce qui
est un mode d'échec déroutant à déboguer par-dessus votre erreur d'origine.
