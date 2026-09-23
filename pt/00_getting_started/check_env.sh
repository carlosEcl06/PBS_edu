#!/bin/bash
# Verifica se tudo o que o curso precisa está no lugar. Rode no nó de login:
#
#   ./check_env.sh             verificação completa, incluindo um job de teste real de 10 segundos
#   ./check_env.sh --no-job    pula o job de teste (verifica só arquivos e comandos)
#
# Não muda nada, a não ser submeter smoke_test.pbs.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE" || exit 1
source ../lib/edu.sh || exit 1

RUN_JOB=1
[ "${1:-}" = "--no-job" ] && RUN_JOB=0

echo "== 1. Comandos do PBS"
for c in qsub qstat qdel pbsnodes; do
    if command -v "$c" >/dev/null 2>&1; then edu_pass "$c"; else edu_fail "$c não encontrado" "você está no nó de login? tente 'module avail pbs'"; fi
done

echo "== 2. Runtime de containers"
if command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
    edu_pass "$CONTAINER_RUNTIME neste nó"
else
    edu_warn "$CONTAINER_RUNTIME não está no PATH neste nó (tudo bem se só os nós de computação o têm; o job de teste verifica isso)"
fi

echo "== 3. Dados (fetch_data.sh)"
if (cd "$DATA_DIR" 2>/dev/null && sha256sum -c --quiet "$HERE/data.sha256" >/dev/null 2>&1); then
    edu_pass "referência + reads reais presentes e íntegros"
else
    edu_fail "dados ausentes ou corrompidos em $DATA_DIR" "rode ./fetch_data.sh"
fi

echo "== 4. Imagens de container (pull_containers.sh)"
for tool in "${TOOLS[@]}"; do
    if [ -s "$(edu_sif "$tool")" ]; then edu_pass "$tool.sif"; else edu_fail "$tool.sif ausente" "rode ./pull_containers.sh"; fi
done

echo "== 5. Amostras simuladas (make_samples.pbs)"
sheet="$DATA_DIR/samples/samples.tsv"
if [ -s "$sheet" ]; then
    n="$(wc -l < "$sheet")"
    missing="$(awk -F'\t' '{print $2; print $3}' "$sheet" | while read -r f; do [ -s "$f" ] || echo "$f"; done | wc -l)"
    edu_expect_eq "amostras em samples.tsv" "$N_SAMPLES" "$n" "rode de novo: qsub make_samples.pbs"
    edu_expect_eq "arquivos de amostra ausentes" "0" "$missing" "rode de novo: qsub make_samples.pbs"
else
    edu_fail "samples.tsv não existe" "submeta: qsub make_samples.pbs   (e espere terminar)"
fi

if [ "$RUN_JOB" -eq 1 ] && command -v qsub >/dev/null 2>&1 && [ "$EDU_FAILS" -eq 0 ]; then
    echo "== 6. Job de teste num nó de computação"
    jid="$(edu_qsub smoke_test.pbs)" || { edu_fail "qsub falhou" "se ele disser que uma fila é obrigatória, defina EDU_QUEUE no site.conf"; jid=""; }
    if [ -n "$jid" ]; then
        num="${jid%%.*}"
        log="smoke_test.o$num"
        echo "  submetido $jid, esperando $log (até 3 minutos)..."
        for _ in $(seq 1 90); do [ -f "$log" ] && break; sleep 2; done
        if [ ! -f "$log" ]; then
            edu_fail "o job não terminou em 3 minutos" "veja 'qstat -u \$USER'; num cluster ocupado pode só precisar de mais tempo"
        elif grep -q 'SMOKE OK' "$log"; then
            edu_pass "o job de teste rodou em $(awk '/^== host/ {print $3}' "$log") e conseguiu usar containers + seus dados"
            rm -f "$log"
        else
            edu_fail "o job de teste falhou; o log dele ($log) diz:" ""
            sed 's/^/        /' "$log"
        fi
    fi
elif [ "$RUN_JOB" -eq 1 ]; then
    echo "== 6. Job de teste pulado (corrija as falhas acima primeiro)"
fi

edu_summary
