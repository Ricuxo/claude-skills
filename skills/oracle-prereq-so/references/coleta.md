# Coleta no servidor (somente leitura)

Rodar como `root` (algumas leituras exigem) ou entregar a quem tem acesso. Nada aqui altera
o sistema. O script não decide nada: só imprime, por seção, para comparar com a
documentação.

Ajuste antes de rodar:
- `ORA_USER` — dono do software Oracle (padrão `oracle`).
- `GRID_USER` — dono do Grid, se houver separação de papéis (vazio se não houver).
- `MOUNTS` — pontos de montagem onde o software e os dados vão ficar.

## Execução remota

Teste o acesso antes, sem prompt de senha:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 <usuário>@<alvo> 'hostname'
```

Rode o script inteiro numa chamada, mandando-o pela entrada padrão (o conteúdo do script
não aparece na linha de comando do processo remoto, o que evita falso positivo nas buscas
por processo):

```bash
ssh -o BatchMode=yes <usuário>@<alvo> 'bash -s' <<'EOF'
<script base>
EOF
```

Falhas comuns: `No route to host` (VM desligada, IP errado ou outra rede virtual);
`Permission denied (publickey...)` (sem chave autorizada; ver Passo 1 do SKILL.md).

## Script base

```bash
ORA_USER=oracle
GRID_USER=
MOUNTS="/u01 /tmp /dev/shm"

sec(){ echo; echo "### $1"; }

sec "SO";            cat /etc/os-release | grep -E '^(NAME|VERSION|ID|VERSION_ID)='; uname -r; uname -m
sec "CPU";           nproc; lscpu | grep -E '^(Model name|Socket|Core|Thread)'
sec "MEMORIA";       grep -E '^(MemTotal|MemAvailable|SwapTotal|SwapFree|HugePages_|Hugepagesize|PageTables|Shmem):' /proc/meminfo
sec "PAGE_SIZE";     getconf PAGE_SIZE
sec "THP";           cat /sys/kernel/mm/transparent_hugepage/enabled /sys/kernel/mm/transparent_hugepage/defrag 2>&1; grep -o 'transparent_hugepage=[^ ]*' /proc/cmdline || echo "(sem parametro no cmdline)"
sec "ESPACO";        df -hP $MOUNTS 2>&1
sec "DEV_SHM";       findmnt -no FSTYPE,OPTIONS /dev/shm 2>&1
sec "SYSCTL_EM_USO"; sysctl kernel.sem kernel.shmall kernel.shmmax kernel.shmmni kernel.panic_on_oops kernel.panic \
                       fs.file-max fs.aio-max-nr net.ipv4.ip_local_port_range \
                       net.core.rmem_default net.core.rmem_max net.core.wmem_default net.core.wmem_max \
                       vm.nr_hugepages vm.swappiness 2>&1
