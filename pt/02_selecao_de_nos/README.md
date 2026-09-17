# 02 — Checando disponibilidade de nós e fixando seu job num nó

Por padrão, o PBS escolhe qual nó de computação roda seu job, baseado no que está
livre. Isso costuma ser suficiente. Duas situações neste cluster em que vale a pena
checar e fixar explicitamente em vez de confiar no padrão:

1. **Um nó está ocupado pelo job de outra pessoa.** Se você pedir mais recursos do que
   está livre no momento em qualquer lugar, seu job fica na fila (`Q`) em vez de rodar,
   mesmo que *outros* nós estejam completamente ociosos — o PBS não tenta
   automaticamente outro nó no meio do seu pedido, como alguns outros escalonadores
   fazem. Checar antes evita ficar se perguntando por que um job que devia levar 5
   minutos está na fila há uma hora.
2. **Um nó específico tem um problema conhecido.** No momento em que isto foi escrito,
   um dos nós de computação está sem um software (Apptainer) que a maioria dos
   pipelines reais precisa — um job que cair lá falha imediatamente e de forma
   confusa. Fixar longe de um nó conhecidamente problemático evita isso.
   **Particularidade importante deste cluster:** esta configuração de PBS não suporta
   *excluir* um nó (sintaxe `host!=pne5` falha com "Illegal attribute or resource
   value") — você só pode fixar *em* um nó específico. Então a solução é listar
   explicitamente só os nós bons e escolher um você mesmo(a).

## Checando o que está livre

```bash
pbsnodes pne3        # troque pne3 pelo nome de qualquer nó de computação
```

Procure duas coisas na saída: `state = free` (em vez de `busy`/`down`/`offline`), e se
existe uma linha `jobs = ...` presente (se estiver ausente ou vazia, nada está rodando
lá no momento). Um nó pode mostrar `state = free` mesmo com alguns jobs já rodando nele,
se nem todos os seus CPUs estiverem em uso ainda — cheque a linha `jobs`, não só o
`state`.

Para checar vários nós de uma vez:

```bash
for n in pne3 pne4 pne6 pne7 pne10; do
    echo -n "$n: "
    pbsnodes $n | grep -i '^ *jobs' || echo 'livre'
done
```

(Pergunte para quem administra o cluster qual é a lista atual completa de nomes de nós
de computação e quais deles, se algum, têm problemas conhecidos no momento — os nomes
específicos dos nós e os problemas vão mudar com o tempo, este guia não vai se
atualizar sozinho.)

## Fixando seu job num nó específico

Adicione `host=<nome_do_no>` dentro do pedido de recursos `select`:

```bash
#PBS -l select=1:ncpus=4:mem=8gb:host=pne3
```

## Um padrão que vale conhecer: round-robin entre vários nós bons

Se você está submetendo muitos jobs pequenos e independentes (comum com ferramentas
como o Nextflow, que espalham um pipeline em muitas tarefas paralelas), fixar todos no
*mesmo* nó desperdiça os outros que estão livres. Um round-robin simples — percorrendo
uma lista de nós conhecidamente bons pelo índice da tarefa — distribui a carga sem
precisar depender do posicionamento automático do próprio PBS (que, nesta configuração,
ocasionalmente não é confiável). Veja `05_nextflow_avancado/` para um exemplo real
desse padrão numa diretiva `clusterOptions` do Nextflow.

## Experimente

`check_free_nodes.sh` é uma versão pronta para rodar do loop acima — experimente agora
para ver o estado atual do cluster. Depois faça `exercise_02_pin_to_free_node.pbs`:
cheque você mesmo(a) quais nós estão livres, preencha o nome do nó, e submeta.
