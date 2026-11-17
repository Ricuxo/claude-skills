---
name: oracle-desempenho-so
description: Analisa desempenho de banco Oracle na camada de SO e infraestrutura — CPU (saturação, run queue, %sys, cpu_count versus cores), memória (RAM, swap, paging, HugePages, Transparent HugePages, SGA/PGA versus memória física), I/O (latência, IOPS, throughput, datafiles, diskgroups ASM) e rede, incluindo interconnect de RAC. Use sempre que o usuário disser que o servidor está lento, a CPU está alta, o disco ou storage está lento, falta memória ou o servidor está usando swap; ou perguntar sobre HugePages, latência de disco, saturação de CPU, blocos perdidos no interconnect ou dimensionamento de servidor Oracle — mesmo sem citar SO ou infraestrutura. Use também ao interpretar vmstat, iostat, sar, mpstat, top, nmon, OSWatcher ou os eventos db file sequential read, log file parallel write e log file sync. Nível 1 de seis skills de desempenho Oracle; somente leitura.
---

# Desempenho Oracle — Nível 1: sistema operacional e infraestrutura

A camada de baixo: CPU, memória, I/O e rede. É onde os sintomas aparecem e raramente onde a
causa está — um SQL ruim satura a CPU, e a CPU saturada parece problema de hardware. Esta
skill serve principalmente para **descartar ou confirmar limitação física** antes de alguém
comprar servidor.

Faz parte de um conjunto de seis níveis. A ordem que dá resultado é de cima para baixo,
guiada por tempo: `oracle-desempenho-instancia` (onde o tempo está indo) →
`oracle-desempenho-sessao` → `oracle-desempenho-sql` → `oracle-desempenho-objetos`. Este nível
e o `oracle-desempenho-aplicacao` são os apoios das pontas. Se o usuário chegou só com "o
servidor está lento", colete este nível **e** o de instância: sozinho, este aqui mostra que a
casa está quente, não quem ligou o fogão.

**Somente leitura.** Nada aqui cria, altera ou remove. Não execute nem oriente executar
`ALTER SYSTEM`, mudança em `/etc/sysctl.conf`, instalação de Statspack ou qualquer outra
mudança sem que o usuário confirme explicitamente que quer sair do diagnóstico. Vários desses
parâmetros só valem após restart, e alguns impedem a instância de subir se mal dimensionados.
Mudanças aparecem no relatório como **recomendação**, nunca como passo de coleta.

Privilégio: `CREATE SESSION` + `SELECT_CATALOG_ROLE`. Não exige SYSDBA. A parte de SO exige
shell no servidor, normalmente como `oracle` — sem isso, entregue os comandos para quem tem.

Todo o SQL está em forma executável direta, sem `SPOOL`, `SET` ou variável de substituição:
funciona pelo MCP do SQLcl, no SQLcl/SQL\*Plus ou em qualquer cliente.

---

## Modo de condução

**Padrão em sessão interativa: uma verificação por vez.** Rode ou entregue uma consulta, leia
o resultado com o usuário, diga o que ele mostra e só então peça a próxima — escolhida pelo
que o número anterior indicou. Não despeje o roteiro inteiro e não abra hipóteses que os dados
ainda não sustentam. Ordem de partida: uptime → CPU → memória → I/O → rede. Desvie quando um
achado pedir (swap em uso pula direto para memória; latência alta de bloco único pula para I/O).

**Modo lote** só quando o usuário pedir explicitamente ("roda tudo", "gera o relatório"):
coleta completa e relatório no formato do final.

---

## Passo 1 — Perguntas de abertura

Faça as três de uma vez, com opções clicáveis quando a interface permitir. Se a conversa já
respondeu alguma, confirme em uma linha e siga.

**1. Diagnostic Pack** — "O ambiente tem licença de Diagnostic Pack?" `Sim` · `Não` · `Não sei`

