# 01 · Básico do PBS

**Você vai aprender:** escrever, submeter, acompanhar e depurar um job.
**Tempo:** 45 minutos.
**Antes de começar:** você terminou [00 · Primeiros passos](../00_getting_started/README.md) (`check_env.sh` passa).
**Por que isso importa em bioinformática:** toda etapa seguinte, seja trimming, alinhamento ou chamada de variantes, é "um script mais um pedido de recursos". Acerte isto e o resto é só trocar o comando lá dentro.

> **Convenção usada no curso inteiro:** submeta jobs *a partir do diretório da seção* (`cd 01_pbs_basics; qsub algo.pbs`). Os scripts usam `source ../lib/edu.sh` e o encontram através do diretório de onde você submeteu.

---

## 1. Anatomia de um script de job

Um script de job é um script de shell comum com linhas de comentário especiais no topo, que começam com `#PBS`. O `qsub` as lê como opções; o shell as ignora como comentários.

```bash
#!/bin/bash
#PBS -N count_reads
#PBS -l select=1:ncpus=1:mem=1gb
#PBS -l walltime=00:05:00
#PBS -j oe

cd "$PBS_O_WORKDIR" || exit 1
echo "hello from $(hostname)"
```

| Linha | Significado |
|---|---|
| `-N count_reads` | **nome** do job, mostrado no `qstat` e usado nos nomes dos arquivos de log. Comece com letra, sem espaços. |
| `-l select=1:ncpus=1:mem=1gb` | o **pedido de recursos**: 1 *chunk* (um pacote de recursos colocado num único nó) com 1 núcleo de CPU e 1 GB de memória. |
| `-l walltime=00:05:00` | tempo máximo de execução, `HH:MM:SS`. **O PBS mata o job quando ele expira**, não importa o que esteja fazendo. |
| `-j oe` | **j**unta o stderr (**e**) ao stdout (**o**): um arquivo de log em vez de dois. |
| `cd "$PBS_O_WORKDIR"` | jobs **começam na sua home**, não onde você rodou o `qsub`. Esta linha volta para lá. Esquecê-la é o primeiro erro clássico. |

Opcionais, mas úteis: `-o <arquivo>` / `-e <arquivo>` dão nome aos arquivos de log (padrão: `<nome>.o<jobid>` e `<nome>.e<jobid>`, criados no diretório de onde você submeteu).

**Comentários em linhas `#PBS`:** coloque-os numa linha própria, nunca depois da opção (`#PBS -N x   # meu job`). Algumas versões do PBS leem o resto da linha como parte da opção e falham de formas confusas. Todos os scripts daqui seguem essa regra.

**Escolhendo os números:** não chute alto demais. Peça um pouco mais do que o job precisa: pouco demais e ele é morto; demais e ele espera mais na fila e desperdiça recursos compartilhados. A seção 03 mostra como medir.

## 2. Submeter e acompanhar

```bash
qsub example_hello_world.pbs      # imprime um id de job, ex.: 12345.meuservidor
qstat -u $USER                    # seus jobs. Olhe a coluna S (estado)
qstat -f 12345                    # tudo sobre um job
qdel 12345                        # cancela o job
qstat -x -u $USER                 # inclui jobs TERMINADOS (se o site guarda histórico)
qstat -xf 12345                   # detalhes completos de um job terminado: Exit_status, resources_used
```

Estados: **Q** na fila · **R** rodando · **H** retido · **E** saindo · **F** terminado (só visível com `-x`).

Quando o job termina, o PBS escreve `hello.o12345` no seu diretório de submissão. Leia com `cat`. **O log só aparece quando o job termina**, não enquanto ele roda, então o arquivo `.o` de um job em execução pode ainda não existir. Isso é normal. Para jobs longos, escreva o progresso no seu próprio arquivo de log no sistema de arquivos compartilhado.

> **Para onde vão meus arquivos de saída?** Dois lugares diferentes, de propósito:
> - o **log** (`count_reads.o12345`) é escrito pelo PBS no diretório de onde você submeteu;
> - os **arquivos de resultado** que seu script cria vão para sua área de saída, `$WORKDIR` do `site.conf`, numa subpasta por seção. Dentro de cada diretório de seção, **`results/`** é um atalho para essa pasta (ele é criado na primeira vez que um job ou verificador roda): `ls results/`, `cat results/fastq_counts.tsv`.
>
> Quer o caminho real? `source ../lib/edu.sh; echo $WORKDIR`. (`$WORKDIR` não está definido no seu shell de login até você dar `source` nesse arquivo.)

## 3. Experimente

