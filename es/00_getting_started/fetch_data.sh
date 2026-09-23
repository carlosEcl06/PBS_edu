#!/bin/bash
# Descarga en $DATA_DIR los pequeños conjuntos de datos reales que usa el curso:
#
#   ref/genome.fasta, ref/genome.gff3      referencia de SARS-CoV-2 (29,8 kb) y su anotación
#   real/test_{1,2}.fastq.gz               100 pares de lecturas Illumina reales
#
# Ambos vienen de los test-datasets públicos de nf-core. Las muestras simuladas,
# más grandes, las crea después un job (make_samples.pbs). Descarga total: unos 60 KB.
#
# Ejecútalo en un nodo con acceso a internet (normalmente el nodo de login). ¿Sin
# internet? Descarga las URL de abajo en otra máquina, copia los archivos a los
# mismos subdirectorios de $DATA_DIR y vuelve a ejecutar este script para verificarlos.

set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../lib/edu.sh" || exit 1

BASE_URL="https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/sarscov2"
FILES=(
    "genome/genome.fasta        ref/genome.fasta"
    "genome/genome.gff3         ref/genome.gff3"
    "illumina/fastq/test_1.fastq.gz  real/test_1.fastq.gz"
    "illumina/fastq/test_2.fastq.gz  real/test_2.fastq.gz"
)

download() { # download <url> <destino>
    if command -v curl >/dev/null 2>&1; then curl -fsSL --retry 3 -o "$2" "$1"
    elif command -v wget >/dev/null 2>&1; then wget -q -O "$2" "$1"
    else echo "hace falta curl o wget" >&2; return 1; fi
}

mkdir -p "$DATA_DIR/ref" "$DATA_DIR/real"
for entry in "${FILES[@]}"; do
    read -r src dest <<< "$entry"
    if [ -s "$DATA_DIR/$dest" ]; then
        echo "ya está    $dest"
    elif download "$BASE_URL/$src" "$DATA_DIR/$dest"; then
        echo "descargado $dest"
    else
        rm -f "$DATA_DIR/$dest"
        echo "FALLÓ      $dest  <-  $BASE_URL/$src" >&2
    fi
done

echo
echo "Verificando las sumas de comprobación..."
if (cd "$DATA_DIR" && sha256sum -c "$HERE/data.sha256"); then
    echo "Datos listos en $DATA_DIR"
else
    echo "Algunos archivos faltan o no coinciden con las sumas de comprobación esperadas (ver arriba)." >&2
    exit 1
fi
