# 01 — Bases de PBS : soumettre, vérifier, annuler

PBS (ce cluster utilise OpenPBS) planifie votre job sur un nœud de calcul et l'y
exécute, au lieu du nœud sur lequel vous êtes connecté au moment de la soumission. Un
job PBS est simplement un script shell avec quelques lignes de commentaire spéciales
`#PBS` en en-tête, indiquant à l'ordonnanceur les ressources dont vous avez besoin.

## Les trois commandes que vous utiliserez constamment

```bash
qsub mon_job.pbs          # soumet un job, affiche son identifiant (ex. "3120.pne2")
qstat -u $(whoami)        # liste vos jobs et leur état
qdel 3120.pne2              # annule un job (en cours ou en attente)
```

États de job que vous verrez dans `qstat` : `Q` (en attente de ressources), `R` (en
cours d'exécution), et une fois terminé le job disparaît simplement de la liste par
défaut de `qstat` (utilisez `qstat -x 3120.pne2` pour voir les informations
comptables d'un job terminé, ou `qstat -xf` pour le détail complet, y compris son code
de sortie).

## Anatomie d'un script de job minimal

```bash
#!/bin/bash
#PBS -N mon_premier_job       # un nom pour le job (apparaît dans qstat)
#PBS -q workq                 # la file d'attente -- workq est celle par défaut ici
#PBS -l select=1:ncpus=1:mem=1gb   # 1 nœud, 1 CPU, 1 Go de RAM
#PBS -l walltime=00:05:00     # tue le job s'il tourne encore après 5 minutes
#PBS -o mon_job.out           # où va la sortie standard (écrite quand le job se termine)
#PBS -e mon_job.err           # où va la sortie d'erreur

echo "Bonjour depuis $(hostname), exécuté en tant que job $PBS_JOBID"
date
sleep 10
echo "Terminé."
```

Enregistrez ceci sous `mon_job.pbs` et soumettez-le avec `qsub mon_job.pbs`. Quelques
points à connaître avant de le faire :

- **`walltime` est une limite stricte.** Si votre job tourne encore une fois ce délai
  atteint, PBS le tue. Laissez toujours une vraie marge au-dessus de ce que vous pensez
  que le job prendra réellement — un job tué en cours de route peut laisser une sortie
  partielle/corrompue, ce qui est une bien pire expérience de débogage qu'un job qui
  finit simplement un peu tôt.
- **`-o`/`-e` ne sont généralement écrits qu'une fois le job terminé**, pas en flux
  continu, sur cette configuration PBS particulière. Ne vous inquiétez pas si le
  fichier de sortie n'existe pas encore alors que `qstat` affiche le job comme `R` —
  c'est normal ici, pas un signe de problème.
- **Le script s'exécute sur le nœud de calcul assigné par PBS**, en partant de
  l'endroit d'où `qsub` a été lancé comme contexte de répertoire de travail (les
  chemins dans votre script doivent généralement être absolus, ou vous devez faire un
  `cd` explicite d'abord, pour éviter toute ambiguïté).
- **Les lignes de directive `#PBS` ne supportent pas les commentaires en fin de
  ligne** sur cette configuration — `#PBS -l ncpus=2  # mon commentaire` échouera avec
  une `directive error`, car l'interpréteur traite tout ce qui suit `-l` comme du texte
  de directive, pas comme un commentaire shell à ignorer. Placez les commentaires
  explicatifs sur leur propre ligne, au-dessus de la directive. (Découvert la première
  fois en soumettant réellement les scripts d'exercice ci-dessous pour vérifier qu'ils
  fonctionnent — cela vaut la peine de le faire vous-même à chaque nouveau script, pas
  seulement de supposer qu'il est correct.)

## Essayez

Exécutez d'abord l'exemple fonctionnel, tel quel, pour voir le cycle complet
soumettre → attendre → vérifier :

```bash
qsub example_hello_world.pbs
qstat -u $(whoami)
# attendez quelques secondes, puis :
cat example_hello_world.out
```

Ensuite ouvrez `exercise_01_fill_in_blanks.pbs`, remplissez les blancs (marqués
`___`), et soumettez votre propre version. Si vous êtes bloqué(e),
`exercise_01_ANSWER.pbs` contient une solution complète — mais essayez d'abord par
vous-même, c'est le but.
