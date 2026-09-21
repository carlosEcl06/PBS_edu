#!/bin/bash
# Discover this cluster's settings and write en/site.conf.
#
#   ./setup.sh          ask a few questions (press Enter to accept the defaults)
#   ./setup.sh --yes    accept every default without asking
#
# Safe to re-run: an existing site.conf is saved as site.conf.bak first.
# Run it on the LOGIN node (that is where qsub, qstat and pbsnodes live).

set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EDU_ROOT="$(cd "$HERE/.." && pwd)"
CONF="$EDU_ROOT/site.conf"
ASSUME_YES=0
[ "${1:-}" = "--yes" ] && ASSUME_YES=1

ask() { # ask "question" "default"  -> prints the answer
    local reply
    if [ "$ASSUME_YES" -eq 1 ] || [ ! -t 0 ]; then echo "$2"; return; fi
    read -r -p "$1 [$2]: " reply
    echo "${reply:-$2}"
}

echo "== PBS_edu setup =="
echo "Repository: $EDU_ROOT"
echo

# ---- 1. Is PBS here? ---------------------------------------------------------
if command -v qsub >/dev/null 2>&1 && command -v qstat >/dev/null 2>&1; then
    echo "[ok]   PBS commands found: $(command -v qsub)"
else
    echo "[!!]   qsub/qstat not found in PATH."
    echo "       Are you on the cluster's login node? Some sites need 'module load pbs' first."
    echo "       Continuing anyway so you can still write a site.conf."
fi

# ---- 2. Queues ---------------------------------------------------------------
QUEUES="$(qstat -Q 2>/dev/null | awk 'NR>2 {print $1}' | tr '\n' ' ')"
DEFAULT_QUEUE="$(qstat -Bf 2>/dev/null | awk '$1=="default_queue" {print $3}')"
EDU_QUEUE=""
if [ -n "$DEFAULT_QUEUE" ]; then
    echo "[ok]   default queue: $DEFAULT_QUEUE (scripts will use it automatically)"
elif [ -n "$QUEUES" ]; then
    echo "[info] no default queue configured. Queues on this server: $QUEUES"
    EDU_QUEUE="$(ask 'Which queue should jobs be submitted to?' "${QUEUES%% *}")"
else
    echo "[info] could not list queues (qstat -Q gave nothing). Leaving the queue empty;"
    echo "       if qsub later says a queue is required, set EDU_QUEUE in site.conf."
fi

# ---- 3. Container runtime ----------------------------------------------------
RUNTIME=""
for r in apptainer singularity; do
    if command -v "$r" >/dev/null 2>&1; then RUNTIME="$r"; break; fi
done
if [ -n "$RUNTIME" ]; then
    echo "[ok]   container runtime: $RUNTIME ($($RUNTIME --version 2>/dev/null))"
else
    RUNTIME="apptainer"
    echo "[!!]   neither apptainer nor singularity is in PATH."
    echo "       Try: module avail apptainer   (or singularity), then 'module load <name>'."
    echo "       If it is only installed on compute nodes, that is fine: run pull_containers.sh as a job."
fi

# ---- 4. Where to keep data, results and images -------------------------------
echo
echo "The data, images and results need about 1 GB on a filesystem that the COMPUTE"
echo "nodes can also see (home, a project area or scratch -- not a local /tmp)."
BASE="$(ask 'Directory to use' "$EDU_ROOT")"
mkdir -p "$BASE" 2>/dev/null
BASE="$(cd "$BASE" 2>/dev/null && pwd)" || { echo "cannot use that directory"; exit 1; }
case "$BASE" in /tmp*|/var/tmp*) echo "[!!]   $BASE looks like a local temp dir; compute nodes probably cannot see it." ;; esac
FS="$(df -PT "$BASE" 2>/dev/null | awk 'NR==2 {print $2}')"
FREE="$(df -Ph "$BASE" 2>/dev/null | awk 'NR==2 {print $4}')"
echo "[info] $BASE is on a '$FS' filesystem with $FREE free."

# ---- 5. Write site.conf ------------------------------------------------------
[ -f "$CONF" ] && cp "$CONF" "$CONF.bak" && echo "[info] previous site.conf saved as site.conf.bak"
cat > "$CONF" <<EOF
# Written by 00_getting_started/setup.sh on $(date +%F). Edit freely; see site.conf.example.
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
echo "[done] wrote $CONF"
echo "Next:  ./fetch_data.sh   then   ./pull_containers.sh   then   qsub make_samples.pbs"
