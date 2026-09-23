#!/bin/bash
# Comprueba los resultados del ejercicio 1a. Ejecútalo cuando tu job haya terminado.
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/01_pbs_basics"
FASTQ="$DATA_DIR/real/test_1.fastq.gz"
exp_reads=$(( $(zcat "$FASTQ" | wc -l) / 4 ))
exp_bases=$(zcat "$FASTQ" | awk 'NR % 4 == 2 { n += length($0) } END { print n }')

echo "Comprobando el ejercicio 1a..."
edu_expect_file "$OUT/read_count.txt" "todavía no hay salida: ¿terminó el job (qstat -u \$USER)? ¿su log muestra algún error?"
edu_expect_file "$OUT/base_count.txt"
[ -s "$OUT/read_count.txt" ] && edu_expect_eq "número de lecturas" "$exp_reads" "$(cat "$OUT/read_count.txt")" "un registro FASTQ tiene 4 líneas"
[ -s "$OUT/base_count.txt" ] && edu_expect_eq "número de bases" "$exp_bases" "$(cat "$OUT/base_count.txt")" "suma el length() de la línea 2 de cada registro"
edu_summary
