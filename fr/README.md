# PBS pour la bioinformatique : un cours pratique

> [!NOTE]
> **Traduction en cours.** Les sections **00** et **01** sont traduites et à jour avec le cours en anglais.
> Les sections **02 à 08** n'existent pour l'instant qu'[en anglais](../en/README.md) : les liens du parcours
> ci-dessous y mènent directement, et vous pouvez y continuer avec la même configuration (voir la fin de la
> [section 01](01_pbs_basics/README.md#la-suite--continuer-en-anglais)).

Apprenez à lancer de vraies analyses sur un cluster de calcul partagé avec PBS, en pratiquant. Chaque exercice est
un job que vous soumettez, qui tourne sur de vraies données de séquençage (ou simulées de façon réaliste) avec de
vrais outils, et que vous validez avec un vérificateur automatique.

**Pour qui :** biologistes, étudiants et analystes qui connaissent les bases de Linux (`cd`, `ls`, `nano`) et
viennent de recevoir un compte sur un cluster.
**Ce que vous saurez faire ensuite :** écrire et soumettre des scripts de job, choisir CPU/mémoire/temps à bon
escient, traiter de nombreux échantillons en parallèle, enchaîner des étapes en pipeline, lancer des outils depuis
des conteneurs, et comprendre pourquoi un job a échoué.
**Durée :** environ 6–8 heures au total ; chaque section tient debout seule (45–60 min) et s'appuie sur la précédente.

---

## Pourquoi un cours ? La version en un paragraphe

Un cluster est partagé par beaucoup de monde. Vous vous connectez à un **nœud de connexion** pour préparer le
travail, et vous soumettez des **jobs** à un ordonnanceur (PBS), qui les lance sur des **nœuds de calcul** quand
des ressources sont libres. Les analyses qui demandent du vrai CPU ou de la vraie mémoire vont dans des jobs, jamais
sur le nœud de connexion. Cette seule règle, plus une poignée de commandes (`qsub`, `qstat`, `qdel`), couvre 90 %
de l'usage quotidien. Le reste du cours, ce sont les 10 % restants : le faire efficacement, et réparer quand ça casse.

## Le parcours

| # | Section | Vous allez | Données / outils | Traduction |
|---|---|---|---|---|
| 00 | [Premiers pas](00_getting_started/README.md) | vous connecter, lancer l'installation, soumettre votre premier job | référence SARS-CoV-2 + vraies lectures | ✅ à jour |
| 01 | [Les bases de PBS](01_pbs_basics/README.md) | écrire, soumettre, suivre et déboguer un job | zcat, awk | ✅ à jour |
| 02 | [Conteneurs](../en/02_containers/README.md) | lancer des outils de bioinformatique sans les installer | seqkit, FastQC | ⏳ anglais seulement |
| 03 | [Ressources et threads](../en/03_resources_threads/README.md) | mesurer un job et demander les bons CPU, mémoire et temps | minimap2, samtools | ⏳ anglais seulement |
| 04 | [Job arrays](../en/04_job_arrays/README.md) | un job par échantillon, relancer seulement les échecs | fastp, seqkit | ⏳ anglais seulement |
| 05 | [Pipelines et dépendances](../en/05_pipelines_dependencies/README.md) | enchaîner QC → alignement → résumé | fastp, minimap2, samtools | ⏳ anglais seulement |
| 06 | [Jobs interactifs et nœuds](../en/06_interactive_and_nodes/README.md) | tester en direct sur un nœud de calcul, lire l'état des nœuds | pbsnodes | ⏳ anglais seulement |
| 07 | [Dépannage](../en/07_troubleshooting/README.md) | diagnostiquer six jobs cassés | logs, qstat | ⏳ anglais seulement |
| 08 | [Nextflow](../en/08_nextflow/README.md) (facultatif) | lancer et étendre un pipeline de gestionnaire de workflows | Nextflow | ⏳ anglais seulement |

Faites la 00 d'abord, puis 01–05 dans l'ordre. La 06 et la 07 peuvent se faire à tout moment après la 01. La 08 est facultative.

## Ce qu'il vous faut

- Un compte sur un cluster PBS (OpenPBS ou PBS Professional) et un terminal avec `ssh`.
- `git` (ou un autre moyen de copier ce dossier sur le cluster), `bash`.
- Apptainer ou Singularity sur le cluster (courant sur les clusters académiques ; le script d'installation vous
  prévient s'il manque).
- Environ 1 Go de disque dans un répertoire visible par les nœuds de calcul, et un accès internet depuis le nœud
  de connexion pour les téléchargements initiaux.

Vous n'avez **pas** besoin de droits administrateur, d'outils de bioinformatique installés, ni d'expérience
préalable avec un ordonnanceur.

## Comment marche chaque section

1. Lisez le `README.md` de la section (objectifs, notions, tableau « en cas de problème »).
2. Lancez les **exemples** (`example_*.pbs`) : ils marchent tels quels. Lisez leurs commentaires.
3. Faites les **exercices** : `exercise_*.pbs` (compléter des trous, réparer un job cassé, ou en écrire un de zéro).
4. Lancez le **vérificateur** de la section (`check_*.sh`). Il examine les vraies sorties de vos jobs et vous dit
   ce qui ne va pas et où regarder. Les vérificateurs ne modifient jamais rien.
5. Comparez avec `solutions/` seulement après avoir essayé.

**Conventions à retenir**
- Soumettez les jobs **depuis le répertoire de la section** : `cd 01_pbs_basics; qsub example_count_reads.pbs`.
- Les particularités de votre cluster sont dans `site.conf` (écrit par `00_getting_started/setup.sh`). Aucun
  script ne fige une file, un nœud ou un chemin. Voir `examples/site.pne.conf` pour un exemple rempli.
- `lib/edu.sh` regroupe de petites fonctions partagées (courtes, lisibles, à lire).
- Les logs des jobs apparaissent dans le répertoire de soumission, sous le nom `<nomdujob>.o<jobid>`, à la fin du job.
- Les fichiers de résultat créés par vos jobs vont dans `$WORKDIR` (de `site.conf`), un sous-dossier par section.
  Dans chaque répertoire de section, **`results/`** est un raccourci vers ce dossier (créé automatiquement) :
  `ls results/`. `$WORKDIR` lui-même n'est défini qu'après `source lib/edu.sh`.
- Les noms de fichiers et de dossiers sont les mêmes que dans la version anglaise, pour que les commandes soient
  identiques dans les deux.

## En plus

- [Aide-mémoire](../en/CHEATSHEET.md) (en anglais) : les commandes et l'anatomie d'un script sur une page.
- [Glossaire](../en/GLOSSARY.md) (en anglais) : tous les termes utilisés, en langage simple.

## Notes pour les formateurs et mainteneurs

- La version anglaise (`../en/`) fait référence ; ce dossier traduit les commentaires, messages et textes, sans
  changer le comportement des scripts.
- Les vérificateurs calculent les valeurs attendues à partir des données elles-mêmes (rien n'est figé pour un jeu
  de données).
- Données : le génome de référence et les 100 vraies paires de lectures viennent des test-datasets publics de
  nf-core (sommes de contrôle dans `00_getting_started/data.sha256`) ; les échantillons plus gros sont simulés avec
  `wgsim` par un job.
- Les versions des conteneurs sont épinglées dans `containers.conf`.
- `../en/tests/lint.sh fr` lance les vérifications statiques sur ce dossier (pas besoin de cluster).