Quase tudo neste nível funciona sem pack. O que exige pack é o histórico (`DBA_HIST_*`) e o
ASH. Em "Não" ou "Não sei", não use `references/historico-pack.md`. Para ver se o pack está
**habilitado** (não é o mesmo que licenciado — licença é contratual):

```sql
SELECT value FROM v$parameter WHERE name = 'control_management_pack_access'
```

`DIAGNOSTIC` ou `DIAGNOSTIC+TUNING` = habilitado. `NONE` = desabilitado. Não use
`dba_feature_usage_statistics` para isso: ela mostra uso detectado, e uso sem licença é
justamente o achado de auditoria.

**2. Acesso ao SO** — "Você tem shell no servidor do banco?"
`Sim, eu rodo` · `Não, mas peço ao time de infra` · `Não`

Sem shell, `V$OSSTAT` ainda dá CPU e memória do host, mas nada de run queue histórica, swap em
tempo real, THP, HugePages efetivas ou latência por dispositivo. Diga isso na conclusão.

**3. Horário** — "A lentidão é constante ou tem hora para acontecer?"
`Constante` · `Tem horário` · `Não sei`

Se tem horário, os contadores acumulados diluem o pico — meça delta em janela (Passo 3).

---

## Passo 2 — Conexão e contexto

Com MCP do SQLcl: inspecione as ferramentas disponíveis (os nomes variam por versão), liste as
conexões salvas, peça ao usuário **o nome da conexão** — nunca IP, usuário ou senha — e
confirme onde está:

```sql
SELECT sys_context('USERENV','DB_NAME') AS banco, sys_context('USERENV','CON_NAME') AS container,
       sys_context('USERENV','SERVER_HOST') AS host, user AS usuario FROM dual
```

Logo em seguida, sempre, o uptime — ele define quanto os contadores valem:

```sql
SELECT inst_id, instance_name, host_name, version, startup_time,
       ROUND(SYSDATE - startup_time, 1) AS dias_no_ar
  FROM gv$instance ORDER BY inst_id
```

Instância no ar há poucas horas: os números não representam o comportamento normal. Diga isso.

Uma consulta por chamada, só `SELECT`. Falhou por permissão: relate e siga. Sem MCP, entregue
as consultas para o DBA rodar (`SET SQLFORMAT CSV` no SQLcl, `SET MARKUP CSV ON` no
SQL\*Plus 12.2+).

**RAC:** este nível é por nó. `V$` mostra só a instância corrente; use `GV$` agrupando por
`INST_ID` ou repita por nó. Um nó saturado e outro ocioso é achado comum e invisível se você
olhar só um.

**CDB:** `V$OSSTAT` e `V$FILESTAT` são do servidor inteiro. Colete no root e deixe claro que o
número é do conjunto; atribuição por PDB fica nos níveis de instância e SQL.

---

## Passo 3 — Acumulado versus delta

Quase toda view `V$` deste nível é contador acumulado. Num banco no ar há 200 dias, "CPU 12%
ocupada" é a média de 200 dias — o pico das 14h de ontem não aparece.

**Delta manual (sem licença nenhuma).** Colete duas vezes, sempre com `SYSTIMESTAMP`, e divida
pelo intervalo **real** entre as coletas — via MCP não é possível esperar um tempo exato entre
chamadas, então nunca assuma 60 s:

```sql
SELECT SYSTIMESTAMP AS coletado_em, stat_name, value FROM v$osstat
 WHERE stat_name IN ('BUSY_TIME','IDLE_TIME','USER_TIME','SYS_TIME','IOWAIT_TIME','NICE_TIME')
```

Valores em centésimos de segundo, somados em todas as CPUs.
`%CPU ocupada = Δbusy / (Δbusy + Δidle) × 100`. Mesmo método para `V$SYSTEM_EVENT`,
`V$SYSSTAT` e `V$SYS_TIME_MODEL` sempre que precisar de taxa.

