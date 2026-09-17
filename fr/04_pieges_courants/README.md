# 04 — Vrais pièges rencontrés sur ce cluster (et comment ils ont été diagnostiqués)

Les tutoriels PBS génériques s'arrêtent généralement à "voici comment soumettre un
job." Voici de vrais problèmes, rencontrés en construisant un véritable pipeline sur ce
serveur exact, avec le raisonnement qui a mené à chaque solution — car c'est le
raisonnement qui est réutilisable, pas la solution spécifique.

## 1. Un nœud de calcul silencieusement dépourvu d'un logiciel requis

**Symptôme :** un pipeline répartissant environ 550 jobs quasi identiques sur
plusieurs nœuds de calcul s'est bien déroulé pour les premières centaines, puis a
commencé à échouer avec `apptainer: No such file or directory` (code de sortie 127)
sur un sous-ensemble de tâches, sans motif évident rien qu'avec le message d'erreur.

**Mauvais réflexe :** simplement relancer les tâches échouées en espérant que
c'était un incident passager.

**Ce qui a vraiment fonctionné :** soumettre quelques petits jobs de diagnostic, chacun
fixé sur exactement un nœud candidat (`host=pneN`), chacun vérifiant simplement
`ls /usr/bin/apptainer`. Cela a isolé le problème à un seul nœud qui, pour une raison
quelconque, n'avait pas du tout le binaire Apptainer — tous les autres nœuds
l'avaient.

**La solution :** comme cette configuration PBS ne supporte pas l'*exclusion* d'un
nœud (`host!=pneN` échoue directement), la solution a consisté à lister explicitement
les bons nœuds connus et à alterner entre eux en round-robin :

```groovy
// exemple : dans le clusterOptions d'un process Nextflow
def good_nodes = ['pne3', 'pne4', 'pne6', 'pne7', 'pne10']
clusterOptions { "-l select=1:ncpus=2:mem=4gb:host=${good_nodes[task.index % good_nodes.size()]}" }
```

**La leçon :** quand un lot de jobs échoue de façon incohérente (certains nœuds, pas
d'autres), ne devinez pas et ne relancez pas — écrivez la plus petite reproduction
possible (un job, un nœud, une vérification) pour chaque suspect et laissez les preuves
vous dire lequel c'est.

## 2. Un conteneur ne voit pas un fichier pourtant juste là

**Symptôme :** un job appelant
`apptainer exec unoutil.sif ... /data2/chemin/vers/entree.gff` a échoué avec
`FileNotFoundError`, alors que `cat /data2/chemin/vers/entree.gff` depuis un shell
interactif fonctionnait très bien, et que le fichier était confirmé comme existant avec
`ls`.

**Mauvais réflexe :** supposer que l'étape de copie/transfert de fichier précédente
dans le pipeline avait été incomplète ou corrompue d'une manière ou d'une autre, et la
relancer.

**Ce qui a vraiment fonctionné :** lire le code source de l'outil qui échouait
(open source — le traceback pointait vers une ligne précise) a confirmé qu'il faisait
bien un `open(chemin)` simple exactement sur le chemin transmis. Cela a écarté un bug
dans l'outil lui-même et a orienté vers la frontière du conteneur : le comportement de
montage par défaut d'Apptainer ne garantit pas que des chemins absolus arbitraires sur
le stockage partagé soient visibles à l'intérieur du conteneur, seulement le
répertoire personnel et le répertoire de travail actuel.

**La solution :** faire un `cd` vers le répertoire de travail du job lui-même d'abord,
puis `cp` pour copier les entrées nécessaires là, et enfin les référencer par chemin
relatif plutôt que par le chemin absolu d'origine. (Explication complète et exemple
dans `03_conteneurs_apptainer/README.md`.)

**La leçon :** "le fichier n'existe pas" depuis l'intérieur d'un job en conteneur ne
signifie pas toujours que le fichier n'existe pas — vérifiez s'il s'agit d'un problème
de bind mount avant de supposer un problème de données, surtout si le même chemin
fonctionne très bien en dehors du conteneur.

## 3. Un outil qui échoue sur de vraies données biologiques n'est pas toujours un bug

**Symptôme :** un outil d'analyse de pangénome a planté au milieu d'un vrai jeu de
données avec `ValueError: Invalid gene sequence!` sur certains des génomes en entrée.

**Mauvais réflexe :** supposer que les fichiers d'entrée étaient mal formés et
commencer à les redériver.

**Ce qui a vraiment fonctionné :** lire la logique de validation de l'outil lui-même
a montré qu'il rejetait les gènes avec des codons stop internes, des longueurs non
multiples de 3, ou des décalages de cadre de lecture — exactement le type d'annotation
qu'on attend de vrais pseudogènes dans un génome, pas nécessairement un signe d'entrée
corrompue. La sortie `--help` de l'outil lui-même listait une option
(`--remove-invalid-genes`) spécifiquement pour cette situation.

**La solution :** utiliser l'option que l'outil fournit lui-même pour cela — elle
existe parce que les vraies données biologiques en contiennent légitimement, pas comme
contournement d'un bug de données.

**La leçon :** avant de supposer que votre entrée est corrompue, vérifiez si l'outil a
une option documentée exactement pour l'échec que vous observez — une option prévue
spécifiquement pour cela est un signal bien plus fort qu'un `try/except` générique que
l'échec est attendu, pas un bug.

## 4. Ne jamais, même brièvement, calculer sur le nœud de connexion

**Symptôme :** aucun, en fait — c'est une note de discipline, pas une histoire de
débogage. Mais il vaut la peine de le dire clairement : il est très facile, en pleine
session de débogage, d'exécuter "juste une commande rapide" directement via SSH sur le
nœud de connexion au lieu de l'envelopper dans un job PBS, surtout pour quelque chose
qui semble trivialement peu coûteux (vérifier la sortie `--help` d'un outil, par
exemple). Cela s'est produit une fois en construisant le pipeline dont ce guide est
tiré — repéré en moins d'une minute, le processus égaré a été tué, sans dommage
durable, mais cela n'aurait pas dû arriver du tout.

**L'habitude à construire :** si une commande doit exécuter *quoi que ce soit* au-delà
d'un script shell trivial (tout vrai programme, tout conteneur, tout véritable calcul),
elle passe par `qsub`, point final — même pour quelque chose qui semble prendre deux
secondes. Le nœud de connexion est un espace d'orchestration partagé par tout le
monde ; traitez-le ainsi de façon constante, pas seulement quand c'est pratique.
