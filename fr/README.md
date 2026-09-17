# PBS_edu — ordonnancement de jobs sur ce cluster partagé

Un guide pratique pour exécuter des jobs de calcul sur ce serveur de la bonne manière :
via l'ordonnanceur PBS, jamais sur le nœud de connexion, avec des conteneurs figés à
des versions précises. Les exemples ici proviennent d'un véritable pipeline de
phylogénomique construit sur ce même serveur — y compris certains problèmes rencontrés
en cours de route.

## Pourquoi ce guide existe

Ceci est un serveur partagé, utilisé par plusieurs personnes en même temps. Le nœud de
connexion (`pne2`) sert à éditer des fichiers, soumettre des jobs et faire de
l'orchestration légère — **pas à exécuter quoi que ce soit qui utilise réellement du
CPU ou de la mémoire**. Les jobs de tout le monde passent par PBS, qui les répartit sur
les nœuds de calcul (`pne3` à `pne10`, disponibilité variable). Si vous exécutez votre
analyse directement sur `pne2` au lieu de la soumettre comme job, vous ne faites pas que
violer une règle — vous utilisez du CPU qui appartient au nœud partagé de
connexion/orchestration, dont tout le monde dépend (y compris ceux qui veulent juste
faire un `cd` et vérifier l'état de leur job).

La bonne nouvelle : une fois que vous l'avez fait deux ou trois fois, soumettre un job
PBS n'est pas plus difficile qu'exécuter une commande directement. Ce guide vous y
amène.

## Comment utiliser ce dossier

Parcourez les répertoires numérotés dans l'ordre. Chacun contient :
- un `README.md` expliquant le concept,
- un ou plusieurs **exemples fonctionnels** que vous pouvez soumettre tels quels pour
  voir à quoi ressemble un vrai job de bout en bout,
- un ou plusieurs **exercices** — le même type de script, mais avec des parties
  importantes laissées en blanc (`___`), à vous de les remplir et de les soumettre
  vous-même.

Rien ici ne touche aux vraies données du projet. Chaque exercice soumet un job trivial
(s'exécute en quelques secondes, utilise des ressources minimales) pour que vous
puissiez itérer rapidement sans vous soucier d'utiliser des ressources partagées
pendant que vous apprenez encore.

1. **`01_bases_pbs/`** — soumettre, vérifier et annuler un job. Commencez ici même si
   vous avez déjà utilisé PBS/Slurm ailleurs — les options et les particularités
   changent d'un cluster à l'autre.
2. **`02_selection_de_noeuds/`** — vérifier quels nœuds de calcul sont réellement libres, et
   y fixer explicitement votre job. Cela compte plus ici que sur certains autres
   clusters, pour des raisons expliquées dans cette section.
3. **`03_conteneurs_apptainer/`** — exécuter des logiciels à partir d'un conteneur au
   lieu de se battre avec la résolution de dépendances de `conda`/`module load`. C'est
   l'option par défaut recommandée pour tout outil qui n'est pas trivial à installer.
4. **`04_pieges_courants/`** — de vrais bugs rencontrés en construisant un pipeline de
   production sur ce serveur exact, présentés comme des leçons plutôt que laissés comme
   simple savoir tacite.
5. **`05_nextflow_avance/`** (optionnel, une fois les bases naturelles) — orchestrer
   un pipeline à plusieurs étapes (de nombreux jobs, des dépendances entre eux) avec
   l'exécuteur PBS de Nextflow au lieu d'enchaîner des `qsub` à la main.

## La version en un paragraphe, si vous ne lisez rien d'autre

N'exécutez jamais de vrai calcul sur `pne2`. Avant de soumettre un job, vérifiez quels
nœuds de calcul sont réellement libres (`pbsnodes <nœud>`) plutôt que de le supposer —
ce serveur ne permet pas toujours d'exclure un nœud spécifique, seulement de s'y fixer,
donc si vous ne vérifiez pas d'abord, vous pouvez rester bloqué en file d'attente
derrière le job de quelqu'un d'autre, ou être silencieusement placé sur un nœud ayant un
problème connu. Préférez les conteneurs Apptainer figés à une version exacte plutôt que
`conda`/les paquets système pour tout ce qui dépasse un script d'une ligne. Et quand un
job basé sur un conteneur ne trouve pas un fichier visible depuis votre shell de
connexion, vérifiez si le chemin est réellement monté (bind-mount) dans le conteneur
avant de supposer que vos données ont disparu — voir `04_pieges_courants/`.