**Janela curta pronta.** `V$SYSMETRIC` (`group_id = 2`) entrega taxas do último minuto, e
`V$SYSMETRIC_HISTORY` guarda cerca de uma hora, minuto a minuto. As consultas estão em
`references/consultas.md` (seção Passo 3): **leia-o** quando precisar de taxa sem fazer delta manual.

Ressalva para dizer ao usuário: as views `V$SYSMETRIC*` são populadas pelo MMON, a mesma
infraestrutura do AWR, e há auditores que as tratam como área cinzenta. Contadores puros
(`V$OSSTAT`, `V$SYSSTAT`, `V$SYSTEM_EVENT`) não têm essa ambiguidade. Em ambiente sensível a
auditoria, prefira o delta manual e registre a escolha no relatório.

---

## Passo 4 — CPU

### 4.1 O que a máquina tem

```sql
SELECT stat_name, value FROM v$osstat
 WHERE stat_name IN ('NUM_CPUS','NUM_CPU_CORES','NUM_CPU_SOCKETS','PHYSICAL_MEMORY_BYTES')
```

```sql
SELECT name, value, isdefault FROM v$parameter
 WHERE name IN ('cpu_count','parallel_max_servers','parallel_degree_policy','parallel_threads_per_cpu',
                'resource_manager_plan','processes','sessions','job_queue_processes')
 ORDER BY name
```

`NUM_CPUS` conta **threads**. Com hyperthreading, uma thread não equivale a um core. Dois
achados frequentes: VM onde `cpu_count` reflete o host e não o que a VM recebe, e licença por
core enquanto o banco se acha dono de todas as threads. `cpu_count` diferente de `NUM_CPUS`
significa que alguém setou manualmente — pergunte por quê antes de sugerir mudar.

### 4.2 Carga instantânea

```sql
SELECT (SELECT value FROM v$osstat WHERE stat_name='LOAD') AS load_atual,
       (SELECT value FROM v$osstat WHERE stat_name='NUM_CPUS') AS threads,
       (SELECT value FROM v$osstat WHERE stat_name='NUM_CPU_CORES') AS cores
  FROM dual
```

`LOAD / threads` acima de 1 = mais trabalho pronto do que CPU. Compare também com `cores`:
com HT, load de 1,0 por thread já é saturação real dos cores. No Linux o load inclui processos
em espera de I/O (estado D), então load alto com CPU ociosa aponta para I/O, não CPU.

### 4.3 Quanto da CPU é do banco — só por delta

`DB CPU` conta desde o startup da instância; `BUSY_TIME` no Linux vem do `/proc/stat`, desde o
boot do host. Compará-los acumulados infla o "consumo fora do banco". Colete duas vezes:

```sql
SELECT SYSTIMESTAMP AS coletado_em,
       (SELECT SUM(value) FROM v$sys_time_model WHERE stat_name='DB CPU') AS db_cpu_us,
       (SELECT SUM(value) FROM v$sys_time_model WHERE stat_name='background cpu time') AS bg_cpu_us,
       (SELECT value FROM v$osstat WHERE stat_name='BUSY_TIME') AS host_busy_cs
  FROM dual
```

`fração do banco = (Δdb_cpu_us + Δbg_cpu_us) / 1.000.000 ÷ (Δhost_busy_cs / 100)`.
Bem abaixo de 1: o consumo está fora do Oracle — outro banco, aplicação co-residente,
antivírus, EDR, agente de backup ou monitoração. Muda completamente a recomendação.

### 4.4 Espera por CPU dentro do banco

Também por delta:

```sql
SELECT SYSTIMESTAMP AS coletado_em,
       (SELECT SUM(value) FROM v$sys_time_model WHERE stat_name='DB time') AS db_time_us,
       (SELECT SUM(value) FROM v$sys_time_model WHERE stat_name='DB CPU') AS db_cpu_us,
       (SELECT SUM(time_waited_micro_fg) FROM v$system_event WHERE wait_class <> 'Idle') AS fg_wait_us
  FROM dual
```

