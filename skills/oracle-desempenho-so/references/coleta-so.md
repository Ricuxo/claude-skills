# Coleta no sistema operacional

Rode como `oracle` (ou entregue ao time de infra). Colete **durante** o período ruim — quase
nada aqui tem histórico, exceto `sar`, OSWatcher e nmon. Em sessão interativa, um comando por
vez, na ordem: CPU → memória → I/O → rede.

## CPU

```bash
vmstat 5 12            # coluna r = processos prontos esperando CPU; compare com nº de threads
                       # coluna st = steal (VM); acima de ~5% o hypervisor está tomando CPU
mpstat -P ALL 5 5      # %sys alto = kernel (I/O sem async, page tables, THP); %iowait; %steal
nproc; lscpu | egrep 'Socket|Core|Thread|Model name|NUMA'
numactl --hardware
top -b -n 1 -o %CPU | head -25
```

## Memória

```bash
free -m                                    # 'available' importa, não 'free'
egrep -i 'MemTotal|MemAvailable|SwapTotal|SwapFree|Huge|PageTables' /proc/meminfo
cat /proc/sys/vm/swappiness                # em servidor de banco: baixo (1–10)
uname -r                                   # a regra do THP depende do kernel (UEK7+ ou anterior)
cat /sys/kernel/mm/transparent_hugepage/enabled   # esperado: [madvise] em UEK7+, [never] antes (ver 5.4)
cat /sys/kernel/mm/transparent_hugepage/defrag
dmesg -T | grep -iE 'oom|out of memory|killed process|hung_task'
```

Leitura das HugePages: `HugePages_Total` alocadas; `HugePages_Free` próximo de `Total` com o
banco no ar significa que a SGA **não** está usando — cheque `memory_target` e o alert log.
`HugePages_Rsvd` são reservadas e ainda não tocadas. `PageTables` com vários GB = SGA grande
sem HugePages.

## I/O

```bash
iostat -xmz 5 12
pidstat -d 5 5                 # I/O por processo
iotop -obn 3                   # alternativa, exige root na maioria das distros
dmesg -T | grep -iE 'i/o error|blk_update|reset|timeout|multipath'
```

Colunas do `iostat` (sysstat recente): `r_await`/`w_await` = latência em ms por operação;
`aqu-sz` (antigo `avgqu-sz`) = fila média; `%util` = tempo com pelo menos uma requisição ativa.

**`%util` só indica saturação em disco único rotacional.** SSD, NVMe e LUN de SAN atendem
várias requisições em paralelo: chegam a 100% de `%util` com folga sobrando. Nesses, olhe
latência e fila.

### Mapeamento disco ASM → device

```bash
multipath -ll                          # LUN → dm-N e caminhos ativos/falhos
ls -l /dev/mapper/ /dev/oracleasm/disks/ 2>/dev/null
oracleasm listdisks 2>/dev/null        # se ASMLib
oracleasm querydisk -p <DISCO> 2>/dev/null
lsblk -o NAME,KNAME,SIZE,TYPE,MOUNTPOINT
cat /etc/udev/rules.d/*asm* 2>/dev/null
```

Cruze `V$ASM_DISK.PATH` com essa saída para saber qual `dm-N` do `iostat` é qual disco ASM.

## Rede

```bash
sar -n DEV 5 5
sar -n EDEV 5 5                       # erros e drops por interface
ip -s link
netstat -s | grep -iE 'retrans|reassem|fail|overflow'
ethtool -S <interface> 2>/dev/null | grep -iE 'err|drop|crc'
```

RAC: rode na interface **privada**. Falhas de remontagem (`reassem`) ou retransmissões
crescendo com `gc blocks lost` > 0 = MTU inconsistente entre nós/switch ou buffers UDP
pequenos (`net.core.rmem_max`). Confirme o MTU dos dois lados: `ip link show <interface>`.

## Histórico do dia (sysstat)

```bash
SA=/var/log/sa; [ -d "$SA" ] || SA=/var/log/sysstat   # RHEL/OL vs Debian/Ubuntu
D=$SA/sa$(date +%d)
sar -u -f $D     # CPU
sar -q -f $D     # run queue e load — o mais útil para "ontem às 14h"
sar -r -f $D     # memória
sar -B -f $D     # paginação
sar -W -f $D     # swap
sar -b -f $D     # I/O
sar -n DEV -f $D # rede
```

Para dia anterior, troque `date +%d` por `date -d yesterday +%d`.

## Limites e montagem

Os limites que valem são os do processo em execução, não os da sua sessão de shell:

```bash
cat /proc/$(pgrep -f ora_pmon_ | head -1)/limits
df -h
mount | grep -iE 'oracle|u0'
```

Confira `Max open files`, `Max processes` e `Max locked memory` (este último precisa cobrir a
SGA para HugePages funcionar).

## OSWatcher e nmon

Se existirem, peça os arquivos da janela ruim: são a única fonte de histórico de SO na maioria
dos ambientes e cobrem exatamente o período que o usuário quer entender.
