# Consultas de apoio (janela curta, TEMP, I/O, rede e limites)

Consultas citadas no `SKILL.md`. A interpretação de cada uma fica no passo correspondente de lá;
aqui só o SQL. Todas são somente leitura.

## Passo 3 — Janela curta

`V$SYSMETRIC` (`group_id = 2`): taxas do último minuto.

```sql
SELECT metric_name, ROUND(value,2) AS valor, metric_unit,
       TO_CHAR(begin_time,'HH24:MI:SS') AS inicio, TO_CHAR(end_time,'HH24:MI:SS') AS fim
  FROM v$sysmetric
 WHERE group_id = 2
   AND metric_name IN ('Host CPU Utilization (%)','CPU Usage Per Sec','Database CPU Time Ratio',
       'Database Wait Time Ratio','Average Active Sessions','Current OS Load',
       'Physical Read Total IO Requests Per Sec','Physical Write Total IO Requests Per Sec',
       'I/O Megabytes per Second','I/O Requests per Second','Redo Generated Per Sec',
       'Logons Per Sec','User Transaction Per Sec','Executions Per Sec')
 ORDER BY metric_name
```

`V$SYSMETRIC_HISTORY`: cerca de uma hora, minuto a minuto.

```sql
SELECT TO_CHAR(end_time,'HH24:MI') AS minuto, ROUND(value,2) AS valor
  FROM v$sysmetric_history
 WHERE metric_name = 'Host CPU Utilization (%)' AND group_id = 2
 ORDER BY end_time
```

**Ressalva para dizer ao usuário:** as views `V$SYSMETRIC*` são populadas pelo MMON, a mesma
infraestrutura do AWR, e há auditores que as tratam como área cinzenta. Contadores puros
(`V$OSSTAT`, `V$SYSSTAT`, `V$SYSTEM_EVENT`) não têm essa ambiguidade. Em ambiente sensível a
auditoria, prefira o delta manual e registre a escolha no relatório.

## Passo 4.4 — Resource Manager

```sql
SELECT event, total_waits, ROUND(time_waited_micro/1000000,2) AS seg_total
  FROM v$system_event WHERE event LIKE 'resmgr%' ORDER BY time_waited_micro DESC
```

## Passo 5.3 — TEMP por sessão

```sql
SELECT s.username, s.sid, s.program, u.tablespace,
       ROUND(SUM(u.blocks * t.block_size)/1048576,2) AS temp_mb,
       MAX(u.segtype) AS tipo, MAX(u.sql_id) AS sql_id
  FROM v$tempseg_usage u
  JOIN v$session s ON s.saddr = u.session_addr
  JOIN dba_tablespaces t ON t.tablespace_name = u.tablespace
 GROUP BY s.username, s.sid, s.program, u.tablespace
 ORDER BY temp_mb DESC
```

Em CDB, rode no PDB da aplicação (no root, `DBA_TABLESPACES` não enxerga a TEMP do PDB).

## Passo 6.1 — Latência de I/O percebida pelo banco

Média por evento:

```sql
SELECT event, total_waits, ROUND(time_waited_micro/1000000,2) AS seg_total,
       ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,2) AS ms_medio, wait_class
  FROM v$system_event
 WHERE event IN ('db file sequential read','db file scattered read','db file parallel read',
                 'direct path read','direct path read temp','direct path write','direct path write temp',
                 'log file parallel write','log file sync','control file sequential read',
                 'db file async I/O submit')
 ORDER BY time_waited_micro DESC
```

Distribuição em milissegundos:

```sql
SELECT event, wait_time_milli AS ate_ms, wait_count,
       ROUND(RATIO_TO_REPORT(wait_count) OVER (PARTITION BY event)*100,2) AS pct
  FROM v$event_histogram
 WHERE event IN ('db file sequential read','log file parallel write','log file sync')
 ORDER BY event, wait_time_milli
```

Distribuição em microssegundos (12.1.0.2+), para flash e NVMe:

```sql
SELECT event, wait_time_format, wait_count
  FROM v$event_histogram_micro
 WHERE event IN ('db file sequential read','log file parallel write')
 ORDER BY event, wait_time_micro
```

## Passo 6.2 — Distribuição por arquivo

Datafiles:

```sql
SELECT d.name AS arquivo, t.name AS tablespace, f.phyrds, f.phywrts,
       ROUND(f.phyblkrd * d.block_size/1073741824,2) AS gb_lidos,
       f.singleblkrds,
       ROUND(f.singleblkrdtim*10/NULLIF(f.singleblkrds,0),2) AS ms_bloco_unico,
       ROUND(f.readtim*10/NULLIF(f.phyrds,0),2) AS ms_leitura_media,
       ROUND(f.writetim*10/NULLIF(f.phywrts,0),2) AS ms_escrita_media
  FROM v$filestat f JOIN v$datafile d ON d.file# = f.file#
  JOIN v$tablespace t ON t.ts# = d.ts#
 ORDER BY f.phyrds + f.phywrts DESC
```

Tempfiles:

```sql
SELECT tf.name AS tempfile, ts.phyrds, ts.phywrts,
       ROUND(ts.readtim*10/NULLIF(ts.phyrds,0),2) AS ms_leitura,
       ROUND(ts.writetim*10/NULLIF(ts.phywrts,0),2) AS ms_escrita
  FROM v$tempstat ts JOIN v$tempfile tf ON tf.file# = ts.file#
 ORDER BY ts.phyrds + ts.phywrts DESC
```

Tempos em centésimos de segundo (daí o `*10`).

## Passo 6.3 — Quem gera o I/O (11g+)

```sql
SELECT function_name,
       ROUND((small_read_megabytes+large_read_megabytes)/1024,2) AS gb_lidos,
       ROUND((small_write_megabytes+large_write_megabytes)/1024,2) AS gb_escritos,
       small_read_reqs+large_read_reqs AS reqs_leitura,
       small_write_reqs+large_write_reqs AS reqs_escrita,
       number_of_waits,
       ROUND(wait_time/NULLIF(number_of_waits,0),2) AS ms_medio
  FROM v$iostat_function
 WHERE small_read_megabytes+large_read_megabytes+small_write_megabytes+large_write_megabytes > 0
 ORDER BY small_read_megabytes+large_read_megabytes+small_write_megabytes+large_write_megabytes DESC
```

## Passo 6.5 — Parâmetros de I/O

```sql
SELECT name, value, isdefault FROM v$parameter
 WHERE name IN ('filesystemio_options','disk_asynch_io','db_file_multiblock_read_count',
                'db_writer_processes','dbwr_io_slaves','log_archive_max_processes','db_block_size')
 ORDER BY name
```

## Passo 7 — Rede e limites de instância

Eventos de rede:

```sql
SELECT event, total_waits, ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,3) AS ms_medio,
       ROUND(time_waited_micro/1000000,2) AS seg_total
  FROM v$system_event
 WHERE event LIKE 'SQL*Net%' OR event LIKE '%TCP%'
 ORDER BY time_waited_micro DESC
```

Limites de instância:

```sql
SELECT resource_name, current_utilization, max_utilization, initial_allocation, limit_value,
       ROUND(max_utilization/NULLIF(TO_NUMBER(REPLACE(limit_value,'UNLIMITED','0')),0)*100,1) AS pct_pico
  FROM v$resource_limit
 WHERE resource_name IN ('processes','sessions','transactions','enqueue_locks','enqueue_resources',
                         'dml_locks','temporary_table_locks','max_shared_servers','parallel_max_servers')
 ORDER BY resource_name
```