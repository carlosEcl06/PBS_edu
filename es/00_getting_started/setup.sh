#!/bin/bash
# Descubre la configuración de este cluster y escribe es/site.conf.
#
#   ./setup.sh          hace unas pocas preguntas (Enter acepta el valor por defecto)
#   ./setup.sh --yes    acepta todos los valores por defecto sin preguntar
#
# Se puede volver a ejecutar sin miedo: un site.conf existente se guarda antes como site.conf.bak.
# Ejecútalo en el nodo de LOGIN (ahí están qsub, qstat y pbsnodes).

set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EDU_ROOT="$(cd "$HERE/.." && pwd)"
CONF="$EDU_ROOT/site.conf"
ASSUME_YES=0
[ "${1:-}" = "--yes" ] && ASSUME_YES=1

ask() { # ask "pregunta" "defecto"  -> imprime la respuesta
    local reply
    if [ "$ASSUME_YES" -eq 1 ] || [ ! -t 0 ]; then echo "$2"; return; fi
    read -r -p "$1 [$2]: " reply
    echo "${reply:-$2}"
}

echo "== Configuración de PBS_edu =="
echo "Repositorio: $EDU_ROOT"
echo

# ---- 1. ¿Está PBS aquí? ------------------------------------------------------
if command -v qsub >/dev/null 2>&1 && command -v qstat >/dev/null 2>&1; then
    echo "[ok]   comandos de PBS encontrados: $(command -v qsub)"
else
    echo "[!!]   qsub/qstat no están en el PATH."
    echo "       ¿Estás en el nodo de login del cluster? Algunos sitios necesitan 'module load pbs' antes."
    echo "       Sigo de todos modos, para que puedas escribir un site.conf."
fi

# ---- 2. Colas ----------------------------------------------------------------
QUEUES="$(qstat -Q 2>/dev/null | awk 'NR>2 {print $1}' | tr '\n' ' ')"
DEFAULT_QUEUE="$(qstat -Bf 2>/dev/null | awk '$1=="default_queue" {print $3}')"
EDU_QUEUE=""
if [ -n "$DEFAULT_QUEUE" ]; then
    echo "[ok]   cola por defecto: $DEFAULT_QUEUE (los scripts la usarán automáticamente)"
elif [ -n "$QUEUES" ]; then
    echo "[info] no hay cola por defecto configurada. Colas en este servidor: $QUEUES"
    EDU_QUEUE="$(ask '¿A qué cola se deben enviar los jobs?' "${QUEUES%% *}")"
else
    echo "[info] no se pudieron listar las colas (qstat -Q no devolvió nada). Dejo la cola vacía;"
    echo "       si más adelante qsub dice que hace falta una cola, define EDU_QUEUE en site.conf."
fi

# ---- 3. Runtime de contenedores ----------------------------------------------
RUNTIME=""
for r in apptainer singularity; do
    if command -v "$r" >/dev/null 2>&1; then RUNTIME="$r"; break; fi
done
if [ -n "$RUNTIME" ]; then
    echo "[ok]   runtime de contenedores: $RUNTIME ($($RUNTIME --version 2>/dev/null))"
else
    RUNTIME="apptainer"
    echo "[!!]   ni apptainer ni singularity están en el PATH."
    echo "       Prueba: module avail apptainer   (o singularity), luego 'module load <nombre>'."
    echo "       Si solo está instalado en los nodos de cómputo, no pasa nada: ejecuta pull_containers.sh como job."
fi

# ---- 4. Dónde guardar datos, resultados e imágenes ----------------------------
echo
echo "Los datos, imágenes y resultados necesitan alrededor de 1 GB en un sistema de archivos"
echo "que los nodos de CÓMPUTO también vean (home, área de proyecto o scratch -- no un /tmp local)."
BASE="$(ask 'Directorio a usar' "$EDU_ROOT")"
mkdir -p "$BASE" 2>/dev/null
BASE="$(cd "$BASE" 2>/dev/null && pwd)" || { echo "no se puede usar ese directorio"; exit 1; }
case "$BASE" in /tmp*|/var/tmp*) echo "[!!]   $BASE parece un directorio temporal local; probablemente los nodos de cómputo no lo ven." ;; esac
FS="$(df -PT "$BASE" 2>/dev/null | awk 'NR==2 {print $2}')"
FREE="$(df -Ph "$BASE" 2>/dev/null | awk 'NR==2 {print $4}')"
echo "[info] $BASE está en un sistema de archivos '$FS' con $FREE libres."

# ---- 5. Escribir site.conf ---------------------------------------------------
[ -f "$CONF" ] && cp "$CONF" "$CONF.bak" && echo "[info] el site.conf anterior se guardó como site.conf.bak"
cat > "$CONF" <<EOF
# Escrito por 00_getting_started/setup.sh el $(date +%F). Edítalo libremente; ver site.conf.example.
EDU_QUEUE="$EDU_QUEUE"

DATA_DIR="$BASE/data"
WORKDIR="$BASE/work"
SIF_CACHE="$BASE/sif"

CONTAINER_RUNTIME="$RUNTIME"
BIND_PATHS=""

N_SAMPLES=6
READS_PER_SAMPLE=300000
EOF
mkdir -p "$BASE/data" "$BASE/work" "$BASE/sif"

echo
echo "[listo] escrito $CONF"
echo "Siguiente:  ./fetch_data.sh   luego   ./pull_containers.sh   luego   qsub make_samples.pbs"
