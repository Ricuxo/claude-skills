# Histórico com Diagnostic Pack

Use **somente** com Diagnostic Pack licenciado. Compare sempre duas janelas — a ruim e uma
normal equivalente (mesmo dia da semana, mesmo horário). Número absoluto sem comparação não
diagnostica nada.

## CPU do host por snapshot (últimos 7 dias)

O delta é particionado por banco e instância e descarta intervalos com restart, em que o
contador zera e o delta ficaria negativo.

```sql
SELECT janela, inst, stat_name, delta
  FROM (SELECT TO_CHAR(sn.begin_interval_time,'DD/MM HH24:MI') AS janela,
               os.instance_number AS inst, os.stat_name, sn.snap_id,
               os.value - LAG(os.value) OVER (PARTITION BY os.dbid, os.instance_number, os.stat_name
                                              ORDER BY sn.snap_id) AS delta,
               CASE WHEN sn.startup_time = LAG(sn.startup_time) OVER (PARTITION BY os.dbid, os.instance_number, os.stat_name
                                                                      ORDER BY sn.snap_id)
                    THEN 1 ELSE 0 END AS mesma_vida
          FROM dba_hist_osstat os
          JOIN dba_hist_snapshot sn
            ON sn.snap_id = os.snap_id AND sn.dbid = os.dbid AND sn.instance_number = os.instance_number
         WHERE os.stat_name IN ('BUSY_TIME','IDLE_TIME','IOWAIT_TIME','SYS_TIME')
           AND sn.begin_interval_time > SYSDATE - 7)
 WHERE mesma_vida = 1
 ORDER BY snap_id, inst, stat_name
```

`%CPU = Δbusy / (Δbusy + Δidle)` em cada janela e instância.

## Métricas resumidas por snapshot

```sql
SELECT TO_CHAR(sn.begin_interval_time,'DD/MM HH24:MI') AS janela, m.instance_number AS inst,
       m.metric_name, ROUND(m.average,2) AS media, ROUND(m.maxval,2) AS pico
  FROM dba_hist_sysmetric_summary m
  JOIN dba_hist_snapshot sn
    ON sn.snap_id = m.snap_id AND sn.dbid = m.dbid AND sn.instance_number = m.instance_number
 WHERE m.metric_name IN ('Host CPU Utilization (%)','Average Active Sessions','Current OS Load',
                         'I/O Megabytes per Second','I/O Requests per Second')
   AND sn.begin_interval_time > SYSDATE - 7
 ORDER BY sn.snap_id, m.instance_number, m.metric_name
```

`pico` muito acima de `media` na mesma janela = rajadas curtas que a média horária esconde.

## Relatório AWR

`@?/rdbms/admin/awrrpt.sql` (ou `awrrpti.sql` para escolher instância, `awrgrpt.sql` para RAC
global) da janela ruim traz **Host CPU**, **Instance CPU**, **IOStat by Function** e
**Wait Event Histogram** prontos. `awrddrpt.sql` compara duas janelas lado a lado — é o
formato mais útil para este nível.

Executar o script de relatório só lê; não altera nada.

## Sem pack

Statspack (`@?/rdbms/admin/spcreate.sql`) cobre boa parte disso sem custo de licença, mas
**cria usuário, tablespace e objetos** — é mudança, não coleta. Recomende para o próximo
incidente, com janela e aprovação; não ajuda no de hoje.
