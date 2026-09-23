#!/bin/bash
# Comprueba los resultados del ejercicio 1b.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/01_pbs_basics"
FASTQ="$DATA_DIR/real/test_1.fastq.gz"

echo "Comprobando el ejercicio 1b..."
edu_expect_file "$OUT/length_histogram.tsv" "el script nunca llegó a escribirlo: ¿qué dice el log?"
if [ -s "$OUT/length_histogram.tsv" ]; then
    expected="$(zcat "$FASTQ" | awk 'NR % 4 == 2 { print length($0) }' | sort -n | uniq -c | awk '{ print $2 "\t" $1 }')"
    edu_expect_eq "contenido del histograma" "$(echo "$expected" | md5sum | cut -c1-8)" "$(md5sum < "$OUT/length_histogram.tsv" | cut -c1-8)" "el histograma no coincide con el esperado"
fi
edu_expect_file "$OUT/length_hist.done" "el job no llegó a su última línea: ¿lo mataron? (qstat -xf <jobid> -> Exit_status; 271 = matado por PBS)"
edu_summary
