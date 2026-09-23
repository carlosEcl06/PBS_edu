#!/bin/bash
#PBS -N pull_containers
#PBS -l select=1:ncpus=1:mem=4gb
#PBS -l walltime=00:45:00
#PBS -j oe

# Baixa as imagens de container listadas em containers.conf para $SIF_CACHE.
#
# Este mesmo script funciona dos dois jeitos:
#   ./pull_containers.sh          rodado direto (no nó de login)
#   qsub pull_containers.sh       como job, se o seu site pede para não rodar
#                                 trabalho pesado no nó de login. Atenção: o job
#                                 precisa de acesso à internet a partir do nó de computação.
# Imagens que já existem são puladas, então pode rodar de novo sem medo.

cd "${PBS_O_WORKDIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}" || exit 1
source ../lib/edu.sh || exit 1

mkdir -p "$SIF_CACHE/.cache" "$SIF_CACHE/.tmp"
# As camadas das imagens ficam em cache (e são descompactadas) em algum lugar; por
# padrão, na sua home, que muitas vezes tem cota pequena. Mantenha junto das imagens.
export APPTAINER_CACHEDIR="$SIF_CACHE/.cache" SINGULARITY_CACHEDIR="$SIF_CACHE/.cache"
export APPTAINER_TMPDIR="$SIF_CACHE/.tmp" SINGULARITY_TMPDIR="$SIF_CACHE/.tmp"

status=0
for tool in "${TOOLS[@]}"; do
    var="IMG_$tool"
    sif="$(edu_sif "$tool")"
    if [ -s "$sif" ]; then
        echo "já tem  $tool"
        continue
    fi
    echo "baixando  $tool  <-  docker://${!var}"
    if ! "$CONTAINER_RUNTIME" pull "$sif" "docker://${!var}"; then
        echo "FALHOU ao baixar $tool" >&2
        rm -f "$sif"
        status=1
    fi
done

[ "$status" -eq 0 ] && echo "Todas as imagens estão em $SIF_CACHE" || echo "Algumas imagens falharam; rode de novo para tentar outra vez." >&2
exit "$status"
