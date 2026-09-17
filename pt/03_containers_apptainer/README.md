# 03 — Rodando software com containers Apptainer

Instalar ferramentas de bioinformática diretamente (via `conda`, `pip`, compilando do
código-fonte...) muitas vezes vira uma briga com resolução de dependências, e é fácil
acabar com uma versão sutilmente diferente da ferramenta em relação a um(a) colega, o
que dificulta comparar ou reproduzir resultados. O padrão recomendado aqui em vez
disso: rodar a ferramenta a partir de um container pré-construído.

## Por que containers, e por que fixar uma versão exata

O [Biocontainers](https://biocontainers.pro/) publica um container para praticamente
toda ferramenta comum de bioinformática, construído e versionado automaticamente a
partir do Bioconda. Dois hábitos importam:

1. **Fixe a tag de versão exata, não use `:latest`.** `:latest` muda silenciosamente
   com o tempo e quebra a reprodutibilidade -- se seus resultados dependem da versão X
   de uma ferramenta e alguém roda seu pipeline de novo seis meses depois com o que
   `:latest` tiver se tornado até lá, pode obter números diferentes sem motivo óbvio.
2. **Pegue a tag exata de uma fonte confiável já conferida, não adivinhe.** Uma boa
   forma: veja como um framework de pipeline já estabelecido
   ([nf-core/modules](https://github.com/nf-core/modules)) fixa a mesma ferramenta —
   as definições de módulo deles listam a string exata
   `quay.io/biocontainers/<ferramenta>:<versão>`, que é uma fixação real e testada, não
   um chute.

## Baixando e rodando um job com container

```bash
apptainer pull --force minhaferramenta.sif docker://quay.io/biocontainers/minhaferramenta:1.2.3--hdfd78af_2
apptainer exec minhaferramenta.sif minhaferramenta --version
```

`apptainer pull` baixa e converte a imagem uma vez; depois disso,
`apptainer exec minhaferramenta.sif <comando>` roda qualquer coisa dentro dela como se
estivesse instalada localmente. Faça o pull uma vez (idealmente para um armazenamento
compartilhado, não algo que será baixado de novo a cada job) e reutilize o arquivo
`.sif` entre os jobs.

## A armadilha que vai te pegar: bind mounts

Um container só enxerga as partes do sistema de arquivos que estão explicitamente (ou
por padrão) "montadas" (bind-mounted) dentro dele. O Apptainer monta automaticamente
seu diretório home e o diretório de trabalho atual por padrão, mas **não monta de
forma confiável caminhos absolutos arbitrários** em outro lugar do armazenamento
compartilhado só porque você consegue vê-los no seu shell de login.

Concretamente: se o script do seu job fizer isto --

```bash
apptainer exec minhaferramenta.sif minhaferramenta -i /data2/projects/OUTRO-PROJETO/entrada.txt
```

-- e esse caminho não estiver coberto por uma montagem automática,
`minhaferramenta` vai falhar com algo como "No such file or directory" para um arquivo
que com certeza existe e que *você* consegue abrir com `cat` sem problema no mesmo
shell. Isso é genuinamente confuso da primeira vez que acontece, porque o erro parece
um problema de arquivo faltando quando o arquivo está bem ali.

**A solução confiável: dê `cd` para o diretório de trabalho do seu próprio job (dentro
da área montada automaticamente) e copie suas entradas para lá primeiro**, depois
referencie-as com caminhos relativos:

```bash
cd /data2/projects/SEU-PROJETO/results/meu_job   # algum lugar onde você tem um cwd de verdade
cp /data2/projects/OUTRO-PROJETO/entrada.txt .
apptainer exec minhaferramenta.sif minhaferramenta -i entrada.txt   # caminho relativo, sempre funciona
```

Isso custa um pouco de I/O de disco para a cópia, mas é a diferença entre um job que
funciona sempre e um que falha misteriosamente dependendo exatamente de quais caminhos
ele toca.

## Experimente

`example_container_job.pbs` baixa um container público pequeno e rápido e roda um
comando trivial dentro dele — submeta como está primeiro. Depois
`exercise_03_run_a_tool.pbs` pede para você baixar o container de uma ferramenta real
de bioinformática e checar sua versão, preenchendo a tag do container você mesmo(a)
(procure no nf-core/modules ou no biocontainers.pro, não chute).
