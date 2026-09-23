# 00 · Premiers pas

**Vous allez apprendre :** ce qu'est un cluster, comment faire tourner ce cours sur le vôtre, et comment prouver que ça marche.
**Durée :** 20–30 minutes (surtout de l'attente : téléchargements et un petit job).
**Il vous faut :** un compte sur un cluster PBS et un terminal. Des bases de shell (`cd`, `ls`, `cat`, éditer un fichier avec `nano` ou `vim`).

---

## 1. Le modèle mental en 2 minutes

Un **cluster** est un groupe d'ordinateurs (les « **nœuds** ») qui partagent un stockage, gérés par un **ordonnanceur**. PBS est cet ordonnanceur.

```
   vous ──ssh──▶  nœud de connexion ──qsub──▶  ordonnanceur (PBS) ──▶ nœud de calcul 1
                  (partagé, travail                              ├─▶ nœud de calcul 2
                   léger seulement)                              └─▶ nœud de calcul …
                        └──── système de fichiers partagé : tout le monde voit les mêmes fichiers ────┘
```

| Lieu | Ce que vous y faites | Ce que vous ne devez pas y faire |
|---|---|---|
| **Nœud de connexion** (login) | vous connecter, éditer des fichiers, soumettre et suivre des jobs, déplacer des données | lancer des analyses. Il est partagé par tous ; une commande lourde ralentit tous vos collègues |
| **Nœuds de calcul** | les *jobs* tournent ici, lancés pour vous par PBS | vous y connecter directement (vous y accédez via PBS) |

Un **job**, c'est simplement un script shell plus une demande : *« donnez-moi 4 CPU et 8 Go de mémoire pendant 2 heures au plus, puis lancez ceci. »* PBS met la demande en file d'attente, trouve un nœud avec de la place, y lance le script et garde sa sortie. C'est toute l'idée ; le reste du cours n'est que du détail par-dessus.

**Pourquoi la bioinformatique en a besoin :** aligner 100 échantillons, ou un échantillon contre un gros génome, demande plus de CPU et de mémoire qu'un portable n'en a, et vous voulez que ça continue de tourner après avoir fermé votre portable.

## 2. Se connecter et récupérer le matériel

```bash
ssh <votre-identifiant>@<adresse-du-noeud-de-connexion>   # demandez l'adresse à l'administration du cluster
git clone <url-de-ce-depot> PBS_edu                       # ou copiez le dossier avec : scp -r PBS_edu <vous>@<noeud-de-connexion>:~/
cd PBS_edu/fr
```

Déplacer des fichiers entre votre portable et le cluster :

```bash
scp results.tsv <vous>@<noeud-de-connexion>:~/                 # portable -> cluster
rsync -avP <vous>@<noeud-de-connexion>:~/results/ ./results/   # cluster -> portable, reprise possible
```

## 3. Installation (trois commandes et un job)

Lancez-les depuis `00_getting_started/` :

```bash
./setup.sh              # 1. découvre votre file d'attente, l'outil de conteneurs, et demande où stocker les données
./fetch_data.sh         # 2. télécharge un minuscule jeu de données réel (environ 60 Ko)
./pull_containers.sh    # 3. télécharge les outils de bioinformatique sous forme d'images de conteneur (quelques minutes)
qsub make_samples.pbs   # 4. VOTRE PREMIER JOB : simule 6 échantillons de lectures de séquençage
```

`qsub` affiche un **identifiant de job** comme `12345.monserveur`. Suivez-le avec `qstat -u $USER` : l'état `Q` (en file) devient `R` (en cours), puis le job disparaît (terminé). Ça prend une minute ou deux. Ensuite :

```bash
./check_env.sh          # vérifie tout, y compris un job de test de 10 secondes sur un nœud de calcul
```

Vous voulez voir `Toutes les vérifications sont passées.` à la fin.

### Qu'ont fait ces commandes ?

- **`setup.sh`** a écrit `../site.conf` : un petit fichier avec les particularités de votre cluster (nom de la file, emplacement des données, outil `apptainer` ou `singularity`). Tous les scripts du cours le lisent, donc *rien dans les exercices n'est figé pour un cluster précis*. Ouvrez-le et lisez-le.
- **`fetch_data.sh`** a téléchargé un génome SARS-CoV-2 de 29,8 kb et 100 vraies paires de lectures. Minuscules exprès : les sections 01 et 02 se terminent en quelques secondes.
- **`pull_containers.sh`** a téléchargé les outils (seqkit, FastQC, fastp, minimap2, samtools, wgsim) sous forme d'**images de conteneur**. Un conteneur emballe un programme avec tout ce dont il a besoin : rien à installer, et tout le monde utilise exactement les mêmes versions. La section 02 explique ça en détail.
- **`make_samples.pbs`** est un vrai job : il lance `wgsim` pour simuler 6 échantillons × 300 000 paires de lectures. Les sections 03–05 les utilisent parce qu'ils sont assez gros pour rendre visibles le CPU, la mémoire et le temps.

### Où atterrissent les choses

- Les **logs** de vos jobs (`make_samples.o12345`) : dans le répertoire depuis lequel vous avez soumis.
- **Données, images, résultats :** dans les répertoires définis dans `site.conf` (`DATA_DIR`, `SIF_CACHE`, `WORKDIR`). Pour utiliser ces noms dans votre propre shell, chargez d'abord le fichier de fonctions : `source ../lib/edu.sh; echo $DATA_DIR`.
- Dans toutes les sections suivantes, `results/` dans le répertoire de la section est un raccourci vers son dossier de sortie.

## 4. Le FASTQ en 60 secondes

Les séquenceurs produisent des fichiers **FASTQ** : 4 lignes par lecture.

```
@read_1              <- nom
GATTTGGGGTTCAAAGCAG  <- la séquence d'ADN
+
IIIIIIIIIIIIIIIIIII  <- un score de qualité par base (I = très bon)
```

Le séquençage paired-end donne deux fichiers par échantillon (`_R1`, `_R2`) ; la lecture *n* de l'un va avec la lecture *n* de l'autre. `.gz` signifie compressé avec gzip ; lisez-le avec `zcat fichier.fastq.gz | head`. Un **génome de référence** est un fichier FASTA (une ligne `>nom`, puis la séquence). *Aligner* des lectures sur une référence (section 03) est l'étape lourde classique qui justifie les clusters.

## En cas de problème

| Symptôme | Cause probable et solution |
|---|---|
| `qsub: command not found` | Vous n'êtes pas sur le nœud de connexion, ou PBS demande un `module load`. Demandez à l'administration / essayez `module avail pbs`. |
| `qsub: ... queue ... required` ou « no default queue » | Mettez le nom de la file dans `EDU_QUEUE` dans `site.conf` (`qstat -Q` liste les files) et utilisez `edu_qsub` ou `qsub -q <file>`. |
| `apptainer: command not found` | Essayez `module avail apptainer` (ou `singularity`) puis `module load` ; ou lancez `pull_containers.sh` comme job (`qsub pull_containers.sh`). |
| Le téléchargement d'image échoue / expire | Le nœud n'a peut-être pas internet, ou il faut un proxy. Demandez à l'administration ; les images peuvent être téléchargées ailleurs puis copiées dans `sif/` sous le nom `<outil>.sif`. |
| Le job `make_samples` reste en `Q` | Le cluster est chargé. `qstat -f <jobid> \| grep -i comment` dit pourquoi. |
| `check_env.sh` dit que le job de test a échoué | Lisez le log qu'il affiche. Cause typique : `DATA_DIR` est sur un disque que les nœuds de calcul ne voient pas. Relancez `setup.sh` avec un répertoire partagé. |
| `No space left` / erreurs de quota | Indiquez à l'installation un espace plus grand, ou baissez `READS_PER_SAMPLE` dans `site.conf`. |

Prêt ? Passez à [01 · Les bases de PBS](../01_pbs_basics/README.md). Bloqué sur un mot ? Voir le [glossaire](../../en/GLOSSARY.md) (en anglais).
