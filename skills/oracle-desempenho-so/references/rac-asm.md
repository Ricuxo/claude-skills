# RAC e ASM

Leia a seção que se aplica ao ambiente. Ambas são somente leitura.

## ASM

Latência por disco e diskgroup vista por esta instância (`READ_TIME`/`WRITE_TIME` em segundos):

```sql
SELECT dg.name AS diskgroup, d.path, i.reads, i.writes, i.read_errs, i.write_errs,
       ROUND(i.read_time*1000/NULLIF(i.reads,0),2) AS ms_leitura,
       ROUND(i.write_time*1000/NULLIF(i.writes,0),2) AS ms_escrita,
       ROUND(i.bytes_read/1073741824,2) AS gb_lidos,
       ROUND(i.bytes_written/1073741824,2) AS gb_escritos
  FROM v$asm_disk_iostat i
  JOIN v$asm_disk_stat d ON d.group_number = i.group_number AND d.disk_number = i.disk_number
  JOIN v$asm_diskgroup_stat dg ON dg.group_number = i.group_number
 ORDER BY dg.name, d.path
```

Um disco com latência muito acima dos irmãos no mesmo diskgroup = LUN ou caminho de multipath
degradado. `read_errs`/`write_errs` > 0 é achado crítico. O mapeamento disco ASM → device do SO
está em `references/coleta-so.md` — sem ele, o `iostat` mostra `dm-17` e ninguém sabe o que é.

## Interconnect

```sql
SELECT inst_id, event, total_waits, ROUND(time_waited_micro/NULLIF(total_waits,0)/1000,3) AS ms_medio
  FROM gv$system_event
 WHERE event IN ('gc cr block 2-way','gc current block 2-way','gc cr block 3-way',
                 'gc current block 3-way','gc cr block busy','gc buffer busy acquire',
                 'gc cr block lost','gc current block lost')
 ORDER BY inst_id, time_waited_micro DESC
```

```sql
SELECT inst_id, name, value FROM gv$sysstat
 WHERE name IN ('gc blocks lost','gc blocks corrupt') ORDER BY inst_id, name
```

```sql
SELECT inst_id, name, ip_address, is_public, source FROM gv$cluster_interconnects ORDER BY inst_id
```

`gc ... 2-way` acima de ~1 ms em rede dedicada = interconnect lento. `gc blocks lost` diferente
de zero e crescendo = perda de pacote na rede privada (MTU inconsistente, buffer UDP pequeno,
placa com erro) — confirme no SO. Interconnect com `is_public = YES` é erro de configuração.
