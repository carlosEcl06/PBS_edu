#!/bin/bash
# Télécharge dans $DATA_DIR les petits jeux de données réels utilisés par le cours :
#
#   ref/genome.fasta, ref/genome.gff3      référence SARS-CoV-2 (29,8 kb) et son annotation
#   real/test_{1,2}.fastq.gz               100 vraies paires de lectures Illumina
#
# Les deux viennent des test-datasets publics de nf-core. Les échantillons simulés,
# plus gros, sont créés ensuite par un job (make_samples.pbs). Téléchargement total : environ 60 Ko.
#
# Lancez-le sur un nœud qui a accès à internet (en général le nœud de connexion).
# Pas d'internet ? Téléchargez les URL ci-dessous sur une autre machine, copiez les
# fichiers dans les mêmes sous-répertoires de $DATA_DIR, puis relancez ce script pour les vérifier.

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

download() { # download <url> <destination>
    if command -v curl >/dev/null 2>&1; then curl -fsSL --retry 3 -o "$2" "$1"
    elif command -v wget >/dev/null 2>&1; then wget -q -O "$2" "$1"
    else echo "il faut curl ou wget" >&2; return 1; fi
}

mkdir -p "$DATA_DIR/ref" "$DATA_DIR/real"
for entry in "${FILES[@]}"; do
    read -r src dest <<< "$entry"
    if [ -s "$DATA_DIR/$dest" ]; then
        echo "déjà là  $dest"
    elif download "$BASE_URL/$src" "$DATA_DIR/$dest"; then
        echo "reçu     $dest"
    else
        rm -f "$DATA_DIR/$dest"
        echo "ÉCHEC    $dest  <-  $BASE_URL/$src" >&2
    fi
done

echo
echo "Vérification des sommes de contrôle..."
if (cd "$DATA_DIR" && sha256sum -c "$HERE/data.sha256"); then
    echo "Données prêtes dans $DATA_DIR"
else
    echo "Certains fichiers manquent ou diffèrent des sommes de contrôle attendues (voir ci-dessus)." >&2
    exit 1
fi