```bash
cd 01_pbs_basics
qsub example_hello_world.pbs
qstat -u $USER            # repita até o job sumir
cat hello.o*              # repare em "Diretório quando o job começou"
qsub example_count_reads.pbs
```

`example_hello_world.pbs` mostra onde o job começou (na sua home!) e para onde foi depois do `cd`. `example_count_reads.pbs` é seu primeiro job de bioinformática: conta reads e bases nos dois arquivos FASTQ reais usando `zcat` e `awk`. Leia o script e depois olhe o resultado: a tabela também é salva num arquivo, `results/fastq_counts.tsv` (veja o quadro acima: `results/` é para onde vão os arquivos de saída de todos os seus jobs).

**Perguntas para responder a partir dos logs** (não precisa anotar em lugar nenhum):
1. Em qual nó seu job rodou? É o nó de login?
2. O que `qstat -xf <jobid>` disse para `Exit_status`, `resources_used.walltime` e `resources_used.mem`?
3. Quantas CPUs o job acha que tem? (`NCPUS`)

## 4. Exercícios

Cada exercício tem um **verificador** que olha a saída real do seu job e diz o que está errado. As soluções estão em `solutions/`: espie só depois de tentar.

### 1a · Preencha as lacunas (10 min)
Edite `exercise_01a_fill_in_blanks.pbs` substituindo cada `___`. Submeta, espere terminar e rode `./check_01a.sh`.

### 1b · Conserte o job quebrado (15 min)
`exercise_01b_fix_the_job.pbs` tem três bugs independentes que aparecem um depois do outro: um na submissão, um quando o job começa, um enquanto ele roda. Submeta, leia o que deu errado, corrija um bug, repita. Depois `./check_01b.sh`.

### 1c · Escreva um job do zero (15 min)
Escreva você mesmo `my_reference_stats.pbs`. Requisitos:

- 1 CPU, 1 GB, 5 minutos, um nome à sua escolha, logs juntados.
- Leia `$DATA_DIR/ref/genome.fasta` (o genoma de referência) e escreva `reference_stats.txt` em `$WORKDIR/01_pbs_basics/` (ou seja, `results/` a partir deste diretório) com exatamente estas cinco linhas (as chaves ficam em inglês, é o que o verificador procura):

  ```
  sequences: <número de registros FASTA>
  length: <número total de bases>
  gc_percent: <porcentagem de G e C, 2 casas decimais>
  job_id: <$PBS_JOBID>
  host: <saída de hostname, de dentro do job>
  ```
- Dica: linhas de cabeçalho começam com `>`; o `awk` sabe contar caracteres; `gsub(/[GC]/, "")` devolve quantos ele substituiu. `printf "%.2f"` imprime duas casas decimais.

Depois `./check_01c.sh`. O conteúdo GC é uma métrica real: varia entre organismos e ajuda a detectar contaminação.

## Confira se aprendeu

Você terminou quando puder responder "sim" a tudo isto:
- [ ] Sei explicar por que meu job precisa de `cd "$PBS_O_WORKDIR"`.
- [ ] Sei o que acontece quando um job passa do walltime, e onde ver isso (`Exit_status`).
- [ ] Sei achar o log de um job terminado e o nó em que ele rodou.
- [ ] `check_01a.sh`, `check_01b.sh`, `check_01c.sh` passam.

## Se algo der errado

| O que você vê | O que fazer |
|---|---|
| `qsub: Unknown resource ...` / `Illegal attribute or resource value` | Uma linha `#PBS` tem um erro de digitação (`ncpu` em vez de `ncpus`, falta o `gb`, lacuna deixada como `___`). |
| O job fica em `Q` por muito tempo | O cluster está ocupado ou você pediu mais do que qualquer nó tem. `qstat -f <id> \| grep -i comment`. |
| Ainda não há arquivo `.o` e o job está em `R` | Esperado: ele aparece no final. |
| O log diz `No such file or directory` para `../lib/edu.sh` | Você esqueceu o `cd "$PBS_O_WORKDIR"`, ou submeteu de um diretório diferente do diretório da seção. |
| O log para de repente, `Exit_status = 271` | Morto pelo PBS, muito provavelmente por estourar o walltime. |
| O job terminou mas os arquivos de resultado não existem | Leia o log até o fim; o script provavelmente falhou no meio. |

## Próximo passo: continuar em inglês

As seções 02 a 08 ainda não foram traduzidas. Você pode seguir na versão em inglês reaproveitando tudo o que já configurou (dados, imagens e resultados ficam onde estão, porque o `site.conf` guarda caminhos absolutos). A partir da pasta `pt/`:

```bash
cp site.conf ../en/site.conf
cd ../en/02_containers
```

Próximo: [02 · Containers](../../en/02_containers/README.md) (em inglês)
