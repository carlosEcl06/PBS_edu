# PBS para bioinformática: um curso prático

> [!NOTE]
> **Tradução em andamento.** As seções **00** e **01** estão traduzidas e em dia com o curso em inglês.
> As seções **02 a 08** ainda existem só [em inglês](../en/README.md): os links do roteiro abaixo levam
> direto a elas, e você pode continuar lá com a mesma configuração (veja o fim da [seção 01](01_pbs_basics/README.md#próximo-passo-continuar-em-inglês)).

Aprenda a rodar análises reais num cluster de computação compartilhado com o PBS, fazendo. Cada exercício é um
job que você submete, roda sobre dados de sequenciamento reais (ou simulados de forma realista) com ferramentas
reais, e confere com um verificador automático.

**Para quem é:** biólogos, estudantes e analistas que conhecem o básico de Linux (`cd`, `ls`, `nano`) e acabaram de
receber uma conta num cluster.
**O que você vai conseguir fazer depois:** escrever e submeter scripts de job, escolher CPU/memória/tempo com
critério, processar muitas amostras em paralelo, encadear etapas num pipeline, rodar ferramentas a partir de
containers e descobrir por que um job falhou.
**Tempo:** cerca de 6–8 horas no total; cada seção se sustenta sozinha (45–60 min) e se apoia na anterior.

---

## Por que um curso? A versão de um parágrafo

Um cluster é compartilhado por muita gente. Você entra num **nó de login** para preparar o trabalho e submete
**jobs** a um escalonador (PBS), que os roda em **nós de computação** quando há recursos livres. Análises que
precisam de CPU ou memória de verdade vão em jobs, nunca no nó de login. Essa regra, mais um punhado de comandos
(`qsub`, `qstat`, `qdel`), cobre 90% do uso diário. O resto do curso são os outros 10%: fazer isso com eficiência
e consertar quando quebra.

## O roteiro

| # | Seção | Você vai | Dados / ferramentas | Tradução |
|---|---|---|---|---|
| 00 | [Primeiros passos](00_getting_started/README.md) | conectar, rodar a configuração, submeter seu primeiro job | referência do SARS-CoV-2 + reads reais | ✅ em dia |
| 01 | [Básico do PBS](01_pbs_basics/README.md) | escrever, submeter, acompanhar e depurar um job | zcat, awk | ✅ em dia |
| 02 | [Containers](../en/02_containers/README.md) | rodar ferramentas de bioinformática sem instalá-las | seqkit, FastQC | ⏳ só em inglês |
| 03 | [Recursos e threads](../en/03_resources_threads/README.md) | medir um job e pedir as CPUs, memória e tempo certos | minimap2, samtools | ⏳ só em inglês |
| 04 | [Job arrays](../en/04_job_arrays/README.md) | um job por amostra, rodar de novo só as falhas | fastp, seqkit | ⏳ só em inglês |
| 05 | [Pipelines e dependências](../en/05_pipelines_dependencies/README.md) | encadear QC → alinhamento → resumo | fastp, minimap2, samtools | ⏳ só em inglês |
| 06 | [Jobs interativos e nós](../en/06_interactive_and_nodes/README.md) | testar ao vivo num nó de computação, ler o estado dos nós | pbsnodes | ⏳ só em inglês |
| 07 | [Solução de problemas](../en/07_troubleshooting/README.md) | diagnosticar seis jobs quebrados | logs, qstat | ⏳ só em inglês |
| 08 | [Nextflow](../en/08_nextflow/README.md) (opcional) | rodar e estender um pipeline de gerenciador de workflows | Nextflow | ⏳ só em inglês |

Faça a 00 primeiro, depois 01–05 em ordem. A 06 e a 07 podem ser feitas a qualquer momento depois da 01. A 08 é opcional.

## Do que você precisa

- Uma conta num cluster PBS (OpenPBS ou PBS Professional) e um terminal com `ssh`.
- `git` (ou outra forma de copiar esta pasta para o cluster), `bash`.
- Apptainer ou Singularity no cluster (comum em clusters acadêmicos; o script de configuração avisa se faltar).
- Cerca de 1 GB de disco num diretório que os nós de computação enxerguem, e acesso à internet a partir do nó de
  login para os downloads iniciais.

Você **não** precisa de permissão de administrador, de ferramentas de bioinformática instaladas nem de
experiência prévia com escalonadores.

## Como cada seção funciona

1. Leia o `README.md` da seção (objetivos, conceitos, tabela "se algo der errado").
2. Rode os **exemplos** (`example_*.pbs`): funcionam do jeito que estão. Leia os comentários.
3. Faça os **exercícios**: `exercise_*.pbs` (preencher lacunas, consertar um job quebrado ou escrever um do zero).
4. Rode o **verificador** da seção (`check_*.sh`). Ele inspeciona as saídas reais dos seus jobs e diz o que está
   errado e onde procurar. Verificadores nunca mudam nada.
5. Compare com `solutions/` só depois de tentar.

**Convenções para lembrar**
- Submeta jobs **a partir do diretório da seção**: `cd 01_pbs_basics; qsub example_count_reads.pbs`.
- As particularidades do seu cluster ficam em `site.conf` (escrito por `00_getting_started/setup.sh`). Nenhum
  script fixa fila, nó ou caminho. Veja `examples/site.pne.conf` para um exemplo preenchido.
- `lib/edu.sh` reúne pequenas funções compartilhadas (curtas, legíveis, vale a pena ler).
- Os logs dos jobs aparecem no diretório de submissão, com o nome `<nomedojob>.o<jobid>`, quando o job termina.
- Os arquivos de resultado que seus jobs criam vão para `$WORKDIR` (do `site.conf`), uma subpasta por seção.
  Dentro de cada diretório de seção, **`results/`** é um atalho para essa pasta (criado automaticamente):
  `ls results/`. O próprio `$WORKDIR` só fica definido depois de `source lib/edu.sh`.
- Os nomes de arquivos e pastas são os mesmos da versão em inglês, para que os comandos sejam idênticos nas duas.

## Extras

- [Cheat sheet](../en/CHEATSHEET.md) (em inglês): os comandos e a anatomia de um script numa página.
- [Glossário](../en/GLOSSARY.md) (em inglês): todos os termos usados, em linguagem simples.

## Notas para instrutores e mantenedores

- A versão em inglês (`../en/`) é a referência; esta pasta traduz comentários, mensagens e textos, sem mudar o
  comportamento dos scripts.
- Os verificadores calculam os valores esperados a partir dos próprios dados (nada fixado num conjunto de dados).
- Dados: o genoma de referência e os 100 pares de reads reais vêm dos test-datasets públicos do nf-core
  (com checksums em `00_getting_started/data.sha256`); as amostras maiores são simuladas com `wgsim` por um job.
- As versões dos containers ficam fixadas em `containers.conf`.
- `../en/tests/lint.sh pt` roda as verificações estáticas nesta pasta (não precisa de cluster).