- `ΔDB CPU / ΔDB time` alto (acima de ~65%) com host saturado: trabalho excessivo, tipicamente
  SQL lendo blocos demais. Não é hardware — encaminhe para `oracle-desempenho-sql`.
- `ΔDB time − ΔDB CPU − Δfg_wait` grande: tempo não contabilizado, que é a sessão na fila do
  SO esperando CPU. É o indicador interno de run queue e complementa a coluna `r` do `vmstat`.

Resource Manager segurando sessões de propósito:

```sql
SELECT event, total_waits, ROUND(time_waited_micro/1000000,2) AS seg_total
  FROM v$system_event WHERE event LIKE 'resmgr%' ORDER BY time_waited_micro DESC
```

`resmgr:cpu quantum` relevante com `resource_manager_plan` vazio na consulta 4.1 costuma ser o
`DEFAULT_MAINTENANCE_PLAN` ativado pela janela de manutenção — muitos ambientes nem sabem.

---

## Passo 5 — Memória

### 5.1 Física versus reservada

```sql
SELECT ROUND((SELECT value FROM v$osstat WHERE stat_name='PHYSICAL_MEMORY_BYTES')/1073741824,2) AS ram_gb,
       ROUND((SELECT value FROM v$osstat WHERE stat_name='FREE_MEMORY_BYTES')/1073741824,2) AS livre_gb,
       ROUND((SELECT SUM(value) FROM v$sga)/1073741824,2) AS sga_gb,
       ROUND((SELECT value FROM v$pgastat WHERE name='total PGA allocated')/1073741824,2) AS pga_atual_gb,
       ROUND((SELECT value FROM v$pgastat WHERE name='maximum PGA allocated')/1073741824,2) AS pga_pico_gb
  FROM dual
```

No Linux, `FREE_MEMORY_BYTES` é o `MemFree`, que exclui cache e parece sempre baixo. A memória
realmente disponível é `MemAvailable` (`free -m`, coluna `available`).

```sql
SELECT name, ROUND(TO_NUMBER(value)/1073741824,2) AS gb, isdefault
  FROM v$parameter
 WHERE name IN ('sga_target','sga_max_size','memory_target','memory_max_target','pga_aggregate_target',
                'pga_aggregate_limit','db_cache_size','shared_pool_size','log_buffer')
 ORDER BY name
```

A conta: **SGA + pico de PGA + processos do SO + folga do sistema deve caber na RAM.**
`pga_aggregate_target` é meta, não limite; o pico real é o que conta. Servidor dimensionado
pela meta é causa comum de swap.

### 5.2 Swap e paginação

```sql
SELECT SYSTIMESTAMP AS coletado_em, stat_name, value FROM v$osstat
 WHERE stat_name IN ('VM_IN_BYTES','VM_OUT_BYTES')
```

Crescimento entre duas coletas é o que importa. **Servidor de banco fazendo swap é emergência**:
páginas da SGA indo para disco transformam acesso de memória em acesso de disco sem que nenhuma
métrica do banco perceba. Confirme no SO se o OOM killer já agiu (`references/coleta-so.md`).

### 5.3 PGA e TEMP

```sql
SELECT name, CASE WHEN unit='bytes' THEN ROUND(value/1048576,2) ELSE value END AS valor,
       CASE WHEN unit='bytes' THEN 'MB' ELSE unit END AS unidade
  FROM v$pgastat
 WHERE name IN ('aggregate PGA target parameter','total PGA allocated','maximum PGA allocated',
                'total PGA inuse','over allocation count','extra bytes read/written',
                'cache hit percentage','total freeable PGA memory')
```

`over allocation count` > 0: o Oracle alocou além do alvo, PGA subdimensionada.
`cache hit percentage` abaixo de ~90%: sorts e hash joins indo para o TEMP. Para ver quem
consome o TEMP agora, use a consulta por sessão de `references/consultas.md` (seção Passo 5.3).

### 5.4 HugePages e Transparent HugePages (Linux)

