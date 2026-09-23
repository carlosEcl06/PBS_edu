# 01 · Les bases de PBS

**Vous allez apprendre :** écrire, soumettre, suivre et déboguer un job.
**Durée :** 45 minutes.
**Avant de commencer :** vous avez terminé [00 · Premiers pas](../00_getting_started/README.md) (`check_env.sh` passe).
**Pourquoi c'est important en bioinformatique :** chaque étape suivante, qu'il s'agisse de trimming, d'alignement ou d'appel de variants, c'est « un script plus une demande de ressources ». Maîtrisez ceci, et le reste consiste juste à changer la commande à l'intérieur.

> **Convention utilisée dans tout le cours :** soumettez les jobs *depuis le répertoire de la section* (`cd 01_pbs_basics; qsub quelquechose.pbs`). Les scripts utilisent `source ../lib/edu.sh` et le trouvent grâce au répertoire depuis lequel vous avez soumis.

---

## 1. Anatomie d'un script de job

Un script de job est un script shell ordinaire avec, en haut, des lignes de commentaire spéciales qui commencent par `#PBS`. `qsub` les lit comme des options ; le shell les ignore comme des commentaires.

```bash
#!/bin/bash
#PBS -N count_reads
#PBS -l select=1:ncpus=1:mem=1gb
#PBS -l walltime=00:05:00
#PBS -j oe

cd "$PBS_O_WORKDIR" || exit 1
echo "hello from $(hostname)"
```

| Ligne | Signification |
|---|---|
| `-N count_reads` | **nom** du job, affiché par `qstat` et utilisé pour nommer les fichiers de log. Commencez par une lettre, pas d'espaces. |
| `-l select=1:ncpus=1:mem=1gb` | la **demande de ressources** : 1 *chunk* (un lot de ressources placé sur un seul nœud) avec 1 cœur CPU et 1 Go de mémoire. |
| `-l walltime=00:05:00` | durée d'exécution maximale, `HH:MM:SS`. **PBS tue le job quand elle est écoulée**, quoi qu'il soit en train de faire. |
| `-j oe` | **j**oint stderr (**e**) à stdout (**o**) : un fichier de log au lieu de deux. |
| `cd "$PBS_O_WORKDIR"` | les jobs **démarrent dans votre home**, pas là où vous avez lancé `qsub`. Cette ligne y retourne. L'oublier est l'erreur classique du débutant. |

Facultatif mais utile : `-o <fichier>` / `-e <fichier>` nomment les fichiers de log (par défaut : `<nom>.o<jobid>` et `<nom>.e<jobid>`, créés dans le répertoire depuis lequel vous avez soumis).

**Commentaires sur les lignes `#PBS` :** mettez-les sur leur propre ligne, jamais après l'option (`#PBS -N x   # mon job`). Certaines versions de PBS lisent le reste de la ligne comme faisant partie de l'option et échouent de façon déroutante. Tous les scripts ici suivent cette règle.

**Choisir les nombres :** ne devinez pas au hasard. Demandez un peu plus que ce dont le job a besoin : trop peu et il est tué ; trop et il attend plus longtemps dans la file et gaspille des ressources partagées. La section 03 montre comment mesurer.

## 2. Soumettre et surveiller

```bash
qsub example_hello_world.pbs      # affiche un identifiant de job, ex. 12345.monserveur
qstat -u $USER                    # vos jobs. Regardez la colonne S (état)
qstat -f 12345                    # tout sur un job
qdel 12345                        # l'annuler
qstat -x -u $USER                 # inclut les jobs TERMINÉS (si le site garde l'historique)
qstat -xf 12345                   # détails complets d'un job terminé : Exit_status, resources_used
```

États : **Q** en file · **R** en cours · **H** retenu · **E** en sortie · **F** terminé (visible seulement avec `-x`).

Quand le job se termine, PBS écrit `hello.o12345` dans votre répertoire de soumission. Lisez-le avec `cat`. **Le log n'apparaît qu'à la fin du job**, pas pendant qu'il tourne, donc le fichier `.o` d'un job en cours peut ne pas exister encore. C'est normal. Pour les longs jobs, écrivez la progression dans votre propre fichier de log sur le système de fichiers partagé.

