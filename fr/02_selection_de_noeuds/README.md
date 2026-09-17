# 02 — Vérifier la disponibilité des nœuds et y fixer son job

Par défaut, PBS choisit lui-même quel nœud de calcul exécute votre job, selon ce qui
est libre. C'est généralement suffisant. Deux situations sur ce cluster où il vaut
mieux vérifier et fixer explicitement plutôt que de faire confiance au comportement
par défaut :

1. **Un nœud est occupé par le job de quelqu'un d'autre.** Si vous demandez plus de
   ressources que ce qui est actuellement libre où que ce soit, votre job reste en
   attente (`Q`) au lieu de s'exécuter, même si *d'autres* nœuds sont complètement
   inactifs — PBS n'essaie pas automatiquement un autre nœud en cours de route comme le
   font certains autres ordonnanceurs. Vérifier d'abord vous évite de vous demander
   pourquoi un job qui devrait prendre 5 minutes est en attente depuis une heure.
2. **Un nœud spécifique a un problème connu.** Au moment de la rédaction, l'un des
   nœuds de calcul ne dispose pas d'un logiciel (Apptainer) dont la plupart des
   pipelines réels ont besoin — un job qui y atterrit échoue immédiatement et de façon
   déroutante. Éviter ce nœud connu comme problématique évite ce cas.
   **Particularité spécifique à ce cluster :** cette configuration PBS ne supporte pas
   l'*exclusion* d'un nœud (la syntaxe `host!=pne5` échoue avec "Illegal attribute or
   resource value") — vous ne pouvez que vous fixer *sur* un nœud spécifique. La
   solution consiste donc à lister explicitement uniquement les bons nœuds et à en
   choisir un vous-même.

## Vérifier ce qui est libre

```bash
pbsnodes pne3        # remplacez pne3 par le nom de n'importe quel nœud de calcul
```

Cherchez deux choses dans la sortie : `state = free` (par opposition à
`busy`/`down`/`offline`), et si une ligne `jobs = ...` est présente (si elle est absente
ou vide, rien n'y tourne actuellement). Un nœud peut afficher `state = free` tout en
ayant déjà des jobs en cours d'exécution si tous ses CPU ne sont pas encore utilisés —
vérifiez la ligne `jobs`, pas seulement `state`.

Pour vérifier plusieurs nœuds à la fois :

```bash
for n in pne3 pne4 pne6 pne7 pne10; do
    echo -n "$n: "
    pbsnodes $n | grep -i '^ *jobs' || echo 'libre'
done
```

(Demandez à la personne qui administre le cluster la liste complète actuelle des noms
de nœuds de calcul et lesquels, le cas échéant, ont des problèmes connus en ce
moment — les noms de nœuds spécifiques et les problèmes évolueront avec le temps, ce
guide ne se mettra pas à jour tout seul.)

## Fixer son job sur un nœud spécifique

Ajoutez `host=<nom_du_nœud>` dans la demande de ressources `select` :

```bash
#PBS -l select=1:ncpus=4:mem=8gb:host=pne3
```

## Un motif à connaître : le round-robin entre plusieurs bons nœuds

Si vous soumettez de nombreux petits jobs indépendants (courant avec des outils comme
Nextflow, qui répartissent un pipeline en de nombreuses tâches parallèles), fixer tout
le monde sur le *même* nœud gaspille les autres nœuds libres. Un round-robin simple —
parcourant une liste de nœuds connus comme bons selon l'indice de la tâche — répartit
la charge sans dépendre du placement automatique de PBS lui-même (qui, sur cette
configuration, est parfois peu fiable). Voir `05_nextflow_avance/` pour un exemple
réel de ce motif dans une directive `clusterOptions` de Nextflow.

## Essayez

`check_free_nodes.sh` est une version prête à l'emploi de la boucle ci-dessus — essayez-
la maintenant pour voir l'état actuel du cluster. Faites ensuite
`exercise_02_pin_to_free_node.pbs` : vérifiez vous-même quels nœuds sont libres,
remplissez le nom du nœud, et soumettez.