```sql
SELECT name, value FROM v$parameter WHERE name IN ('use_large_pages','memory_target','memory_max_target')
```

Evidência definitiva de quanto da SGA está em HugePages é o bloco *Large Pages Information*
que o alert log grava no startup (12c+; a view lê XML e pode demorar):

```sql
SELECT originating_timestamp, message_text FROM v$diag_alert_ext
 WHERE message_text LIKE '%Large Pages%' OR message_text LIKE '%large pages%'
 ORDER BY originating_timestamp DESC FETCH FIRST 30 ROWS ONLY
```

No SO, `grep -i huge /proc/meminfo` e a verificação de THP em `references/coleta-so.md`.

Quatro coisas que valem mais do que parecem:
- SGA acima de ~8 GB sem HugePages: page tables crescem a gigabytes (`PageTables` no
  `/proc/meminfo`) e cada processo servidor paga o custo, com `%sys` alto.
- **AMM (`memory_target`) e HugePages são mutuamente exclusivos.** Com `memory_target` setado,
  HugePages não é usada — muito ambiente tem HugePages configurada no SO e inativa por isso.
- `use_large_pages = ONLY` faz a instância se recusar a subir sem HugePages, o que ao menos
  torna o problema visível.
- **Transparent HugePages deve estar desabilitado** (recomendação Oracle). THP ativo causa
  travamentos intermitentes por compactação de memória no kernel, que parecem problema de storage.

---

## Passo 6 — I/O

**Leia `references/consultas.md`** (seções do Passo 6) ao entrar neste passo: o SQL de cada
verificação abaixo está lá, e a interpretação fica aqui.

### 6.1 Latência percebida pelo banco

O número mais importante deste nível: a média por evento de `V$SYSTEM_EVENT`.

`db file sequential read` (bloco único, quase sempre por índice) é a melhor aproximação da
latência do storage. Referências: abaixo de 1 ms = flash ou cache do storage; 2 a 6 ms = disco
saudável com cache; acima de 10 ms = lento; acima de 20 ms = contenção real.

**`log file sync` versus `log file parallel write`:** se o sync for muito maior que o parallel
write, o storage do redo não é o problema — é commit excessivo da aplicação, CPU saturada
atrasando o LGWR ou o LGWR perdendo prioridade no SO. `log file parallel write` saudável fica
abaixo de ~2 ms em flash e ~5 ms em disco.

A média esconde a cauda: olhe a distribuição em `V$EVENT_HISTOGRAM`. Em flash/NVMe quase tudo
cai no balde de 1 ms; use `V$EVENT_HISTOGRAM_MICRO` (12.1.0.2+).

95% em 1 ms e 2% acima de 64 ms = problema intermitente de storage que nenhuma média revela —
e são esses 2% que o usuário sente.

### 6.2 Distribuição por arquivo

`V$FILESTAT` (datafiles) e `V$TEMPSTAT` (tempfiles). Um datafile com 60% das leituras sozinho num
mount point = gargalo físico e ponto único de falha.

### 6.3 Quem gera o I/O (11g+)

`V$IOSTAT_FUNCTION` separa buffer cache, direct read, RMAN, archiving, DBWR e LGWR. Descobrir que metade do I/O é
do RMAN em horário comercial resolve mais "storage lento" do que qualquer tuning.

### 6.4 ASM

Se o banco usa ASM, **leia `references/rac-asm.md`** (seção ASM): latência e erros por disco e
diskgroup. Um disco com latência muito acima dos irmãos = LUN ou caminho de multipath degradado.

### 6.5 Parâmetros de I/O

`filesystemio_options`, `disk_asynch_io`, `db_file_multiblock_read_count`, `db_writer_processes`,
`dbwr_io_slaves`, `log_archive_max_processes` e `db_block_size`, de `V$PARAMETER`.

