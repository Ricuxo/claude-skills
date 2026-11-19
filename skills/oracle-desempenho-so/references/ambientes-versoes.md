# Ambientes especiais e diferenças por versão

## Ambientes

- **Data Guard:** standby em `MOUNTED` responde a `V$OSSTAT` e `V$SYSTEM_EVENT`, mas o perfil de
  I/O é de recuperação. Não compare com o primary.
- **Exadata:** eventos mudam de nome (`cell single block physical read`, `cell smart table scan`)
  e as referências de latência são outras. Se aparecer `cell%`, diga que é Exadata e ajuste a
  leitura.
- **VM:** `V$OSSTAT` vê só o SO convidado. Verifique `%steal` antes de concluir que há CPU
  sobrando.
- **Contêiner, cgroup, LPAR, zonas:** o banco pode ver mais CPU do que a cota permite. Compare
  `NUM_CPUS` com a cota (`cat /sys/fs/cgroup/cpu.max` em cgroup v2) antes de calcular saturação.
- **Nuvem gerenciada (RDS, Autonomous):** sem shell; diga que a cobertura de SO depende das
  métricas do provedor.

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
| Polling adaptativo do `log file sync` | não | sim |

**Unidade de `READ_TIME`/`WRITE_TIME` em `V$ASM_DISK_IOSTAT`:** a referência 19c+ documenta
segundos (a consulta de `references/rac-asm.md` usa `*1000` para chegar a ms). O manual 11.2
documenta centésimos de segundo. Em 11g, se o ms resultante sair ~100× acima do que o
`iostat -x` mostra para o mesmo device, a unidade é a do manual 11.2: troque `*1000` por `*10`.
