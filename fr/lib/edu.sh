#!/bin/bash
# Fonctions utilitaires partagées par les scripts de PBS_edu. Chargez ce fichier
# avec source, ne l'exécutez pas :
#
#   cd "$PBS_O_WORKDIR"        # les jobs démarrent dans $HOME, pas là où vous avez lancé qsub
#   source ../lib/edu.sh       # fonctionne quand on soumet depuis un répertoire de section
#
# Il charge les réglages de votre cluster (site.conf), les images de conteneur
# épinglées (containers.conf) et quelques petites fonctions. Lisez-le -- il est
# court exprès.

# Les pourcentages et décimaux doivent utiliser "." sur toutes les machines (certaines locales utilisent ",").
export LC_ALL=C

EDU_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -f "$EDU_ROOT/site.conf" ]; then
    echo "PBS_edu : $EDU_ROOT/site.conf introuvable." >&2
    echo "          Lancez 00_getting_started/setup.sh d'abord (voir 00_getting_started/README.md)." >&2
    return 1 2>/dev/null || exit 1
fi
# shellcheck disable=SC1091
source "$EDU_ROOT/site.conf"
# shellcheck disable=SC1091
source "$EDU_ROOT/containers.conf"

# Raccourci : dans un répertoire de section, results/ pointe vers le dossier de sortie
# de cette section dans $WORKDIR (où écrivent tous les jobs), donc `ls results/` marche.
_edu_here="${PBS_O_WORKDIR:-$PWD}"
if [ "$(dirname "$_edu_here")" = "$EDU_ROOT" ] && { [ ! -e "$_edu_here/results" ] || [ -L "$_edu_here/results" ]; }; then
    mkdir -p "$WORKDIR/$(basename "$_edu_here")" 2>/dev/null \
        && ln -sfn "$WORKDIR/$(basename "$_edu_here")" "$_edu_here/results" 2>/dev/null
fi
unset _edu_here

# ---------------------------------------------------------------- lancer des outils

# Chemin de l'image .sif d'un outil listé dans containers.conf.
edu_sif() { echo "$SIF_CACHE/$1.sif"; }

# Liste, séparée par des virgules, des répertoires de l'hôte visibles dans les conteneurs.
edu_binds() {
    local b="$EDU_ROOT,$DATA_DIR,$WORKDIR"
    [ -n "${BIND_PATHS:-}" ] && b="$b,$BIND_PATHS"
    echo "$b"
}

# Lance un outil dans son conteneur :   edu_exec samtools view -H x.bam
# Le premier mot est À LA FOIS le nom de l'image (samtools.sif) et le programme.
# C'est juste une façon courte d'écrire :
#   apptainer exec --bind <dirs> samtools.sif samtools view -H x.bam
edu_exec() {
    local tool="$1" sif
    sif="$(edu_sif "$tool")"
    if [ ! -f "$sif" ]; then
        echo "PBS_edu : l'image $sif est introuvable. Lancez 00_getting_started/pull_containers.sh" >&2
        return 127
    fi
    "$CONTAINER_RUNTIME" exec --bind "$(edu_binds)" "$sif" "$@"
}

# Enveloppe de qsub qui n'ajoute -q que si site.conf indique qu'une file est obligatoire.
edu_qsub() {
    if [ -n "${EDU_QUEUE:-}" ]; then qsub -q "$EDU_QUEUE" "$@"; else qsub "$@"; fi
}

# ---------------------------------------------------------------- bonnes pratiques dans les jobs

# Nombre de CPU que PBS a donnés à ce job. PBS définit NCPUS dans les jobs ; n'utilisez
# pas `nproc` ici : sur beaucoup de clusters il affiche tous les cœurs du nœud.
edu_threads() { echo "${NCPUS:-1}"; }

edu_banner() {
    echo "== job:   ${PBS_JOBID:-<hors de PBS>}"
    echo "== host:  $(hostname)"
    echo "== début: $(date)"
    echo "== cpus:  ${NCPUS:-inconnu}"
}

# Échoue tôt, avec un message clair, si ce nœud ne peut pas faire le travail. Un
# nœud sans runtime ou avec un système de fichiers non monté est une cause
# classique de jobs qui meurent dans la première seconde.
edu_preflight() {
    local bad=0
    if ! command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
        echo "PREFLIGHT ÉCHEC sur $(hostname) : '$CONTAINER_RUNTIME' n'est pas dans le PATH" >&2
        bad=1
    fi
    for d in "$DATA_DIR" "$SIF_CACHE"; do
        if [ ! -d "$d" ]; then
            echo "PREFLIGHT ÉCHEC sur $(hostname) : répertoire non visible : $d" >&2
            bad=1
        fi
    done
    return $bad
}

# Ajoute "<étape> <start|end> <secondes-epoch>" à $EDU_TIMELINE (utilisé en section 05).
edu_stamp() { printf '%s\t%s\t%s\n' "$1" "$2" "$(date +%s)" >> "${EDU_TIMELINE:?définissez EDU_TIMELINE avant}"; }

# ---------------------------------------------------------------- vérification des exercices

EDU_FAILS=0
if [ -t 1 ]; then _G=$'\033[32m'; _R=$'\033[31m'; _Y=$'\033[33m'; _N=$'\033[0m'; else _G=""; _R=""; _Y=""; _N=""; fi

edu_pass() { printf '  %sOK    %s  %s\n' "$_G" "$_N" "$1"; }
edu_warn() { printf '  %sALERTE%s  %s\n' "$_Y" "$_N" "$1"; }
edu_fail() {
    printf '  %sÉCHEC %s  %s\n' "$_R" "$_N" "$1"
    [ -n "${2:-}" ] && printf '          piste : %s\n' "$2"
    EDU_FAILS=$((EDU_FAILS + 1))
}

# edu_expect_file <chemin> [piste]
edu_expect_file() {
    if [ -s "$1" ]; then edu_pass "trouvé $1"; else edu_fail "absent ou vide : $1" "${2:-}"; fi
}

# edu_expect_eq <description> <attendu> <obtenu> [piste]
edu_expect_eq() {
    if [ "$2" = "$3" ]; then edu_pass "$1 ($3)"; else edu_fail "$1 : attendu '$2', obtenu '${3:-<rien>}'" "${4:-}"; fi
}

# Exit status d'un job terminé, d'après l'historique de PBS (vide si l'historique est désactivé).
edu_job_exit_status() { qstat -xf "$1" 2>/dev/null | awk -F' = ' '/Exit_status/ {print $2}'; }

edu_summary() {
    echo
    if [ "$EDU_FAILS" -eq 0 ]; then echo "Toutes les vérifications sont passées. Bravo !"; else echo "$EDU_FAILS vérification(s) en échec -- lisez les pistes ci-dessus et réessayez."; fi
    return "$EDU_FAILS"
}
