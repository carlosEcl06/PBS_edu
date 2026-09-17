# 04 — Armadilhas reais encontradas neste cluster (e como foram diagnosticadas)

Tutoriais genéricos de PBS costumam parar em "assim que você submete um job." Estes
são problemas reais, encontrados construindo um pipeline de verdade neste exato
servidor, com o raciocínio que levou a cada solução — porque o raciocínio é a parte
reaproveitável, não a solução específica.

## 1. Um nó de computação sem um software necessário, silenciosamente

**Sintoma:** um pipeline que espalhava ~550 jobs quase idênticos por vários nós de
computação rodou bem nas primeiras centenas, depois começou a falhar com
`apptainer: No such file or directory` (código de saída 127) num subconjunto de
tarefas, sem um padrão óbvio só pela mensagem de erro.

**Instinto errado:** apenas tentar de novo as tarefas que falharam e torcer para ter
sido uma falha passageira.

**O que realmente funcionou:** submeter alguns jobs de diagnóstico bem pequenos, cada
um fixado exatamente num nó candidato (`host=pneN`), cada um só checando
`ls /usr/bin/apptainer`. Isso isolou o problema a um único nó que, por algum motivo,
estava sem o binário do Apptainer completamente — todos os outros nós o tinham.

**A solução:** como esta configuração de PBS não suporta *excluir* um nó
(`host!=pneN` falha direto), a solução foi listar explicitamente os nós bons
conhecidos e alternar entre eles em round-robin:

```groovy
// exemplo: dentro do clusterOptions de um process do Nextflow
def good_nodes = ['pne3', 'pne4', 'pne6', 'pne7', 'pne10']
clusterOptions { "-l select=1:ncpus=2:mem=4gb:host=${good_nodes[task.index % good_nodes.size()]}" }
```

**A lição:** quando um lote de jobs falha de forma inconsistente (alguns nós, outros
não), não chute e tente de novo — escreva a menor reprodução possível (um job, um nó,
uma checagem) para cada suspeito e deixe a evidência dizer qual é.

## 2. Um container não consegue enxergar um arquivo que está bem ali

**Sintoma:** um job chamando
`apptainer exec algumaferramenta.sif ... /data2/caminho/para/entrada.gff` falhou com
`FileNotFoundError`, mesmo com `cat /data2/caminho/para/entrada.gff` funcionando bem
num shell interativo, e o arquivo confirmado como existente com `ls`.

**Instinto errado:** assumir que a etapa de cópia/transferência de arquivo anterior no
pipeline ficou incompleta ou corrompida de alguma forma, e rodá-la de novo.

**O que realmente funcionou:** ler o código-fonte da própria ferramenta que estava
falhando (é de código aberto — o traceback apontava para uma linha exata) confirmou que
ela realmente estava fazendo um `open(caminho)` simples exatamente no caminho passado.
Isso descartou um bug na própria ferramenta e apontou para a fronteira do container: o
comportamento padrão de bind-mount do Apptainer não garante que caminhos absolutos
arbitrários no armazenamento compartilhado fiquem visíveis dentro do container, só o
seu diretório home e o diretório de trabalho atual.

**A solução:** dar `cd` para o diretório de trabalho do próprio job primeiro e usar
`cp` para copiar as entradas necessárias para lá, depois referenciá-las por caminho
relativo em vez do caminho absoluto original. (Explicação completa e exemplo em
`03_containers_apptainer/README.md`.)

**A lição:** "o arquivo não existe" de dentro de um job em container nem sempre
significa que o arquivo não existe — verifique se é um problema de bind-mount antes de
assumir um problema de dado, especialmente se o mesmo caminho funciona bem fora do
container.

## 3. Uma ferramenta que falha em dados biológicos reais nem sempre é bug

**Sintoma:** uma ferramenta de análise de pangenoma falhou no meio de um conjunto de
dados real com `ValueError: Invalid gene sequence!` em alguns dos genomas de entrada.

**Instinto errado:** assumir que os arquivos de entrada estavam malformados e começar
a rederivá-los.

**O que realmente funcionou:** ler a lógica de validação da própria ferramenta mostrou
que ela estava rejeitando genes com códons de parada no meio da sequência, comprimentos
que não eram múltiplos de 3, ou mudanças de fase de leitura — exatamente o tipo de
anotação que se espera de pseudogenes reais num genoma, não necessariamente um sinal de
entrada corrompida. A própria saída de `--help` da ferramenta listava uma flag
(`--remove-invalid-genes`) especificamente para essa situação.

**A solução:** passar a flag que a própria ferramenta oferece para isso — ela existe
porque dados biológicos reais legitimamente contêm isso, não como uma gambiarra para
um bug de dado.

**A lição:** antes de assumir que sua entrada está quebrada, verifique se a ferramenta
tem uma opção documentada exatamente para a falha que você está vendo — uma flag
feita especificamente para aquilo é um sinal muito mais forte de que a falha é esperada
do que um `try/except` genérico.

## 4. Nunca, nem por um instante, rode computação no nó de login

**Sintoma:** nenhum, na verdade — esta é uma nota de disciplina, não uma história de
depuração. Mas vale dizer claramente: é muito fácil, no meio de uma sessão de
depuração, rodar "só um comando rápido" direto via SSH no nó de login em vez de
empacotá-lo num job PBS, especialmente para algo que parece trivialmente barato
(checar a saída de `--help` de uma ferramenta, por exemplo). Isso aconteceu uma vez
enquanto o pipeline por trás deste guia estava sendo construído — percebido em menos
de um minuto, o processo perdido foi morto, sem dano duradouro, mas não devia ter
acontecido de jeito nenhum.

**O hábito a construir:** se um comando precisa executar *qualquer coisa* além de
script de shell trivial (qualquer programa de verdade, qualquer container, qualquer
computação real), ele passa pelo `qsub`, ponto final — mesmo para algo que parece que
vai levar dois segundos. O nó de login é espaço de orquestração compartilhado por
todo mundo; trate-o assim de forma consistente, não só quando for conveniente.
