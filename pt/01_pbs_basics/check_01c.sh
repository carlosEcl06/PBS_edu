#!/bin/bash
# Verifica os resultados do exercício 1c (o job que você escreveu do zero).
cd "$(dirname "$0")" || exit 1
source ../lib/edu.sh || exit 1

OUT="$WORKDIR/01_pbs_basics"
RES="$OUT/reference_stats.txt"
REF="$DATA_DIR/ref/genome.fasta"

echo "Verificando o exercício 1c..."
edu_expect_file "$RES" "seu job precisa escrever $RES; olhe o arquivo de log dele"
if [ -s "$RES" ]; then
    read -r exp_seqs exp_len exp_gc < <(awk '/^>/ { n++; next } { len += length($0); gc += gsub(/[GCgc]/, "") } END { printf "%d %d %.2f\n", n, len, 100 * gc / len }' "$REF")
    get() { awk -F': ' -v k="$1" '$1 == k { print $2 }' "$RES"; }
    edu_expect_eq "sequences" "$exp_seqs" "$(get sequences)" "conte as linhas de cabeçalho '>'"
    edu_expect_eq "length" "$exp_len" "$(get length)" "some o comprimento das linhas que não são cabeçalho"
    edu_expect_eq "gc_percent" "$exp_gc" "$(get gc_percent)" "G e C, maiúsculas ou minúsculas, sobre o comprimento total; 2 casas decimais"
    jid="$(get job_id)"
    case "$jid" in
        "" ) edu_fail "a linha job_id está vazia" "escreva \"job_id: \$PBS_JOBID\" de DENTRO do job" ;;
        * ) edu_pass "job_id registrado ($jid)" ;;
    esac
    node="$(get host)"
    if [ -z "$node" ]; then
        edu_fail "a linha host está faltando" "escreva \"host: \$(hostname)\""
    elif [ "$node" = "$(hostname)" ]; then
        edu_warn "host é '$node', a mesma máquina em que você está agora. Isto rodou no nó de login? (Tudo bem num cluster de uma máquina só.)"
    else
        edu_pass "rodou numa máquina diferente do nó de login ($node)"
    fi
fi
edu_summary
