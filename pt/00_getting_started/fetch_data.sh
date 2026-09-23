#!/bin/bash
# Baixa os pequenos conjuntos de dados reais usados no curso para $DATA_DIR:
#
#   ref/genome.fasta, ref/genome.gff3      referência do SARS-CoV-2 (29,8 kb) e sua anotação
#   real/test_{1,2}.fastq.gz               100 pares de reads Illumina reais
#
# Ambos vêm dos test-datasets públicos do nf-core. As amostras simuladas maiores
# são criadas depois por um job (make_samples.pbs). Download total: cerca de 60 KB.
#
# Rode num nó com acesso à internet (normalmente o nó de login). Sem internet?
# Baixe as URLs abaixo em outra máquina, copie os arquivos para os mesmos
# subdiretórios de $DATA_DIR e rode este script de novo para verificá-los.

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
    else echo "é preciso ter curl ou wget" >&2; return 1; fi
}

mkdir -p "$DATA_DIR/ref" "$DATA_DIR/real"
for entry in "${FILES[@]}"; do
    read -r src dest <<< "$entry"
    if [ -s "$DATA_DIR/$dest" ]; then
        echo "já tem  $dest"
    elif download "$BASE_URL/$src" "$DATA_DIR/$dest"; then
        echo "baixado $dest"
    else
        rm -f "$DATA_DIR/$dest"
        echo "FALHOU  $dest  <-  $BASE_URL/$src" >&2
    fi
done

echo
echo "Verificando os checksums..."
if (cd "$DATA_DIR" && sha256sum -c "$HERE/data.sha256"); then
    echo "Dados prontos em $DATA_DIR"
else
    echo "Alguns arquivos estão faltando ou diferem dos checksums esperados (veja acima)." >&2
    exit 1
fi
