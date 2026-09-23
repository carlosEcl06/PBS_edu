#!/bin/bash
#PBS -N pull_containers
#PBS -l select=1:ncpus=1:mem=4gb
#PBS -l walltime=00:45:00
#PBS -j oe

# Descarga en $SIF_CACHE las imágenes de contenedor listadas en containers.conf.
#
# Este mismo script funciona de las dos maneras:
#   ./pull_containers.sh          ejecutado directamente (en el nodo de login)
#   qsub pull_containers.sh       como job, si tu sitio pide no ejecutar trabajo
#                                 pesado en el nodo de login. Ojo: el job necesita
#                                 acceso a internet desde el nodo de cómputo.
# Las imágenes que ya existen se saltan, así que se puede volver a ejecutar sin miedo.

cd "${PBS_O_WORKDIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}" || exit 1
source ../lib/edu.sh || exit 1

mkdir -p "$SIF_CACHE/.cache" "$SIF_CACHE/.tmp"
# Las capas de las imágenes se guardan en caché (y se descomprimen) en algún sitio; por
# defecto en tu home, que a menudo tiene poca cuota. Mantenlas junto a las imágenes.
export APPTAINER_CACHEDIR="$SIF_CACHE/.cache" SINGULARITY_CACHEDIR="$SIF_CACHE/.cache"
export APPTAINER_TMPDIR="$SIF_CACHE/.tmp" SINGULARITY_TMPDIR="$SIF_CACHE/.tmp"

status=0
for tool in "${TOOLS[@]}"; do
    var="IMG_$tool"
    sif="$(edu_sif "$tool")"
    if [ -s "$sif" ]; then
        echo "ya está  $tool"
        continue
    fi
    echo "descargando  $tool  <-  docker://${!var}"
    if ! "$CONTAINER_RUNTIME" pull "$sif" "docker://${!var}"; then
        echo "FALLÓ la descarga de $tool" >&2
        rm -f "$sif"
        status=1
    fi
done

[ "$status" -eq 0 ] && echo "Todas las imágenes están en $SIF_CACHE" || echo "Algunas imágenes fallaron; vuelve a ejecutarlo para reintentar." >&2
exit "$status"
