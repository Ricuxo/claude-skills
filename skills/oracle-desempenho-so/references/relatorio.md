# Modelo de relatório

```markdown
# Análise de desempenho — Nível SO/Infraestrutura — <BANCO>
Coletado em <data> · <host> · Oracle <versão> · <N> threads / <N> cores · <RAM> GB
Instância no ar há <N> dias · Janela: <acumulado | delta de N min | AWR HH:MM–HH:MM>
Fonte das taxas: <delta manual | V$SYSMETRIC | AWR>

## Veredito
Uma frase: existe ou não limitação física, e qual.

## CPU
## Memória
## I/O
## Rede, interconnect e limites de instância

## Pontos de atenção
Ordenados por criticidade, com o número ao lado de cada afirmação.

## Recomendações
Cada uma marcada: exige restart? exige janela? risco?

## O que este nível NÃO respondeu
O que ficou fora (incluindo o que faltou por falta de shell ou de pack) e qual nível investiga.
```

A última seção não é modéstia: um relatório que conclui "o hardware está bem" sem apontar o
próximo passo deixa o usuário onde estava.

Para RAC ou vários bancos, inclua tabela comparativa: nó, threads, load, %CPU, RAM, swap,
latência de bloco único, `gc 2-way`, top wait. Desequilíbrio entre nós só aparece assim.

Se o usuário pedir planilha, consulte a skill de xlsx disponível antes de gerar.