Em filesystem (não ASM), `filesystemio_options = SETALL` habilita I/O assíncrono e direto; sem
isso o banco passa pelo page cache do SO, que duplica o cache e desperdiça RAM. Alto retorno,
baixo risco — mas exige restart: é recomendação, não diagnóstico. `db_file_multiblock_read_count`
setado manualmente (`isdefault = FALSE`) merece pergunta; o default autoajustável costuma ser melhor.

---

## Passo 7 — Rede, interconnect e limites

```sql
SELECT event, total_waits, ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,3) AS ms_medio,
       ROUND(time_waited_micro/1000000,2) AS seg_total
  FROM v$system_event
 WHERE event LIKE 'SQL*Net%' OR event LIKE '%TCP%'
 ORDER BY time_waited_micro DESC
```

`SQL*Net message from client` é ocioso — ignore. Importam `SQL*Net more data to client` e
`SQL*Net break/reset to client`. Latência de rede da aplicação aparece melhor por round-trips,
em `oracle-desempenho-aplicacao`.

**Interconnect (RAC).** Em RAC, **leia `references/rac-asm.md`** (seção Interconnect):
latência `gc 2-way`/`3-way`, blocos perdidos e interfaces configuradas. É infraestrutura de rede
pura e o achado mais comum de "lentidão só no RAC".

**Limites de instância:**

```sql
SELECT resource_name, current_utilization, max_utilization, initial_allocation, limit_value,
       ROUND(max_utilization/NULLIF(TO_NUMBER(REPLACE(limit_value,'UNLIMITED','0')),0)*100,1) AS pct_pico
  FROM v$resource_limit
 WHERE resource_name IN ('processes','sessions','transactions','enqueue_locks','enqueue_resources',
                         'dml_locks','temporary_table_locks','max_shared_servers','parallel_max_servers')
 ORDER BY resource_name
```

`max_utilization` é a marca d'água desde o startup. `processes` a 98% do limite = já esteve a
um passo de `ORA-00020`. Cada processo consome memória — conversa direto com o Passo 5.

---

## Passo 8 — Sistema operacional

**Leia `references/coleta-so.md`** sempre que o usuário tiver shell (Pergunta 2) ou colar
saída de `vmstat`, `iostat`, `sar`, `mpstat`, `top`, `nmon` ou OSWatcher. O arquivo traz os
comandos, como ler cada coluna, THP, OOM killer, limites efetivos do processo, rede do
interconnect e o mapeamento disco ASM → device.

Para ligar um processo caro do `top` a uma sessão do banco (troque `12345` pelo PID):

```sql
SELECT p.spid AS pid_so, s.sid, s.serial#, s.username, s.status, s.program, s.module,
       s.sql_id, s.event, s.machine, ROUND(p.pga_used_mem/1048576,2) AS pga_mb
  FROM v$process p JOIN v$session s ON s.paddr = p.addr
 WHERE p.spid = '12345'
```

Com `threaded_execution = TRUE` (12c+), o PID do `top` é uma thread: filtre por `p.stid` em vez
de `p.spid`. Esse pulo do `top` para a sessão conecta este nível a `oracle-desempenho-sessao`.

## Histórico com Diagnostic Pack

**Leia `references/historico-pack.md` somente** se a Pergunta 1 foi "Sim". Sem pack, não use
`DBA_HIST_*`; sugira Statspack como recomendação futura (é instalação, não coleta).

---

## Como analisar

Quase tudo neste nível é sintoma. Procure especificamente:

- **CPU saturada com fração do banco baixa** (4.3) — o consumo é de fora. Investigue o que mais
  roda no servidor antes de qualquer tuning.
- **CPU saturada com DB CPU alto** — trabalho demais, SQL lendo blocos em excesso. Vá para
  `oracle-desempenho-sql`.
- **Tempo não contabilizado alto** (4.4) — sessões na fila de CPU do SO.
- **Load acima das threads com CPU não saturada** — processos esperando I/O, não CPU.
- **`%sys` alto** — I/O sem async, page tables grandes sem HugePages, THP compactando ou
  excesso de processos.
