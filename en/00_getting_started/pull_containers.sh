#!/bin/bash
#PBS -N pull_containers
#PBS -l select=1:ncpus=1:mem=4gb
#PBS -l walltime=00:45:00
#PBS -j oe

# Download the container images listed in containers.conf into $SIF_CACHE.
#
# This one script works both ways:
#   ./pull_containers.sh          run directly (on the login node)
#   qsub pull_containers.sh       as a job, if your site asks you not to run
#                                 heavy work on the login node. Note the job needs
#                                 internet access from the compute node.
# Images that already exist are skipped, so it is safe to re-run.

cd "${PBS_O_WORKDIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}" || exit 1
source ../lib/edu.sh || exit 1

mkdir -p "$SIF_CACHE/.cache" "$SIF_CACHE/.tmp"
# Image layers are cached (and unpacked) somewhere; by default that is your home
# directory, which often has a small quota. Keep it next to the images instead.
export APPTAINER_CACHEDIR="$SIF_CACHE/.cache" SINGULARITY_CACHEDIR="$SIF_CACHE/.cache"
export APPTAINER_TMPDIR="$SIF_CACHE/.tmp" SINGULARITY_TMPDIR="$SIF_CACHE/.tmp"

status=0
for tool in "${TOOLS[@]}"; do
    var="IMG_$tool"
    sif="$(edu_sif "$tool")"
    if [ -s "$sif" ]; then
        echo "have  $tool"
        continue
    fi
    echo "pull  $tool  <-  docker://${!var}"
    if ! "$CONTAINER_RUNTIME" pull "$sif" "docker://${!var}"; then
        echo "FAILED to pull $tool" >&2
        rm -f "$sif"
        status=1
    fi
done

[ "$status" -eq 0 ] && echo "All images are in $SIF_CACHE" || echo "Some images failed; re-run to retry." >&2
exit "$status"
