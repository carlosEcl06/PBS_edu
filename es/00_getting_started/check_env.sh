#!/bin/bash
# Comprueba que todo lo que el curso necesita está en su sitio. Ejecútalo en el nodo de login:
#
#   ./check_env.sh             comprobación completa, incluido un job de prueba real de 10 segundos
#   ./check_env.sh --no-job    omite el job de prueba (solo comprueba archivos y comandos)
#
# No cambia nada, salvo enviar smoke_test.pbs.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE" || exit 1
source ../lib/edu.sh || exit 1

RUN_JOB=1
[ "${1:-}" = "--no-job" ] && RUN_JOB=0

echo "== 1. Comandos de PBS"
for c in qsub qstat qdel pbsnodes; do
    if command -v "$c" >/dev/null 2>&1; then edu_pass "$c"; else edu_fail "no se encontró $c" "¿estás en el nodo de login? prueba 'module avail pbs'"; fi
done

echo "== 2. Runtime de contenedores"
if command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
    edu_pass "$CONTAINER_RUNTIME en este nodo"
else
    edu_warn "$CONTAINER_RUNTIME no está en el PATH en este nodo (no pasa nada si solo lo tienen los nodos de cómputo; el job de prueba lo comprueba)"
fi

echo "== 3. Datos (fetch_data.sh)"
if (cd "$DATA_DIR" 2>/dev/null && sha256sum -c --quiet "$HERE/data.sha256" >/dev/null 2>&1); then
    edu_pass "referencia + lecturas reales presentes e intactas"
else
    edu_fail "faltan datos o están dañados en $DATA_DIR" "ejecuta ./fetch_data.sh"
fi

echo "== 4. Imágenes de contenedor (pull_containers.sh)"
for tool in "${TOOLS[@]}"; do
    if [ -s "$(edu_sif "$tool")" ]; then edu_pass "$tool.sif"; else edu_fail "falta $tool.sif" "ejecuta ./pull_containers.sh"; fi
done

echo "== 5. Muestras simuladas (make_samples.pbs)"
sheet="$DATA_DIR/samples/samples.tsv"
if [ -s "$sheet" ]; then
    n="$(wc -l < "$sheet")"
    missing="$(awk -F'\t' '{print $2; print $3}' "$sheet" | while read -r f; do [ -s "$f" ] || echo "$f"; done | wc -l)"
    edu_expect_eq "muestras en samples.tsv" "$N_SAMPLES" "$n" "vuelve a enviar: qsub make_samples.pbs"
    edu_expect_eq "archivos de muestra que faltan" "0" "$missing" "vuelve a enviar: qsub make_samples.pbs"
else
    edu_fail "no hay samples.tsv" "envía: qsub make_samples.pbs   (y espera a que termine)"
fi

if [ "$RUN_JOB" -eq 1 ] && command -v qsub >/dev/null 2>&1 && [ "$EDU_FAILS" -eq 0 ]; then
    echo "== 6. Job de prueba en un nodo de cómputo"
    jid="$(edu_qsub smoke_test.pbs)" || { edu_fail "qsub falló" "si dice que hace falta una cola, define EDU_QUEUE en site.conf"; jid=""; }
    if [ -n "$jid" ]; then
        num="${jid%%.*}"
        log="smoke_test.o$num"
        echo "  enviado $jid, esperando $log (hasta 3 minutos)..."
        for _ in $(seq 1 90); do [ -f "$log" ] && break; sleep 2; done
        if [ ! -f "$log" ]; then
            edu_fail "el job no terminó en 3 minutos" "mira 'qstat -u \$USER'; un cluster ocupado puede necesitar más tiempo"
        elif grep -q 'SMOKE OK' "$log"; then
            edu_pass "el job de prueba corrió en $(awk '/^== host/ {print $3}' "$log") y pudo usar contenedores + tus datos"
            rm -f "$log"
        else
            edu_fail "el job de prueba falló; su log ($log) dice:" ""
            sed 's/^/        /' "$log"
        fi
    fi
elif [ "$RUN_JOB" -eq 1 ]; then
    echo "== 6. Job de prueba omitido (corrige primero los fallos de arriba)"
fi

edu_summary