- **`%steal` acima de ~5% em VM** — o hypervisor está tomando CPU; `V$OSSTAT` não enxerga isso.
- **Swap em uso ou OOM killer no `dmesg`** — crítico. Diga isso com clareza; nenhum tuning compensa.
- **`over allocation count` > 0 com TEMP alta** — PGA subdimensionada, custo aparecendo como I/O.
- **`memory_target` setado com HugePages no SO** — HugePages inativa.
- **THP habilitado** — fonte provável de travamentos intermitentes.
- **`db file sequential read` acima de 10 ms** — storage lento *ou* cache pequeno gerando leituras
  que não deveriam existir. O histograma e o volume separam as duas causas.
- **Cauda ruim no histograma com média boa** — problema intermitente de storage; o achado que
  mais explica "trava de vez em quando".
- **`log file sync` muito acima de `log file parallel write`** — problema de commit ou CPU, não
  de storage.
- **`%util` alto no `iostat` em SSD, NVMe ou LUN de SAN** — **não** indica saturação nesses
  dispositivos, que atendem requisições em paralelo. Olhe `r_await`/`w_await` e `aqu-sz`.
- **Disco ASM com latência fora do padrão dos irmãos** — LUN ou caminho degradado.
- **I/O concentrado em poucos datafiles ou num mount** — gargalo físico e ponto único de falha.
- **RMAN, archiving ou backup em `V$IOSTAT_FUNCTION` no horário de pico** — janela de
  manutenção invadindo produção. Barato de resolver.
- **`gc blocks lost` crescendo** — rede privada do RAC com perda; não é tuning de banco.
- **`processes` perto do limite** — risco de indisponibilidade e sinal de ausência de pool.
- **`filesystemio_options = none` em filesystem** — cache duplicado.
- **RAC com um nó carregado e outro ocioso** — balanceamento de serviço, não capacidade.

Separe **fato** de **recomendação**. Fatos saem dos números; recomendações dependem de janela de
manutenção, criticidade, contrato de storage e orçamento. Resista a "precisa de mais hardware":
só se sustenta depois que instância, SQL e aplicação foram olhados. Comprar CPU para compensar
um índice ausente é o erro mais caro deste ofício.

---

## Relatório

Ao fechar a análise ou no modo lote, **leia `references/relatorio.md`** e siga o modelo. A
seção "O que este nível NÃO respondeu" é obrigatória: um relatório que conclui "o hardware está
bem" sem apontar o próximo nível deixa o usuário onde estava.

---

## Cuidados operacionais

- Views `V$` zeram no restart — sempre informe o uptime.
- Data Guard: standby em `MOUNTED` responde a `V$OSSTAT` e `V$SYSTEM_EVENT`, mas o perfil de
  I/O é de recuperação. Não compare com o primary.
- Exadata: eventos mudam de nome (`cell single block physical read`, `cell smart table scan`) e
  as referências de latência são outras. Se aparecer `cell%`, diga que é Exadata e ajuste a leitura.
- VM: `V$OSSTAT` vê só o SO convidado. Verifique `%steal` antes de concluir que há CPU sobrando.
- Nuvem gerenciada (RDS, Autonomous): sem shell; diga que a cobertura de SO depende das métricas
  do provedor.
- Nunca escreva senhas, strings de conexão ou dados de negócio no relatório.

## Diferenças por versão

| Recurso | 11g | 12c+ |
|---|---|---|
| `V$IOSTAT_FUNCTION`, `V$IOSTAT_FILE` | sim | sim |
| `V$EVENT_HISTOGRAM` | sim | sim |
| `V$EVENT_HISTOGRAM_MICRO` | não | 12.1.0.2+ |
| `V$DIAG_ALERT_EXT` | não (grep no alert log) | sim |
| `FETCH FIRST n ROWS` | não (use `ROWNUM`) | sim |
| `V$PROCESS.STID` | não | sim |
| `pga_aggregate_limit` | não | sim |
| `CON_ID` nas views V$ | não | sim |