> **Où vont mes fichiers de sortie ?** À deux endroits différents, exprès :
> - le **log** (`count_reads.o12345`) est écrit par PBS dans le répertoire depuis lequel vous avez soumis ;
> - les **fichiers de résultat** créés par votre script vont dans votre espace de sortie, `$WORKDIR` de `site.conf`, dans un sous-dossier par section. Dans chaque répertoire de section, **`results/`** est un raccourci vers ce dossier (il est créé la première fois qu'un job ou un vérificateur tourne) : `ls results/`, `cat results/fastq_counts.tsv`.
>
> Vous voulez le vrai chemin ? `source ../lib/edu.sh; echo $WORKDIR`. (`$WORKDIR` n'est pas défini dans votre shell de connexion tant que vous n'avez pas fait `source` sur ce fichier.)

## 3. Essayez

```bash
cd 01_pbs_basics
qsub example_hello_world.pbs
qstat -u $USER            # répétez jusqu'à ce que le job disparaisse
cat hello.o*              # remarquez « Répertoire au démarrage du job »
qsub example_count_reads.pbs
```

`example_hello_world.pbs` affiche où le job a démarré (votre home !) et où il est allé après le `cd`. `example_count_reads.pbs` est votre premier job de bioinformatique : il compte les lectures et les bases des deux vrais fichiers FASTQ avec `zcat` et `awk`. Lisez-le, puis regardez son résultat : le tableau est aussi enregistré dans un fichier, `results/fastq_counts.tsv` (voir l'encadré ci-dessus : `results/` est l'endroit où vont les fichiers de sortie de tous vos jobs).

**Questions auxquelles répondre à partir des logs** (inutile de les écrire quelque part) :
1. Sur quel nœud votre job a-t-il tourné ? Est-ce le nœud de connexion ?
2. Qu'a dit `qstat -xf <jobid>` pour `Exit_status`, `resources_used.walltime` et `resources_used.mem` ?
3. Combien de CPU le job pense-t-il avoir ? (`NCPUS`)

## 4. Exercices

Chaque exercice a un **vérificateur** qui examine la vraie sortie de votre job et vous dit ce qui ne va pas. Les solutions sont dans `solutions/` : n'y jetez un œil qu'après avoir essayé.

### 1a · Complétez les trous (10 min)
Modifiez `exercise_01a_fill_in_blanks.pbs` en remplaçant chaque `___`. Soumettez-le, attendez qu'il se termine, puis `./check_01a.sh`.

### 1b · Réparez le job cassé (15 min)
`exercise_01b_fix_the_job.pbs` contient trois bugs distincts qui apparaissent l'un après l'autre : un à la soumission, un au démarrage du job, un pendant son exécution. Soumettez, lisez ce qui s'est mal passé, corrigez un bug, recommencez. Puis `./check_01b.sh`.

### 1c · Écrivez un job de zéro (15 min)
Écrivez vous-même `my_reference_stats.pbs`. Exigences :

- 1 CPU, 1 Go, 5 minutes, un nom de votre choix, logs fusionnés.
- Lisez `$DATA_DIR/ref/genome.fasta` (le génome de référence) et écrivez `reference_stats.txt` dans `$WORKDIR/01_pbs_basics/` (c'est-à-dire `results/` depuis ce répertoire) avec exactement ces cinq lignes (les clés restent en anglais : c'est ce que cherche le vérificateur) :

  ```
  sequences: <nombre d'enregistrements FASTA>
  length: <nombre total de bases>
  gc_percent: <pourcentage de G et C, 2 décimales>
  job_id: <$PBS_JOBID>
  host: <sortie de hostname, depuis l'intérieur du job>
  ```
- Indice : les lignes d'en-tête commencent par `>` ; `awk` sait compter les caractères ; `gsub(/[GC]/, "")` renvoie le nombre de remplacements. `printf "%.2f"` affiche deux décimales.

Puis `./check_01c.sh`. Le taux de GC est une vraie métrique : il varie selon les organismes et aide à repérer une contamination.

## Faites le point

Vous avez fini quand vous pouvez répondre « oui » à tout ceci :
- [ ] Je sais expliquer pourquoi mon job a besoin de `cd "$PBS_O_WORKDIR"`.
- [ ] Je sais ce qui se passe quand un job dépasse son walltime, et où le voir (`Exit_status`).
- [ ] Je sais trouver le log d'un job terminé et le nœud sur lequel il a tourné.
- [ ] `check_01a.sh`, `check_01b.sh`, `check_01c.sh` passent.

## En cas de problème

| Ce que vous voyez | Que faire |
|---|---|
| `qsub: Unknown resource ...` / `Illegal attribute or resource value` | Une ligne `#PBS` contient une faute de frappe (`ncpu` au lieu de `ncpus`, `gb` manquant, trou laissé en `___`). |
| Le job reste en `Q` longtemps | Le cluster est chargé ou vous avez demandé plus que ce qu'a n'importe quel nœud. `qstat -f <id> \| grep -i comment`. |
| Pas encore de fichier `.o`, le job est en `R` | Normal : il apparaît à la fin. |
| Le log dit `No such file or directory` pour `../lib/edu.sh` | Vous avez oublié `cd "$PBS_O_WORKDIR"`, ou vous avez soumis depuis un autre répertoire que celui de la section. |
| Le log s'arrête net, `Exit_status = 271` | Tué par PBS, très probablement pour dépassement du walltime. |
| Le job s'est terminé mais les fichiers de résultat manquent | Lisez le log jusqu'au bout ; le script a probablement échoué en cours de route. |

## La suite : continuer en anglais

Les sections 02 à 08 ne sont pas encore traduites. Vous pouvez continuer dans la version anglaise en réutilisant tout ce que vous avez déjà configuré (données, images et résultats restent où ils sont, car `site.conf` contient des chemins absolus). Depuis le dossier `fr/` :

```bash
cp site.conf ../en/site.conf
cd ../en/02_containers
```

Suivant : [02 · Containers](../../en/02_containers/README.md) (en anglais)
