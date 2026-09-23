#!/bin/bash
# Vérifie les résultats de l'exercice 1a. Lancez-le une fois votre job terminé.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/01_pbs_basics"
FASTQ="$DATA_DIR/real/test_1.fastq.gz"
exp_reads=$(( $(zcat "$FASTQ" | wc -l) / 4 ))
exp_bases=$(zcat "$FASTQ" | awk 'NR % 4 == 2 { n += length($0) } END { print n }')

echo "Vérification de l'exercice 1a..."
edu_expect_file "$OUT/read_count.txt" "pas encore de sortie : le job est-il terminé (qstat -u \$USER) ? son log montre-t-il une erreur ?"
edu_expect_file "$OUT/base_count.txt"
[ -s "$OUT/read_count.txt" ] && edu_expect_eq "nombre de lectures" "$exp_reads" "$(cat "$OUT/read_count.txt")" "un enregistrement FASTQ fait 4 lignes"
[ -s "$OUT/base_count.txt" ] && edu_expect_eq "nombre de bases" "$exp_bases" "$(cat "$OUT/base_count.txt")" "additionnez length() de la ligne 2 de chaque enregistrement"
edu_summary
