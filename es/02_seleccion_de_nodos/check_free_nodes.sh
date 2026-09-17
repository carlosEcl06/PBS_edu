#!/bin/bash
# Imprime el estado actual de cada nodo de cómputo nombrado. Edita la lista
# NODES de abajo para que coincida con los nombres reales de los nodos de
# cómputo de este clúster (pregunta a un(a) colega o a quien administre el
# clúster si no estás seguro(a)) -- esto no es algo detectable de forma
# automática y confiable desde el nodo de acceso.

NODES=(pne3 pne4 pne6 pne7 pne10)

for n in "${NODES[@]}"; do
    echo "--- $n ---"
    pbsnodes "$n" 2>&1 | grep -i 'state\|jobs ='
    echo
done
