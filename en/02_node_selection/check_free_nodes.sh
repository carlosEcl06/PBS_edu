#!/bin/bash
# Prints the current state of each named compute node. Edit the NODES list
# below to match this cluster's actual compute node names (ask a labmate or
# whoever maintains the cluster if you're not sure) -- this isn't something
# that can be auto-detected reliably from the login node.

NODES=(pne3 pne4 pne6 pne7 pne10)

for n in "${NODES[@]}"; do
    echo "--- $n ---"
    pbsnodes "$n" 2>&1 | grep -i 'state\|jobs ='
    echo
done