sec "SYSCTL_PERSISTIDO"; grep -HvE '^\s*(#|$)' /etc/sysctl.conf /etc/sysctl.d/*.conf 2>/dev/null
sec "LIMITS_CONFIG"; grep -HvE '^\s*(#|$)' /etc/security/limits.conf /etc/security/limits.d/*.conf 2>/dev/null
for u in $ORA_USER $GRID_USER; do
  id "$u" >/dev/null 2>&1 || { sec "USUARIO $u"; echo "(usuario nao existe)"; continue; }
  sec "LIMITS_EFETIVO $u"; su - "$u" -c 'ulimit -Sn; ulimit -Hn; ulimit -Su; ulimit -Hu; ulimit -Ss; ulimit -Hs; ulimit -Sl; ulimit -Hl' 2>&1 \
    | paste -sd' ' | awk '{print "nofile soft="$1" hard="$2" | nproc soft="$3" hard="$4" | stack soft="$5" hard="$6" | memlock soft="$7" hard="$8}'
  sec "USUARIO $u";  id "$u" 2>&1; getent passwd "$u" | cut -d: -f1,3,4,6,7
done
sec "GRUPOS";        getent group oinstall dba oper backupdba dgdba kmdba racdba asmdba asmoper asmadmin 2>&1
sec "PREINSTALL";    rpm -qa 'oracle-database-preinstall*' 'oracle-ai-database-preinstall*' 2>&1
sec "HORARIO";       timedatectl 2>&1 | grep -E 'Time zone|synchronized|NTP'; systemctl is-active chronyd ntpd 2>&1; chronyc tracking 2>&1 | head -5
sec "HOSTNAME";      hostname; hostname -f 2>&1; getent ahostsv4 "$(hostname)" 2>&1 | head -1; getent ahostsv6 "$(hostname)" 2>&1 | head -1; grep -vE '^\s*(#|$)' /etc/hosts
sec "SELINUX_FIREWALL"; getenforce 2>&1; systemctl is-active firewalld 2>&1
sec "ORACLE_EXISTENTE"; cat /etc/oraInst.loc 2>&1; grep -vE '^\s*(#|$)' /etc/oratab 2>&1; pgrep -fa 'ora_pmon_|asm_pmon_|ohasd' 2>&1 || echo "(nenhum processo Oracle)"
sec "OUTROS_SGBD_PROCESSOS"; pgrep -ax 'mysqld|mariadbd|postgres|postmaster|sqlservr|mongod|db2sysc|redis-server|dataserver|edb-postgres' 2>&1 || echo "(nenhum)"
sec "OUTROS_SGBD_SERVICOS"; systemctl list-unit-files --no-legend 'mysql*' 'mariadb*' 'postgresql*' 'edb-as*' 'mssql-server*' 'mongod*' 'db2*' 'redis*' 2>&1 || echo "(nenhum)"
sec "OUTROS_SGBD_PACOTES"; rpm -qa 2>/dev/null | grep -iE '^(mysql|mariadb|percona|postgresql|edb-as|mssql-server|mongodb|db2|redis)' || echo "(nenhum)"
sec "OUTROS_SGBD_DADOS"; achou=0; for d in /var/lib/mysql /var/lib/pgsql /var/lib/postgresql /var/opt/mssql /var/lib/mongo /opt/ibm/db2; do [ -d "$d" ] && { echo "$d"; achou=1; }; done; [ $achou = 1 ] || echo "(nenhum)"
sec "OUTROS_SGBD_DIR_REAL"; r=$(pgrep -ax 'mysqld|mariadbd|postgres|postmaster|sqlservr|mongod|edb-postgres' 2>/dev/null | grep -oE '(-D|--datadir|--dbpath|--pgdata)[= ]+[^ ]+' | sort -u); [ -n "$r" ] && echo "$r" || echo "(nenhum parametro de diretorio nos processos)"
sec "PORTAS_EM_ESCUTA"; ss -ltnpH 2>&1 | awk '{print $4, $6}' | grep -E ':(1521|1522|3306|5432|1433|27017|50000|6379|5000)\b' || echo "(nenhuma porta de banco conhecida)"
```

`LIMITS_EFETIVO` usa `su - <usuário>`, que abre sessão de login e executa o `.bash_profile`
e o `.bashrc` desse usuário. É o que dá os limits efetivos via PAM, mas num servidor que já
tem Oracle o perfil pode ter qualquer coisa (exports, `sqlplus`, menus). Diga isso a quem
for rodar o script; se o perfil travar ou pedir entrada, interrompa e marque os limits
efetivos como NÃO VERIFICADO.

`OUTROS_SGBD_*` (inclusive `OUTROS_SGBD_DIR_REAL`, o diretório de dados real tirado da linha de comando do processo, que pode estar fora dos caminhos padrão) e `PORTAS_EM_ESCUTA` servem para identificar **alvo errado**: servidor com
MySQL, MariaDB, PostgreSQL, SQL Server, MongoDB, Db2, Redis ou SAP ASE instalado ou rodando.
A porta 1521 ocupada por processo que não é `tnslsnr` também entra aqui.

Para comparar com a documentação, o que importa de cada seção:
- `MEMORIA` + `PAGE_SIZE`: calcular `shmmax`/`shmall` e a faixa de swap conforme a fórmula
  da página da versão.
- `SYSCTL_EM_USO` × `SYSCTL_PERSISTIDO`: se divergirem, o valor volta ao persistido no
  próximo boot. A lista de parâmetros acima é ponto de partida: inclua qualquer outro que a
  tabela da versão exigir.
- `LIMITS_EFETIVO` é o que vale para a instalação; `LIMITS_CONFIG` explica de onde vem.
- `ORACLE_EXISTENTE` não é requisito: indica se é pré-instalação ou auditoria.

## Pacotes

Depois de extrair a lista de pacotes da documentação da versão e da distro coletada,
rode com essa lista (exemplo de formato, não de conteúdo):

```bash
rpm -q --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' <pacote1> <pacote2> ... 2>&1
```

`package ... is not installed` = `FALTA`. Versão abaixo da mínima da doc = `DIVERGE`.

## ASM

```bash
ls -l /dev/oracleasm/disks/ 2>&1            # se ASMLib
ls -lL <devices esperados> 2>&1             # dono, grupo, permissão
grep -vE '^\s*(#|$)' /etc/udev/rules.d/*asm* /etc/udev/rules.d/*oracle* 2>&1
lsblk -o NAME,SIZE,TYPE,OWNER,GROUP,MODE 2>&1
```

## RAC (rodar em todos os nós)

```bash
ip -br addr
getent hosts <nome-scan> 2>&1               # deve resolver os IPs do SCAN
su - <dono-grid> -c 'ssh -o BatchMode=yes <outro-no> hostname' 2>&1
```

Compare as saídas do script base entre os nós: kernel, pacotes, sysctl, limits e
horário devem ser iguais.
