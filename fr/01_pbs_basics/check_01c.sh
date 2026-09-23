#!/bin/bash
# Vérifie les résultats de l'exercice 1c (le job que vous avez écrit de zéro).
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/01_pbs_basics"
RES="$OUT/reference_stats.txt"
REF="$DATA_DIR/ref/genome.fasta"

echo "Vérification de l'exercice 1c..."
edu_expect_file "$RES" "votre job doit écrire $RES ; regardez son fichier de log"
if [ -s "$RES" ]; then
    read -r exp_seqs exp_len exp_gc < <(awk '/^>/ { n++; next } { len += length($0); gc += gsub(/[GCgc]/, "") } END { printf "%d %d %.2f\n", n, len, 100 * gc / len }' "$REF")
    get() { awk -F': ' -v k="$1" '$1 == k { print $2 }' "$RES"; }
    edu_expect_eq "sequences" "$exp_seqs" "$(get sequences)" "comptez les lignes d'en-tête '>'"
    edu_expect_eq "length" "$exp_len" "$(get length)" "additionnez la longueur des lignes qui ne sont pas des en-têtes"
    edu_expect_eq "gc_percent" "$exp_gc" "$(get gc_percent)" "G et C, majuscules ou minuscules, sur la longueur totale ; 2 décimales"
    jid="$(get job_id)"
    case "$jid" in
        "" ) edu_fail "la ligne job_id est vide" "écrivez \"job_id: \$PBS_JOBID\" depuis l'INTÉRIEUR du job" ;;
        * ) edu_pass "job_id enregistré ($jid)" ;;
    esac
    node="$(get host)"
    if [ -z "$node" ]; then
        edu_fail "la ligne host manque" "écrivez \"host: \$(hostname)\""
    elif [ "$node" = "$(hostname)" ]; then
        edu_warn "host vaut '$node', la machine sur laquelle vous êtes en ce moment. Le job a-t-il tourné sur le nœud de connexion ? (Normal sur un cluster d'une seule machine.)"
    else
        edu_pass "a tourné sur une autre machine que le nœud de connexion ($node)"
    fi
fi
edu_summary
