#!/bin/bash
# Verifica os resultados do exercício 1a. Rode depois que seu job terminar.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/01_pbs_basics"
FASTQ="$DATA_DIR/real/test_1.fastq.gz"
exp_reads=$(( $(zcat "$FASTQ" | wc -l) / 4 ))
exp_bases=$(zcat "$FASTQ" | awk 'NR % 4 == 2 { n += length($0) } END { print n }')

echo "Verificando o exercício 1a..."
edu_expect_file "$OUT/read_count.txt" "ainda não há saída: o job terminou (qstat -u \$USER)? o log dele mostra algum erro?"
edu_expect_file "$OUT/base_count.txt"
[ -s "$OUT/read_count.txt" ] && edu_expect_eq "número de reads" "$exp_reads" "$(cat "$OUT/read_count.txt")" "um registro FASTQ tem 4 linhas"
[ -s "$OUT/base_count.txt" ] && edu_expect_eq "número de bases" "$exp_bases" "$(cat "$OUT/base_count.txt")" "some o length() da linha 2 de cada registro"
edu_summary
