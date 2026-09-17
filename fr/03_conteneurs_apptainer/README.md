# 03 — Exécuter des logiciels avec des conteneurs Apptainer

Installer des outils de bioinformatique directement (via `conda`, `pip`, en compilant
depuis les sources...) se transforme souvent en bataille de résolution de dépendances,
et il est facile de se retrouver avec une version subtilement différente de l'outil par
rapport à un(e) collègue, ce qui complique la comparaison ou la reproduction des
résultats. L'option par défaut recommandée ici : exécuter l'outil depuis un conteneur
pré-construit.

## Pourquoi des conteneurs, et pourquoi figer une version exacte

[Biocontainers](https://biocontainers.pro/) publie un conteneur pour pratiquement
chaque outil courant de bioinformatique, construit et versionné automatiquement à
partir de Bioconda. Deux habitudes comptent :

1. **Figez le tag de version exact, n'utilisez pas `:latest`.** `:latest` change
   silencieusement avec le temps et casse la reproductibilité -- si vos résultats
   dépendent de la version X d'un outil et que quelqu'un relance votre pipeline six mois
   plus tard avec ce que `:latest` sera devenu entre-temps, il/elle peut obtenir des
   chiffres différents sans raison évidente.
2. **Récupérez le tag exact depuis une source fiable déjà vérifiée, ne devinez pas.**
   Une bonne méthode : regardez comment un framework de pipeline déjà établi
   ([nf-core/modules](https://github.com/nf-core/modules)) fige le même outil — leurs
   définitions de module listent la chaîne exacte
   `quay.io/biocontainers/<outil>:<version>`, qui est un pin réel et testé, pas une
   supposition.

## Récupérer et exécuter un job avec conteneur

```bash
apptainer pull --force monoutil.sif docker://quay.io/biocontainers/monoutil:1.2.3--hdfd78af_2
apptainer exec monoutil.sif monoutil --version
```

`apptainer pull` télécharge et convertit l'image une fois ; ensuite,
`apptainer exec monoutil.sif <commande>` exécute n'importe quoi à l'intérieur comme si
c'était installé localement. Faites le pull une fois (idéalement vers un stockage
partagé, pas quelque chose qui serait re-téléchargé à chaque job) et réutilisez le
fichier `.sif` d'un job à l'autre.

## Le piège qui vous attend : les points de montage (bind mounts)

Un conteneur ne voit que les parties du système de fichiers explicitement (ou par
défaut) "montées" (bind-mounted) à l'intérieur. Apptainer monte automatiquement votre
répertoire personnel et le répertoire de travail actuel par défaut, mais **ne monte pas
de façon fiable des chemins absolus arbitraires** ailleurs sur le stockage partagé,
simplement parce que vous pouvez les voir depuis votre shell de connexion.

Concrètement : si le script de votre job fait ceci --

```bash
apptainer exec monoutil.sif monoutil -i /data2/projects/AUTRE-PROJET/entree.txt
```

-- et que ce chemin n'est pas couvert par un montage automatique, `monoutil` échouera
avec quelque chose comme "No such file or directory" pour un fichier qui existe
pourtant bel et bien et que *vous* pouvez afficher sans problème avec `cat` depuis le
même shell. C'est vraiment déroutant la première fois, car l'erreur ressemble à un
problème de fichier manquant alors que le fichier est juste là.

**La solution fiable : faites un `cd` vers le répertoire de travail de votre propre job
(dans la zone montée automatiquement) et copiez-y d'abord vos entrées**, puis
référencez-les avec des chemins relatifs :

```bash
cd /data2/projects/VOTRE-PROJET/results/mon_job   # un endroit où vous avez un vrai répertoire de travail
cp /data2/projects/AUTRE-PROJET/entree.txt .
apptainer exec monoutil.sif monoutil -i entree.txt   # chemin relatif, fonctionne toujours
```

Cela coûte un peu d'I/O disque pour la copie, mais c'est la différence entre un job qui
fonctionne à chaque fois et un job qui échoue mystérieusement selon exactement quels
chemins il touche.

## Essayez

`example_container_job.pbs` télécharge un petit conteneur public rapide et y exécute
une commande triviale — soumettez-le tel quel en premier. Ensuite
`exercise_03_run_a_tool.pbs` vous demande de télécharger le conteneur d'un véritable
outil de bioinformatique et de vérifier sa version, en remplissant vous-même le tag du
conteneur (cherchez sur nf-core/modules ou biocontainers.pro, ne devinez pas).
