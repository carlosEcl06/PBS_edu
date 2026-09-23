#!/bin/bash
# Comprueba los resultados del ejercicio 1c (el job que escribiste desde cero).
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/01_pbs_basics"
RES="$OUT/reference_stats.txt"
REF="$DATA_DIR/ref/genome.fasta"

echo "Comprobando el ejercicio 1c..."
edu_expect_file "$RES" "tu job debe escribir $RES; mira su archivo de log"
if [ -s "$RES" ]; then
    read -r exp_seqs exp_len exp_gc < <(awk '/^>/ { n++; next } { len += length($0); gc += gsub(/[GCgc]/, "") } END { printf "%d %d %.2f\n", n, len, 100 * gc / len }' "$REF")
    get() { awk -F': ' -v k="$1" '$1 == k { print $2 }' "$RES"; }
    edu_expect_eq "sequences" "$exp_seqs" "$(get sequences)" "cuenta las líneas de cabecera '>'"
    edu_expect_eq "length" "$exp_len" "$(get length)" "suma la longitud de las líneas que no son cabecera"
    edu_expect_eq "gc_percent" "$exp_gc" "$(get gc_percent)" "G y C, mayúsculas o minúsculas, sobre la longitud total; 2 decimales"
    jid="$(get job_id)"
    case "$jid" in
        "" ) edu_fail "la línea job_id está vacía" "escribe \"job_id: \$PBS_JOBID\" desde DENTRO del job" ;;
        * ) edu_pass "job_id registrado ($jid)" ;;
    esac
    node="$(get host)"
    if [ -z "$node" ]; then
        edu_fail "falta la línea host" "escribe \"host: \$(hostname)\""
    elif [ "$node" = "$(hostname)" ]; then
        edu_warn "host es '$node', la misma máquina en la que estás ahora. ¿Corrió en el nodo de login? (Normal en un cluster de una sola máquina.)"
    else
        edu_pass "corrió en una máquina distinta del nodo de login ($node)"
    fi
fi
edu_summary
