#!/bin/bash
# Funciones auxiliares compartidas por los scripts de PBS_edu. Carga este archivo
# con source, no lo ejecutes:
#
#   cd "$PBS_O_WORKDIR"        # los jobs empiezan en $HOME, no donde ejecutaste qsub
#   source ../lib/edu.sh       # funciona al enviar desde un directorio de sección
#
# Carga la configuración de tu cluster (site.conf), las imágenes de contenedor
# fijadas (containers.conf) y unas pocas funciones pequeñas. Léelo -- es corto
# a propósito.

# Los porcentajes y decimales deben usar "." en cualquier máquina (algunos locales usan ",").
export LC_ALL=C

EDU_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -f "$EDU_ROOT/site.conf" ]; then
    echo "PBS_edu: no se encontró $EDU_ROOT/site.conf." >&2
    echo "         Ejecuta 00_getting_started/setup.sh primero (ver 00_getting_started/README.md)." >&2
    return 1 2>/dev/null || exit 1
fi
# shellcheck disable=SC1091
source "$EDU_ROOT/site.conf"
# shellcheck disable=SC1091
source "$EDU_ROOT/containers.conf"

# Atajo: dentro de un directorio de sección, results/ apunta a la carpeta de salida
# de esa sección en $WORKDIR (donde escriben todos los jobs), así `ls results/` funciona.
_edu_here="${PBS_O_WORKDIR:-$PWD}"
if [ "$(dirname "$_edu_here")" = "$EDU_ROOT" ] && { [ ! -e "$_edu_here/results" ] || [ -L "$_edu_here/results" ]; }; then
    mkdir -p "$WORKDIR/$(basename "$_edu_here")" 2>/dev/null \
        && ln -sfn "$WORKDIR/$(basename "$_edu_here")" "$_edu_here/results" 2>/dev/null
fi
unset _edu_here

# ---------------------------------------------------------------- ejecutar herramientas

# Ruta de la imagen .sif de una herramienta listada en containers.conf.
edu_sif() { echo "$SIF_CACHE/$1.sif"; }

# Lista, separada por comas, de los directorios del host visibles dentro de los contenedores.
edu_binds() {
    local b="$EDU_ROOT,$DATA_DIR,$WORKDIR"
    [ -n "${BIND_PATHS:-}" ] && b="$b,$BIND_PATHS"
    echo "$b"
}

# Ejecuta una herramienta dentro de su contenedor:   edu_exec samtools view -H x.bam
# La primera palabra es A LA VEZ el nombre de la imagen (samtools.sif) y el programa.
# Es solo una forma corta de escribir:
#   apptainer exec --bind <dirs> samtools.sif samtools view -H x.bam
edu_exec() {
    local tool="$1" sif
    sif="$(edu_sif "$tool")"
    if [ ! -f "$sif" ]; then
        echo "PBS_edu: la imagen $sif no existe. Ejecuta 00_getting_started/pull_containers.sh" >&2
        return 127
    fi
    "$CONTAINER_RUNTIME" exec --bind "$(edu_binds)" "$sif" "$@"
}

# Envoltorio de qsub que solo añade -q cuando site.conf dice que una cola es obligatoria.
edu_qsub() {
    if [ -n "${EDU_QUEUE:-}" ]; then qsub -q "$EDU_QUEUE" "$@"; else qsub "$@"; fi
}

# ---------------------------------------------------------------- buenas prácticas en los jobs

# Número de CPUs que PBS dio a este job. PBS define NCPUS dentro de los jobs; no uses
# `nproc` aquí: en muchos clusters muestra todos los núcleos del nodo.
edu_threads() { echo "${NCPUS:-1}"; }

edu_banner() {
    echo "== job:    ${PBS_JOBID:-<fuera de PBS>}"
    echo "== host:   $(hostname)"
    echo "== inicio: $(date)"
    echo "== cpus:   ${NCPUS:-desconocido}"
}

# Falla pronto, con un mensaje claro, si este nodo no puede hacer el trabajo. Un
# nodo sin el runtime o con un sistema de archivos sin montar es una causa clásica
# de jobs que mueren en el primer segundo.
edu_preflight() {
    local bad=0
    if ! command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
        echo "PREFLIGHT FALLÓ en $(hostname): '$CONTAINER_RUNTIME' no está en el PATH" >&2
        bad=1
    fi
    for d in "$DATA_DIR" "$SIF_CACHE"; do
        if [ ! -d "$d" ]; then
            echo "PREFLIGHT FALLÓ en $(hostname): directorio no visible: $d" >&2
            bad=1
        fi
    done
    return $bad
}

# Añade "<paso> <start|end> <segundos-epoch>" a $EDU_TIMELINE (se usa en la sección 05).
edu_stamp() { printf '%s\t%s\t%s\n' "$1" "$2" "$(date +%s)" >> "${EDU_TIMELINE:?define EDU_TIMELINE primero}"; }

# ---------------------------------------------------------------- comprobación de ejercicios

EDU_FAILS=0
if [ -t 1 ]; then _G=$'\033[32m'; _R=$'\033[31m'; _Y=$'\033[33m'; _N=$'\033[0m'; else _G=""; _R=""; _Y=""; _N=""; fi

edu_pass() { printf '  %sOK   %s  %s\n' "$_G" "$_N" "$1"; }
edu_warn() { printf '  %sAVISO%s  %s\n' "$_Y" "$_N" "$1"; }
edu_fail() {
    printf '  %sFALLO%s  %s\n' "$_R" "$_N" "$1"
    [ -n "${2:-}" ] && printf '         pista: %s\n' "$2"
    EDU_FAILS=$((EDU_FAILS + 1))
}

# edu_expect_file <ruta> [pista]
edu_expect_file() {
    if [ -s "$1" ]; then edu_pass "encontrado $1"; else edu_fail "falta o está vacío: $1" "${2:-}"; fi
}

# edu_expect_eq <descripción> <esperado> <obtenido> [pista]
edu_expect_eq() {
    if [ "$2" = "$3" ]; then edu_pass "$1 ($3)"; else edu_fail "$1: se esperaba '$2', se obtuvo '${3:-<nada>}'" "${4:-}"; fi
}

# Exit status de un job terminado, según el historial de PBS (vacío si el historial está desactivado).
edu_job_exit_status() { qstat -xf "$1" 2>/dev/null | awk -F' = ' '/Exit_status/ {print $2}'; }

edu_summary() {
    echo
    if [ "$EDU_FAILS" -eq 0 ]; then echo "Todas las comprobaciones pasaron. ¡Buen trabajo!"; else echo "$EDU_FAILS comprobación(es) fallaron -- lee las pistas de arriba y vuelve a intentarlo."; fi
    return "$EDU_FAILS"
}
