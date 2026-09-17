#!/bin/bash
# Affiche l'état actuel de chaque nœud de calcul nommé. Modifiez la liste
# NODES ci-dessous pour qu'elle corresponde aux noms réels des nœuds de
# calcul de ce cluster (demandez à un(e) collègue ou à l'administrateur·rice
# du cluster si vous n'êtes pas sûr·e) -- ce n'est pas quelque chose de
# détectable automatiquement et de façon fiable depuis le nœud de connexion.

NODES=(pne3 pne4 pne6 pne7 pne10)

for n in "${NODES[@]}"; do
    echo "--- $n ---"
    pbsnodes "$n" 2>&1 | grep -i 'state\|jobs ='
    echo
done
