# 00 · Primeiros passos

**Você vai aprender:** o que é um cluster, como pôr este curso para funcionar no seu e como provar que funciona.
**Tempo:** 20–30 minutos (a maior parte esperando downloads e um job pequeno).
**Você precisa de:** uma conta num cluster PBS e um terminal. Noções básicas de shell (`cd`, `ls`, `cat`, editar um arquivo com `nano` ou `vim`).

---

## 1. O modelo mental em 2 minutos

Um **cluster** é um grupo de computadores ("**nós**") que compartilham armazenamento, gerenciados por um **escalonador**. O PBS é esse escalonador.

```
   você ──ssh──▶  nó de login ──qsub──▶  escalonador (PBS) ──▶ nó de computação 1
                  (compartilhado,                          ├─▶ nó de computação 2
                   só trabalho leve)                       └─▶ nó de computação …
                        └──── sistema de arquivos compartilhado: todos veem os mesmos arquivos ────┘
```

| Lugar | O que você faz lá | O que você não deve fazer lá |
|---|---|---|
| **Nó de login** | entrar, editar arquivos, submeter e acompanhar jobs, mover dados | rodar análises. Ele é compartilhado por todos; um comando pesado deixa todos os seus colegas mais lentos |
| **Nós de computação** | os *jobs* rodam aqui, iniciados para você pelo PBS | entrar diretamente (você chega a eles através do PBS) |

Um **job** é só um script de shell mais um pedido: *"me dê 4 CPUs e 8 GB de memória por até 2 horas e rode isto."* O PBS coloca o pedido na fila, encontra um nó com espaço, roda o script lá e guarda a saída. Essa é a ideia inteira; todo o resto do curso é detalhe em cima disso.

**Por que a bioinformática precisa disso:** alinhar 100 amostras, ou uma amostra contra um genoma grande, exige mais CPUs e memória do que um notebook tem, e você quer que continue rodando depois de fechar o notebook.

## 2. Conectar e obter o material

```bash
ssh <seu-usuario>@<endereco-do-no-de-login>   # peça o endereço à administração do cluster
git clone <url-deste-repositorio> PBS_edu     # ou copie a pasta com: scp -r PBS_edu <voce>@<no-de-login>:~/
cd PBS_edu/pt
```

Movendo arquivos entre seu notebook e o cluster:

```bash
scp results.tsv <voce>@<no-de-login>:~/                 # notebook -> cluster
rsync -avP <voce>@<no-de-login>:~/results/ ./results/   # cluster -> notebook, retomável
```

## 3. Configuração (três comandos e um job)

Rode estes comandos de dentro de `00_getting_started/`:

```bash
./setup.sh              # 1. descobre sua fila, a ferramenta de containers e pergunta onde guardar os dados
./fetch_data.sh         # 2. baixa um conjunto de dados real minúsculo (cerca de 60 KB)
./pull_containers.sh    # 3. baixa as ferramentas de bioinformática como imagens de container (alguns minutos)
qsub make_samples.pbs   # 4. SEU PRIMEIRO JOB: simula 6 amostras de reads de sequenciamento
```

O `qsub` imprime um **id de job** como `12345.meuservidor`. Acompanhe com `qstat -u $USER`: o estado `Q` (na fila) vira `R` (rodando) e depois o job some (terminou). Leva um ou dois minutos. Então:

```bash
./check_env.sh          # verifica tudo, incluindo um job de teste de 10 segundos num nó de computação
```

No final você quer ver `Todas as verificações passaram.`

### O que esses comandos fizeram?

- **`setup.sh`** escreveu `../site.conf`: um arquivo pequeno com as particularidades do seu cluster (nome da fila, onde ficam os dados, se a ferramenta é `apptainer` ou `singularity`). Todos os scripts do curso o leem, então *nada nos exercícios está amarrado a um cluster específico*. Abra e leia.
- **`fetch_data.sh`** baixou um genoma de SARS-CoV-2 de 29,8 kb e 100 pares de reads reais. Minúsculos de propósito: as seções 01 e 02 terminam em segundos.
- **`pull_containers.sh`** baixou as ferramentas (seqkit, FastQC, fastp, minimap2, samtools, wgsim) como **imagens de container**. Um container empacota um programa com tudo o que ele precisa, então não há nada para instalar e todos rodam versões idênticas. A seção 02 explica isso direito.
- **`make_samples.pbs`** é um job de verdade: roda o `wgsim` para simular 6 amostras × 300.000 pares de reads. As seções 03–05 as usam porque são grandes o bastante para tornar CPU, memória e tempo visíveis.

### Onde as coisas vão parar

- **Logs** dos seus jobs (`make_samples.o12345`): no diretório de onde você submeteu.
- **Dados, imagens, resultados:** nos diretórios definidos em `site.conf` (`DATA_DIR`, `SIF_CACHE`, `WORKDIR`). Para usar esses nomes no seu próprio shell, carregue antes o arquivo de funções: `source ../lib/edu.sh; echo $DATA_DIR`.
- Em todas as seções seguintes, `results/` dentro do diretório da seção é um atalho para a pasta de saída daquela seção.

## 4. FASTQ em 60 segundos

Sequenciadores produzem arquivos **FASTQ**: 4 linhas por read.

```
@read_1              <- nome
GATTTGGGGTTCAAAGCAG  <- a sequência de DNA
+
IIIIIIIIIIIIIIIIIII  <- uma nota de qualidade por base (I = muito boa)
```

Sequenciamento paired-end gera dois arquivos por amostra (`_R1`, `_R2`); o read *n* de um faz par com o read *n* do outro. `.gz` significa comprimido com gzip; leia com `zcat arquivo.fastq.gz | head`. Um **genoma de referência** é um arquivo FASTA (uma linha `>nome`, depois a sequência). *Alinhar* reads a uma referência (seção 03) é a etapa pesada clássica que motiva o uso de clusters.

## Se algo der errado

| Sintoma | Causa provável e solução |
|---|---|
| `qsub: command not found` | Você não está no nó de login, ou o PBS precisa de `module load`. Pergunte à administração / tente `module avail pbs`. |
| `qsub: ... queue ... required` ou "no default queue" | Coloque o nome da fila em `EDU_QUEUE` no `site.conf` (`qstat -Q` lista as filas) e use `edu_qsub` ou `qsub -q <fila>`. |
| `apptainer: command not found` | Tente `module avail apptainer` (ou `singularity`) e faça `module load`; ou rode `pull_containers.sh` como job (`qsub pull_containers.sh`). |
| O download da imagem falha / expira | O nó pode estar sem internet ou precisar de proxy. Pergunte à administração; as imagens podem ser baixadas em outro lugar e copiadas para `sif/` como `<ferramenta>.sif`. |
| O job `make_samples` fica em `Q` | O cluster está ocupado. `qstat -f <jobid> \| grep -i comment` diz o motivo. |
| `check_env.sh` diz que o job de teste falhou | Leia o log que ele imprime. Causa típica: `DATA_DIR` está num disco que os nós de computação não enxergam. Rode `setup.sh` de novo com um diretório compartilhado. |
| `No space left` / erros de cota | Aponte a configuração para uma área maior, ou diminua `READS_PER_SAMPLE` no `site.conf`. |

Pronto? Vá para [01 · Básico do PBS](../01_pbs_basics/README.md). Travou numa palavra? Veja o [glossário](../../en/GLOSSARY.md) (em inglês).
