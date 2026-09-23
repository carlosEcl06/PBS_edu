#!/bin/bash
# Verifica os resultados do exercício 1b.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/01_pbs_basics"
FASTQ="$DATA_DIR/real/test_1.fastq.gz"

echo "Verificando o exercício 1b..."
edu_expect_file "$OUT/length_histogram.tsv" "o script nunca chegou a escrevê-lo: o que diz o log?"
if [ -s "$OUT/length_histogram.tsv" ]; then
    expected="$(zcat "$FASTQ" | awk 'NR % 4 == 2 { print length($0) }' | sort -n | uniq -c | awk '{ print $2 "\t" $1 }')"
    edu_expect_eq "conteúdo do histograma" "$(echo "$expected" | md5sum | cut -c1-8)" "$(md5sum < "$OUT/length_histogram.tsv" | cut -c1-8)" "o histograma é diferente do esperado"
fi
edu_expect_file "$OUT/length_hist.done" "o job não chegou à última linha: ele foi morto? (qstat -xf <jobid> -> Exit_status; 271 = morto pelo PBS)"
edu_summary
