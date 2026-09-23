#!/bin/bash
# Découvre les réglages de ce cluster et écrit fr/site.conf.
#
#   ./setup.sh          pose quelques questions (Entrée accepte la valeur par défaut)
#   ./setup.sh --yes    accepte toutes les valeurs par défaut sans rien demander
#
# Peut être relancé sans risque : un site.conf existant est d'abord sauvegardé en site.conf.bak.
# Lancez-le sur le nœud de CONNEXION (c'est là que se trouvent qsub, qstat et pbsnodes).

set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EDU_ROOT="$(cd "$HERE/.." && pwd)"
CONF="$EDU_ROOT/site.conf"
ASSUME_YES=0
[ "${1:-}" = "--yes" ] && ASSUME_YES=1

ask() { # ask "question" "défaut"  -> affiche la réponse
    local reply
    if [ "$ASSUME_YES" -eq 1 ] || [ ! -t 0 ]; then echo "$2"; return; fi
    read -r -p "$1 [$2] : " reply
    echo "${reply:-$2}"
}

echo "== Configuration de PBS_edu =="
echo "Dépôt : $EDU_ROOT"
echo

# ---- 1. PBS est-il là ? ------------------------------------------------------
if command -v qsub >/dev/null 2>&1 && command -v qstat >/dev/null 2>&1; then
    echo "[ok]   commandes PBS trouvées : $(command -v qsub)"
else
    echo "[!!]   qsub/qstat introuvables dans le PATH."
    echo "       Êtes-vous sur le nœud de connexion du cluster ? Certains sites demandent d'abord 'module load pbs'."
    echo "       On continue quand même, pour que vous puissiez écrire un site.conf."
fi

# ---- 2. Files d'attente ------------------------------------------------------
QUEUES="$(qstat -Q 2>/dev/null | awk 'NR>2 {print $1}' | tr '\n' ' ')"
DEFAULT_QUEUE="$(qstat -Bf 2>/dev/null | awk '$1=="default_queue" {print $3}')"
EDU_QUEUE=""
if [ -n "$DEFAULT_QUEUE" ]; then
    echo "[ok]   file par défaut : $DEFAULT_QUEUE (les scripts l'utiliseront automatiquement)"
elif [ -n "$QUEUES" ]; then
    echo "[info] aucune file par défaut configurée. Files sur ce serveur : $QUEUES"
    EDU_QUEUE="$(ask 'Dans quelle file soumettre les jobs ?' "${QUEUES%% *}")"
else
    echo "[info] impossible de lister les files (qstat -Q n'a rien renvoyé). La file reste vide ;"
    echo "       si qsub dit plus tard qu'une file est obligatoire, définissez EDU_QUEUE dans site.conf."
fi

# ---- 3. Runtime de conteneurs ------------------------------------------------
RUNTIME=""
for r in apptainer singularity; do
    if command -v "$r" >/dev/null 2>&1; then RUNTIME="$r"; break; fi
done
if [ -n "$RUNTIME" ]; then
    echo "[ok]   runtime de conteneurs : $RUNTIME ($($RUNTIME --version 2>/dev/null))"
else
    RUNTIME="apptainer"
    echo "[!!]   ni apptainer ni singularity ne sont dans le PATH."
    echo "       Essayez : module avail apptainer   (ou singularity), puis 'module load <nom>'."
    echo "       S'il n'est installé que sur les nœuds de calcul, pas de souci : lancez pull_containers.sh comme job."
fi

# ---- 4. Où garder données, résultats et images --------------------------------
echo
echo "Les données, images et résultats demandent environ 1 Go sur un système de fichiers"
echo "que les nœuds de CALCUL voient aussi (home, espace projet ou scratch -- pas un /tmp local)."
BASE="$(ask 'Répertoire à utiliser' "$EDU_ROOT")"
mkdir -p "$BASE" 2>/dev/null
BASE="$(cd "$BASE" 2>/dev/null && pwd)" || { echo "impossible d'utiliser ce répertoire"; exit 1; }
case "$BASE" in /tmp*|/var/tmp*) echo "[!!]   $BASE ressemble à un répertoire temporaire local ; les nœuds de calcul ne le voient sans doute pas." ;; esac
FS="$(df -PT "$BASE" 2>/dev/null | awk 'NR==2 {print $2}')"
FREE="$(df -Ph "$BASE" 2>/dev/null | awk 'NR==2 {print $4}')"
echo "[info] $BASE est sur un système de fichiers '$FS' avec $FREE libres."

# ---- 5. Écrire site.conf -----------------------------------------------------
[ -f "$CONF" ] && cp "$CONF" "$CONF.bak" && echo "[info] ancien site.conf sauvegardé en site.conf.bak"
cat > "$CONF" <<EOF
# Écrit par 00_getting_started/setup.sh le $(date +%F). Modifiez librement ; voir site.conf.example.
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
echo "[terminé] $CONF écrit"
echo "Ensuite :  ./fetch_data.sh   puis   ./pull_containers.sh   puis   qsub make_samples.pbs"
