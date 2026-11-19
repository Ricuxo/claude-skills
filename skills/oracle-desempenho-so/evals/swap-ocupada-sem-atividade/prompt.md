---
tags: [oracle-desempenho-so]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
free -m no servidor oracle (256 GB de RAM, SGA de 120 GB em hugepages) mostra 6 GB de swap usada. rodei vmstat 5 12 e si e so ficaram 0 em todas as linhas. o pessoal de infra quer reiniciar o servidor hoje à noite porque "banco fazendo swap é emergência". procede?
