#!/bin/bash
#PBS -N pull_containers
#PBS -l select=1:ncpus=1:mem=4gb
#PBS -l walltime=00:45:00
#PBS -j oe

# Télécharge dans $SIF_CACHE les images de conteneur listées dans containers.conf.
#
# Ce même script marche des deux façons :
#   ./pull_containers.sh          lancé directement (sur le nœud de connexion)
#   qsub pull_containers.sh       comme job, si votre site demande de ne pas lancer
#                                 de travail lourd sur le nœud de connexion. Attention :
#                                 le job a besoin d'internet depuis le nœud de calcul.
# Les images déjà présentes sont sautées, donc il peut être relancé sans risque.

cd "${PBS_O_WORKDIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}" || exit 1
source ../lib/edu.sh || exit 1

mkdir -p "$SIF_CACHE/.cache" "$SIF_CACHE/.tmp"
# Les couches des images sont mises en cache (et décompressées) quelque part ; par
# défaut dans votre home, qui a souvent un petit quota. Gardez-les à côté des images.
export APPTAINER_CACHEDIR="$SIF_CACHE/.cache" SINGULARITY_CACHEDIR="$SIF_CACHE/.cache"
export APPTAINER_TMPDIR="$SIF_CACHE/.tmp" SINGULARITY_TMPDIR="$SIF_CACHE/.tmp"

status=0
for tool in "${TOOLS[@]}"; do
    var="IMG_$tool"
    sif="$(edu_sif "$tool")"
    if [ -s "$sif" ]; then
        echo "déjà là  $tool"
        continue
    fi
    echo "téléchargement  $tool  <-  docker://${!var}"
    if ! "$CONTAINER_RUNTIME" pull "$sif" "docker://${!var}"; then
        echo "ÉCHEC du téléchargement de $tool" >&2
        rm -f "$sif"
        status=1
    fi
done

[ "$status" -eq 0 ] && echo "Toutes les images sont dans $SIF_CACHE" || echo "Certaines images ont échoué ; relancez pour réessayer." >&2
exit "$status"
