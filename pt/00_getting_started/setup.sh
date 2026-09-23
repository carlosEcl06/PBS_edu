#!/bin/bash
# Descobre as configurações deste cluster e escreve pt/site.conf.
#
#   ./setup.sh          faz algumas perguntas (Enter aceita o valor padrão)
#   ./setup.sh --yes    aceita todos os valores padrão sem perguntar
#
# Pode rodar de novo sem medo: um site.conf existente é salvo antes como site.conf.bak.
# Rode no nó de LOGIN (é lá que ficam qsub, qstat e pbsnodes).

set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EDU_ROOT="$(cd "$HERE/.." && pwd)"
CONF="$EDU_ROOT/site.conf"
ASSUME_YES=0
[ "${1:-}" = "--yes" ] && ASSUME_YES=1

ask() { # ask "pergunta" "padrão"  -> imprime a resposta
    local reply
    if [ "$ASSUME_YES" -eq 1 ] || [ ! -t 0 ]; then echo "$2"; return; fi
    read -r -p "$1 [$2]: " reply
    echo "${reply:-$2}"
}

echo "== Configuração do PBS_edu =="
echo "Repositório: $EDU_ROOT"
echo

# ---- 1. O PBS está aqui? -----------------------------------------------------
if command -v qsub >/dev/null 2>&1 && command -v qstat >/dev/null 2>&1; then
    echo "[ok]   comandos do PBS encontrados: $(command -v qsub)"
else
    echo "[!!]   qsub/qstat não estão no PATH."
    echo "       Você está no nó de login do cluster? Alguns sites exigem 'module load pbs' antes."
    echo "       Continuando mesmo assim, para você ainda poder escrever um site.conf."
fi

# ---- 2. Filas ----------------------------------------------------------------
QUEUES="$(qstat -Q 2>/dev/null | awk 'NR>2 {print $1}' | tr '\n' ' ')"
DEFAULT_QUEUE="$(qstat -Bf 2>/dev/null | awk '$1=="default_queue" {print $3}')"
EDU_QUEUE=""
if [ -n "$DEFAULT_QUEUE" ]; then
    echo "[ok]   fila padrão: $DEFAULT_QUEUE (os scripts vão usá-la automaticamente)"
elif [ -n "$QUEUES" ]; then
    echo "[info] nenhuma fila padrão configurada. Filas neste servidor: $QUEUES"
    EDU_QUEUE="$(ask 'Para qual fila os jobs devem ser submetidos?' "${QUEUES%% *}")"
else
    echo "[info] não foi possível listar as filas (qstat -Q não retornou nada). Deixando a fila vazia;"
    echo "       se depois o qsub disser que uma fila é obrigatória, defina EDU_QUEUE no site.conf."
fi

# ---- 3. Runtime de containers ------------------------------------------------
RUNTIME=""
for r in apptainer singularity; do
    if command -v "$r" >/dev/null 2>&1; then RUNTIME="$r"; break; fi
done
if [ -n "$RUNTIME" ]; then
    echo "[ok]   runtime de containers: $RUNTIME ($($RUNTIME --version 2>/dev/null))"
else
    RUNTIME="apptainer"
    echo "[!!]   nem apptainer nem singularity estão no PATH."
    echo "       Tente: module avail apptainer   (ou singularity), depois 'module load <nome>'."
    echo "       Se só estiver instalado nos nós de computação, tudo bem: rode pull_containers.sh como job."
fi

# ---- 4. Onde guardar dados, resultados e imagens ------------------------------
echo
echo "Os dados, imagens e resultados precisam de cerca de 1 GB num sistema de arquivos"
echo "que os nós de COMPUTAÇÃO também enxerguem (home, área de projeto ou scratch -- não um /tmp local)."
BASE="$(ask 'Diretório a usar' "$EDU_ROOT")"
mkdir -p "$BASE" 2>/dev/null
BASE="$(cd "$BASE" 2>/dev/null && pwd)" || { echo "não é possível usar esse diretório"; exit 1; }
case "$BASE" in /tmp*|/var/tmp*) echo "[!!]   $BASE parece um diretório temporário local; os nós de computação provavelmente não o enxergam." ;; esac
FS="$(df -PT "$BASE" 2>/dev/null | awk 'NR==2 {print $2}')"
FREE="$(df -Ph "$BASE" 2>/dev/null | awk 'NR==2 {print $4}')"
echo "[info] $BASE está num sistema de arquivos '$FS' com $FREE livres."

# ---- 5. Escrever o site.conf -------------------------------------------------
[ -f "$CONF" ] && cp "$CONF" "$CONF.bak" && echo "[info] site.conf anterior salvo como site.conf.bak"
cat > "$CONF" <<EOF
# Escrito por 00_getting_started/setup.sh em $(date +%F). Edite à vontade; veja site.conf.example.
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
echo "[pronto] escrito $CONF"
echo "Próximo:  ./fetch_data.sh   depois   ./pull_containers.sh   depois   qsub make_samples.pbs"
