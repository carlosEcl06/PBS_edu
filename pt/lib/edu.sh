#!/bin/bash
# Funções auxiliares compartilhadas pelos scripts do PBS_edu. Carregue este
# arquivo com source, não o execute:
#
#   cd "$PBS_O_WORKDIR"        # jobs começam no $HOME, não onde você rodou o qsub
#   source ../lib/edu.sh       # funciona quando submetido de um diretório de seção
#
# Ele carrega as configurações do seu cluster (site.conf), as imagens de
# container fixadas (containers.conf) e algumas funções pequenas. Leia -- ele é
# curto de propósito.

# Porcentagens e decimais precisam usar "." em qualquer máquina (alguns locales usam ",").
export LC_ALL=C

EDU_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -f "$EDU_ROOT/site.conf" ]; then
    echo "PBS_edu: $EDU_ROOT/site.conf não encontrado." >&2
    echo "         Rode 00_getting_started/setup.sh primeiro (veja 00_getting_started/README.md)." >&2
    return 1 2>/dev/null || exit 1
fi
# shellcheck disable=SC1091
source "$EDU_ROOT/site.conf"
# shellcheck disable=SC1091
source "$EDU_ROOT/containers.conf"

# Atalho: dentro de um diretório de seção, results/ aponta para a pasta de saída
# daquela seção em $WORKDIR (onde todos os jobs escrevem), então `ls results/` funciona.
_edu_here="${PBS_O_WORKDIR:-$PWD}"
if [ "$(dirname "$_edu_here")" = "$EDU_ROOT" ] && { [ ! -e "$_edu_here/results" ] || [ -L "$_edu_here/results" ]; }; then
    mkdir -p "$WORKDIR/$(basename "$_edu_here")" 2>/dev/null \
        && ln -sfn "$WORKDIR/$(basename "$_edu_here")" "$_edu_here/results" 2>/dev/null
fi
unset _edu_here

# ---------------------------------------------------------------- rodar ferramentas

# Caminho da imagem .sif de uma ferramenta listada em containers.conf.
edu_sif() { echo "$SIF_CACHE/$1.sif"; }

# Lista, separada por vírgulas, dos diretórios do host visíveis dentro dos containers.
edu_binds() {
    local b="$EDU_ROOT,$DATA_DIR,$WORKDIR"
    [ -n "${BIND_PATHS:-}" ] && b="$b,$BIND_PATHS"
    echo "$b"
}

# Roda uma ferramenta dentro do seu container:   edu_exec samtools view -H x.bam
# A primeira palavra é AO MESMO TEMPO o nome da imagem (samtools.sif) e o programa.
# É só uma forma curta de escrever:
#   apptainer exec --bind <dirs> samtools.sif samtools view -H x.bam
edu_exec() {
    local tool="$1" sif
    sif="$(edu_sif "$tool")"
    if [ ! -f "$sif" ]; then
        echo "PBS_edu: a imagem $sif não existe. Rode 00_getting_started/pull_containers.sh" >&2
        return 127
    fi
    "$CONTAINER_RUNTIME" exec --bind "$(edu_binds)" "$sif" "$@"
}

# Envolve o qsub e só acrescenta -q quando o site.conf diz que uma fila é obrigatória.
edu_qsub() {
    if [ -n "${EDU_QUEUE:-}" ]; then qsub -q "$EDU_QUEUE" "$@"; else qsub "$@"; fi
}

# ---------------------------------------------------------------- boas práticas nos jobs

# Número de CPUs que o PBS deu a este job. O PBS define NCPUS dentro dos jobs; não
# use `nproc` aqui: em muitos clusters ele mostra todos os núcleos do nó.
edu_threads() { echo "${NCPUS:-1}"; }

edu_banner() {
    echo "== job:    ${PBS_JOBID:-<fora do PBS>}"
    echo "== host:   $(hostname)"
    echo "== início: $(date)"
    echo "== cpus:   ${NCPUS:-desconhecido}"
}

# Falha cedo, com uma mensagem clara, se este nó não consegue fazer o trabalho. Um
# nó sem o runtime ou com um sistema de arquivos não montado é uma causa clássica
# de jobs que morrem no primeiro segundo.
edu_preflight() {
    local bad=0
    if ! command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
        echo "PREFLIGHT FALHOU em $(hostname): '$CONTAINER_RUNTIME' não está no PATH" >&2
        bad=1
    fi
    for d in "$DATA_DIR" "$SIF_CACHE"; do
        if [ ! -d "$d" ]; then
            echo "PREFLIGHT FALHOU em $(hostname): diretório não visível: $d" >&2
            bad=1
        fi
    done
    return $bad
}

# Acrescenta "<etapa> <start|end> <segundos-epoch>" a $EDU_TIMELINE (usado na seção 05).
edu_stamp() { printf '%s\t%s\t%s\n' "$1" "$2" "$(date +%s)" >> "${EDU_TIMELINE:?defina EDU_TIMELINE primeiro}"; }

# ---------------------------------------------------------------- verificação dos exercícios

EDU_FAILS=0
if [ -t 1 ]; then _G=$'\033[32m'; _R=$'\033[31m'; _Y=$'\033[33m'; _N=$'\033[0m'; else _G=""; _R=""; _Y=""; _N=""; fi

edu_pass() { printf '  %sOK   %s  %s\n' "$_G" "$_N" "$1"; }
edu_warn() { printf '  %sAVISO%s  %s\n' "$_Y" "$_N" "$1"; }
edu_fail() {
    printf '  %sFALHA%s  %s\n' "$_R" "$_N" "$1"
    [ -n "${2:-}" ] && printf '         dica: %s\n' "$2"
    EDU_FAILS=$((EDU_FAILS + 1))
}

# edu_expect_file <caminho> [dica]
edu_expect_file() {
    if [ -s "$1" ]; then edu_pass "encontrado $1"; else edu_fail "ausente ou vazio: $1" "${2:-}"; fi
}

# edu_expect_eq <descrição> <esperado> <obtido> [dica]
edu_expect_eq() {
    if [ "$2" = "$3" ]; then edu_pass "$1 ($3)"; else edu_fail "$1: esperado '$2', obtido '${3:-<nada>}'" "${4:-}"; fi
}

# Exit status de um job terminado, pelo histórico do PBS (vazio se o histórico estiver desligado).
edu_job_exit_status() { qstat -xf "$1" 2>/dev/null | awk -F' = ' '/Exit_status/ {print $2}'; }

edu_summary() {
    echo
    if [ "$EDU_FAILS" -eq 0 ]; then echo "Todas as verificações passaram. Bom trabalho!"; else echo "$EDU_FAILS verificação(ões) falharam -- leia as dicas acima e tente de novo."; fi
    return "$EDU_FAILS"
}
