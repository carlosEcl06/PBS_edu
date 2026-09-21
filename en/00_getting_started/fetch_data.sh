#!/bin/bash
# Download the small real datasets used by the course into $DATA_DIR:
#
#   ref/genome.fasta, ref/genome.gff3      SARS-CoV-2 reference (29.8 kb) and its annotation
#   real/test_{1,2}.fastq.gz               100 real Illumina read pairs
#
# Both come from the public nf-core test-datasets. The larger simulated samples
# are made later by a job (make_samples.pbs). Total download: about 60 KB.
#
# Run on a node with internet access (usually the login node). No internet?
# Download the URLs below on another machine and copy the files to the same
# sub-directories of $DATA_DIR, then re-run this script to verify them.

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

download() { # download <url> <dest>
    if command -v curl >/dev/null 2>&1; then curl -fsSL --retry 3 -o "$2" "$1"
    elif command -v wget >/dev/null 2>&1; then wget -q -O "$2" "$1"
    else echo "need curl or wget" >&2; return 1; fi
}

mkdir -p "$DATA_DIR/ref" "$DATA_DIR/real"
for entry in "${FILES[@]}"; do
    read -r src dest <<< "$entry"
    if [ -s "$DATA_DIR/$dest" ]; then
        echo "have   $dest"
    elif download "$BASE_URL/$src" "$DATA_DIR/$dest"; then
        echo "got    $dest"
    else
        rm -f "$DATA_DIR/$dest"
        echo "FAILED $dest  <-  $BASE_URL/$src" >&2
    fi
done

echo
echo "Verifying checksums..."
if (cd "$DATA_DIR" && sha256sum -c "$HERE/data.sha256"); then
    echo "Data ready in $DATA_DIR"
else
    echo "Some files are missing or differ from the expected checksums (see above)." >&2
    exit 1
fi
