# 01 — Básico de PBS: submeter, checar, cancelar

O PBS (este cluster roda OpenPBS) agenda seu job num nó de computação e o executa lá,
em vez de no nó em que você estiver logado no momento. Um job PBS é só um script de
shell com algumas linhas especiais de comentário `#PBS` no topo, dizendo ao
escalonador quais recursos você precisa.

## Os três comandos que você vai usar o tempo todo

```bash
qsub meu_job.pbs          # submete um job, imprime seu ID (ex.: "3120.pne2")
qstat -u $(whoami)        # lista seus jobs e o estado de cada um
qdel 3120.pne2             # cancela um job (rodando ou na fila)
```

Estados de job que você vai ver no `qstat`: `Q` (na fila, esperando recursos), `R`
(rodando), e assim que termina o job simplesmente some da listagem padrão do `qstat`
(use `qstat -x 3120.pne2` para ver as informações de um job já terminado, ou
`qstat -xf` para o detalhe completo, incluindo o código de saída).

## Anatomia de um script de job mínimo

```bash
#!/bin/bash
#PBS -N meu_primeiro_job      # um nome para o job (aparece no qstat)
#PBS -q workq                 # a fila -- workq é a padrão aqui
#PBS -l select=1:ncpus=1:mem=1gb   # 1 nó, 1 CPU, 1GB de RAM
#PBS -l walltime=00:05:00     # mata o job se ainda estiver rodando após 5 minutos
#PBS -o meu_job.out           # para onde vai o stdout (escrito quando o job termina)
#PBS -e meu_job.err           # para onde vai o stderr

echo "Olá de $(hostname), rodando como job $PBS_JOBID"
date
sleep 10
echo "Terminado."
```

Salve isso como `meu_job.pbs` e submeta com `qsub meu_job.pbs`. Algumas coisas que vale
a pena saber antes de fazer isso:

- **`walltime` é um limite rígido.** Se seu job ainda estiver rodando quando o tempo
  acaba, o PBS o mata. Sempre deixe uma margem real acima do que você espera que o job
  leve de verdade — um job morto no meio pode deixar saída parcial/corrompida, o que é
  uma experiência de depuração bem pior do que um job que simplesmente termina um pouco
  cedo.
- **`-o`/`-e` geralmente só são escritos quando o job termina**, não em tempo real,
  nesta configuração específica de PBS. Não se assuste se o arquivo de saída ainda não
  existir enquanto o `qstat` mostra o job como `R` — isso é normal aqui, não é sinal de
  que algo está errado.
- **O script roda no nó de computação que o PBS designar**, partindo de onde o `qsub`
  foi executado como contexto de diretório de trabalho (caminhos no seu script devem
  geralmente ser absolutos, ou você deve dar `cd` explicitamente primeiro, para evitar
  ambiguidade).
- **Linhas de diretiva `#PBS` não suportam comentários no final da linha** nesta
  configuração — `#PBS -l ncpus=2  # meu comentário` vai falhar com um `directive
  error`, porque o interpretador trata tudo depois do `-l` como texto da diretiva, não
  como comentário de shell a ser descartado. Coloque comentários explicativos em uma
  linha própria, acima da diretiva. (Descobri isso da primeira vez de verdade
  submetendo os scripts de exercício abaixo para conferir se funcionavam — vale a pena
  fazer isso sempre que você escrever um script novo, não só confiar que está certo.)

## Experimente

Rode o exemplo funcional primeiro, exatamente como está, para ver o ciclo completo de
submeter → esperar → checar:

```bash
qsub example_hello_world.pbs
qstat -u $(whoami)
# espere alguns segundos, depois:
cat example_hello_world.out
```

Depois abra `exercise_01_fill_in_blanks.pbs`, preencha as lacunas (marcadas com `___`),
e submeta sua própria versão. Se ficar travado(a), `exercise_01_ANSWER.pbs` tem uma
solução pronta — mas tente sozinho(a) primeiro, essa é a ideia.
