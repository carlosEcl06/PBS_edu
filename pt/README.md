# PBS_edu — agendamento de jobs neste cluster compartilhado

Um guia prático para rodar jobs de computação neste servidor da forma correta:
usando o escalonador PBS, nunca no nó de login, com containers fixados em versões
exatas. Os exemplos aqui vêm de um pipeline real de filogenômica construído neste
mesmo servidor — inclusive alguns dos problemas que apareceram no caminho.

## Por que isso existe

Este é um servidor compartilhado, usado por várias pessoas ao mesmo tempo. O nó de
login (`pne2`) serve para editar arquivos, submeter jobs e fazer orquestração leve —
**não para rodar nada que use CPU ou memória de verdade**. Os jobs de todo mundo passam
pelo PBS, que os distribui entre os nós de computação (`pne3` até `pne10`,
disponibilidade varia). Se você rodar sua análise direto no `pne2` em vez de submetê-la
como job, você não está só quebrando uma regra — está usando CPU que pertence ao nó
compartilhado de login/orquestração, do qual todo mundo depende (inclusive quem só
quer dar um `cd` e checar o status do próprio job).

A boa notícia: depois que você faz duas ou três vezes, submeter um job PBS não é mais
difícil do que rodar um comando direto. Este guia leva você até lá.

## Como usar esta pasta

Percorra os diretórios numerados em ordem. Cada um tem:
- um `README.md` explicando o conceito,
- um ou mais **exemplos funcionais** que você pode submeter como estão para ver como é
  um job de verdade, do início ao fim,
- um ou mais **exercícios** — o mesmo tipo de script, mas com partes importantes em
  branco (`___`), para você preencher e submeter sozinho(a).

Nada aqui mexe em dados reais de projeto. Todo exercício submete um job trivial (roda
em segundos, usa recursos mínimos) para você poder iterar rápido sem se preocupar em
consumir recursos compartilhados enquanto ainda está aprendendo.

1. **`01_basico_pbs/`** — submeter, checar e cancelar um job. Comece por aqui mesmo se
   já usou PBS/Slurm em outro lugar — as flags e as particularidades mudam de cluster
   para cluster.
2. **`02_selecao_de_nos/`** — checar quais nós de computação estão realmente livres, e
   fixar seu job explicitamente em um deles. Importa mais aqui do que em alguns outros
   clusters, por motivos explicados nessa seção.
3. **`03_containers_apptainer/`** — rodar software a partir de um container em vez de
   brigar com resolução de dependências do `conda`/`module load`. Esse é o padrão
   recomendado para qualquer ferramenta que não seja trivial de instalar.
4. **`04_problemas_comuns/`** — bugs reais encontrados construindo um pipeline de
   produção neste exato servidor, escritos como lições em vez de deixados apenas como
   conhecimento tácito.
5. **`05_nextflow_avancado/`** (opcional, depois que o básico estiver natural) —
   orquestrar um pipeline com várias etapas (muitos jobs, dependências entre eles) com
   o executor PBS do Nextflow em vez de encadear `qsub` manualmente.

## A versão de um parágrafo, se você não ler mais nada

Nunca rode computação de verdade no `pne2`. Antes de submeter um job, cheque quais nós
de computação estão realmente livres (`pbsnodes <nó>`) em vez de simplesmente assumir —
este servidor nem sempre suporta excluir um nó específico, só fixar *em* um, então se
você não checar antes pode acabar preso na fila atrás do job de outra pessoa, ou
agendado silenciosamente num nó com um problema conhecido. Prefira containers
Apptainer fixados numa versão exata a `conda`/pacotes do sistema para qualquer coisa
além de um script de uma linha. E quando um job baseado em container não conseguir
encontrar um arquivo que está visível no seu shell de login, verifique se o caminho
está realmente montado (bind-mount) dentro do container antes de assumir que seus
dados sumiram — veja `04_problemas_comuns/`.
