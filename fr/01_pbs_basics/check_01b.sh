#!/bin/bash
# Vérifie les résultats de l'exercice 1b.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/01_pbs_basics"
FASTQ="$DATA_DIR/real/test_1.fastq.gz"

echo "Vérification de l'exercice 1b..."
edu_expect_file "$OUT/length_histogram.tsv" "le script n'est jamais allé jusqu'à l'écrire : que dit le log ?"
if [ -s "$OUT/length_histogram.tsv" ]; then
    expected="$(zcat "$FASTQ" | awk 'NR % 4 == 2 { print length($0) }' | sort -n | uniq -c | awk '{ print $2 "\t" $1 }')"
    edu_expect_eq "contenu de l'histogramme" "$(echo "$expected" | md5sum | cut -c1-8)" "$(md5sum < "$OUT/length_histogram.tsv" | cut -c1-8)" "l'histogramme diffère de celui attendu"
fi
edu_expect_file "$OUT/length_hist.done" "le job n'a pas atteint sa dernière ligne : a-t-il été tué ? (qstat -xf <jobid> -> Exit_status ; 271 = tué par PBS)"
edu_summary
