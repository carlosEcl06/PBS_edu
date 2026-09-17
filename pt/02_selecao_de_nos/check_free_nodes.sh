#!/bin/bash
# Imprime o estado atual de cada nó de computação nomeado. Edite a lista
# NODES abaixo para bater com os nomes reais dos nós de computação deste
# cluster (pergunte a um(a) colega ou a quem administra o cluster se não
# tiver certeza) -- isso não é algo detectável automaticamente e de forma
# confiável a partir do nó de login.

NODES=(pne3 pne4 pne6 pne7 pne10)

for n in "${NODES[@]}"; do
    echo "--- $n ---"
    pbsnodes "$n" 2>&1 | grep -i 'state\|jobs ='
    echo
done
