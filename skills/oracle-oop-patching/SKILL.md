---
name: oracle-oop-patching
description: Conduz patching out-of-place de Oracle 19c (GI + DB) com opatchauto -prepare-clone/-switch-clone em Oracle Restart, RAC e Data Guard, passo a passo, da seleção de patches ao rollback.
---

# Patching out-of-place Oracle 19c (opatchauto prepare-clone / switch-clone)

Método para aplicar uma Release Update (RU) com one-offs em GI e DB homes, preparando clones sem downtime e trocando de home só na janela de mudança.

Esta skill **guia**. Por padrão, o usuário roda os comandos nos servidores e cola as saídas.

**Quando o usuário pedir para acessar o servidor** (e houver acesso SSH configurado):
- Comandos e consultas **só de leitura** (levantamento, `lspatches`, `crsctl stat`, `dgmgrl show`, SELECTs nos standbys) podem ser executados diretamente.
- **Qualquer alteração** (arquivos de configuração, srvctl modify, Broker, OPatch, stage, opatchauto) só depois de mostrar o que será feito e receber o OK explícito.
- Antes de editar um arquivo de configuração (listener.ora, oratab etc.), faça backup com sufixo de timestamp (`<arquivo>.bak_YYYYMMDD_HHMMSS`) e mostre o `diff` depois.
- `/etc/oratab` se edita como **root**: o `sed -i` como owner falha porque ele não consegue criar o temporário em `/etc`.
- Alterações no **primário de produção** (ex.: `ALTER SYSTEM`) só com pedido explícito. Diagnostique e entregue o comando.
- **O backup vem antes, e o script aborta se ele falhar.** Todo script SQL de mudança começa com `whenever sqlerror exit failure`. Sem isso, um `create pfile` que falha não impede o `ALTER SYSTEM` seguinte, e a mudança fica sem backup.
- O diretório de destino de arquivos gravados **pelo banco** (`create pfile`, Data Pump, trace) precisa pertencer ao owner da home. Um diretório criado como root dá ORA-07391.

## Abertura obrigatória (antes do primeiro comando)

Identifique, perguntando só o que não estiver claro na conversa:
1. **Host** e, se for RAC, o nó.
2. **Tipo:** Oracle Restart ou RAC, e se é primário ou standby.
3. **Fase:** **Preparação** (fases 1 a 5, sem downtime), **Janela de mudança** (fase 6), **DST** (fase 7) ou **Rollback** (fase 8).
4. **RU alvo** e, se já existir, a lista de patches definida para o ciclo.

Resuma em uma linha o que entendeu (ex.: "Preparação — <host>, Restart, standby, RU 19.xx") e só então comece pela fase indicada.

Nunca avance da Preparação para a janela de mudança por conta própria. A troca de home só começa quando o usuário disser que está na janela aprovada.

## Padrão de Oracle Home (destino dos clones)

Padrão default para as homes novas, com a versão da RU em **4 octetos**:

| Home | Caminho |
|---|---|
| GI | `/u01/app/<RU>.0.0/grid` |
| DB | `/u01/app/oracle/product/<RU>.0.0/db_1` |

Exemplo para a RU 19.33: `/u01/app/19.33.0.0/grid` e `/u01/app/oracle/product/19.33.0.0/db_1`.

- Se o ambiente tiver outro padrão (outro mount point, ORACLE_BASE ou nome de home), pergunte e use o do ambiente.
- As homes de origem podem estar em qualquer padrão: leia o caminho real no `olr.loc` e no `crsctl`, nunca suponha.
- Se o host tiver mais de uma DB home de origem, pergunte o nome de destino de cada uma antes de montar o `clone.properties`.

## Como conduzir

- **Um passo por vez.** Mande um comando ou uma verificação, espere a saída colada e só então proponha o próximo. Não antecipe hipóteses nem várias etapas.
- **Indique o usuário em todo bloco de comandos:** **👤 root** ou **👤 oracle** (owner das homes; se a GI tiver owner separado, como `grid`, use o owner correto de cada home).
  - O `opatchauto` roda como **root**.
  - O `opatch` (lspatches, version, prereq), o unzip, o `-detachHome`, o srvctl, o dgmgrl e o SQL rodam como o **owner da home**. Como root, o opatch recusa (*OPatch cannot continue if the user is root*).
- Português na conversa, inglês nos comandos.
- Só sugira o que tiver referência da Oracle (MOS/KB, README do patch, documentação). Sem fonte on-prem, diga que não há base para afirmar.
- Antes de qualquer ação destrutiva ou de troca de home, diga o impacto e peça confirmação explícita.

## Fase 1 — Levantamento do host

1. Tipo de instalação (👤 root): `cat /etc/oracle/ocr.loc` (`local_only=TRUE` significa Oracle Restart). GRID_HOME: `grep -oP '^crs_home=\K.*' /etc/oracle/olr.loc`.
2. Bancos e homes (👤 root): `$GH/bin/crsctl stat res -t -w "TYPE = ora.database.type"`. Não confie no oratab.
   - **Compare com os pmon** (`ps -ef | grep pmon`). Se uma instância roda mas o recurso está `OFFLINE`/`TARGET=OFFLINE` (ex.: *Abnormal Termination*), ela foi iniciada fora do CRS. No switch-clone, o opatchauto para e religa pelo CRS, então ela pode não voltar. Corrija antes da janela: parar e subir com `srvctl`.
   - Confira se o SID que está rodando é o mesmo do `srvctl config database -db <db>` (*Database instance*). Se for diferente, padronize com `srvctl modify database -db <db> -instance <sid>` e reinicie pelo srvctl.
   - Entradas de SID que não existem mais no oratab são resíduo: remova com backup, depois de confirmar que não há pmon com aquele nome.
3. Patches atuais de cada home (👤 oracle): `opatch lspatches -oh <HOME>`. Anote a RU e **todos os one-offs**.
4. Em RAC: confira se o inventário é idêntico em todos os nós (o rolling quebra se houver divergência).
5. Data Guard: identifique primário e standbys, se usa Broker (`dg_broker_start`), TDE (`gv$encryption_wallet`) e quais standbys ficam em cada host. Em cada standby: `v$database` (papel e open_mode), MRP em `v$managed_standby` e lag em `v$dataguard_stats`.
   - **Broker** (👤 oracle): `dgmgrl / "show configuration"` **em cada configuração**. ORA-16525/ORA-16625 vindos do primário → confira `dg_broker_start` no primário (pode estar FALSE). O `drc<sid>.log` do standby mostra desde quando. Antes de religar, pergunte por que foi desligado.
   - `show database <standby>` lista as instâncias. Instância **fantasma** (SHUTDOWN, SID antigo) → `remove instance <sid> on database <db>`.
   - No 19c, o `StaticConnectIdentifier` é propriedade da **instância**: `show instance <sid> StaticConnectIdentifier on database <db>`.
   - **Listener estático** (`listener.ora` da GI): o `SID_NAME` precisa ser **idêntico ao SID real**, porque no Linux ele diferencia maiúsculas de minúsculas. Se não for, o Broker não consegue subir a instância em switchover ou failover. Padrão do `GLOBAL_DBNAME`: `<db_unique_name>_DGMGRL`. Depois de corrigir, `lsnrctl reload` (sem downtime) e `show configuration` em todos os bancos do host.
6. Recursos afetados pela GI: filesystems ACFS montados (`mount -t acfs`), GoldenGate, QoS (`srvctl status qosmserver`).
7. **HugePages** (só leitura). O switch-clone reinicia todas as instâncias do host, e cada uma realoca a SGA nesse momento.
   - 👤 oracle: `grep -i huge /proc/meminfo`, `cat /sys/kernel/mm/transparent_hugepage/enabled` e, em cada instância, `use_large_pages`, `sga_max_size` e `memory_target`.
   - Necessário: a soma de `ipcs -m` (bytes ÷ Hugepagesize), que é o método do MOS 401749.1, comparada com `HugePages_Total`.
   - **Prova por instância:** no alert log do último startup, a tabela `Supported system pagesize(s)` (19c). Se `ALLOCATED_PAGES` de 4K for alto, a SGA está em páginas pequenas.
   - Com `use_large_pages=TRUE` (o default), se faltar HugePages, a instância sobe **em silêncio** com o resto da SGA em 4 KB. O resultado é mais page table, SGA sujeita a swap e lentidão depois da janela, que parece culpa do patch.
   - A Oracle recomenda `ONLY` *"for consistent performance"* (Database Reference 19c, `USE_LARGE_PAGES`). Com `ONLY`, a instância não sobe se faltar HugePages, e ele não pode coexistir com `MEMORY_TARGET` ou `MEMORY_MAX_TARGET` explícitos no spfile. Um ASM com AMM fica com `FALSE` automaticamente, e isso é normal.
   - **Encontrou `TRUE`:** avise e pergunte se é para alterar. Se o usuário disser que sim, **calcule antes** se o pool comporta a soma das SGAs de todas as instâncias do host.
   - Ordem segura, com cada passo confirmado:
     1. Aumentar o pool com `sysctl -w vm.nr_hugepages=<n>` (👤 root).
     2. Conferir se o `HugePages_Total` chegou ao valor pedido. Com memória fragmentada, o kernel pode alocar menos.
     3. Só então persistir no `sysctl.conf`, com backup e `diff`. Confira antes se o valor não vem também da cmdline ou do tuned.
     4. Por último, `alter system set use_large_pages='ONLY' scope=spfile sid='*'`, que vale no restart do switch.
     - Rollback: `sysctl -w` com o valor antigo e `alter system reset use_large_pages scope=spfile sid='*'`.
     - Nunca grave `ONLY` com o pool menor que a soma, porque a última instância a subir no switch não volta (ORA-27106).

## Fase 2 — Seleção de patches (mudança mínima)

Regra: **só entra one-off com motivo concreto**: um bug confirmado no ambiente, a substituição de um one-off que já está em uso, ou uma condição que existe comprovadamente.

Fontes válidas para on-premises:
- **KB188772 (ex-555.1):** one-offs recomendados por RU. Use a coluna *replaces* para achar o substituto de um one-off que já está em uso, e a coluna *RAC Rolling Installable*.
- **KB136647:** patches de RDBMS para GoldenGate (Integrated Extract/Replicat). Os merges da seção *Highly recommended* não têm descrição: abra os bugs incluídos para ver se se aplicam à captura (origem) ou à aplicação (destino).
- **KB107134:** Data Pump Bundle Patch (DPBP). É não binário, mas **não é RAC rolling**. Só se o Data Pump for usado em produção.
- **KB260868:** índice das notas de Known Issues. Releia perto da janela, porque a nota da RU nova pode sair depois.
- **KM de cada bug:** sempre abra antes de incluir. A descrição resumida engana. Exemplo: o 33566299 (ASM staleness registry) só afeta DB 19c sobre GI 23ai/26ai.
- **README da RU:** mudanças de comportamento (ex.: Tomcat e QoS/WLM removidos a partir da 19.31).

Não use:
- A nota de inventário das imagens do **Exadata Cloud** (ExaDB-D/C@C). Ela é o `lspatches` das imagens de cloud, não uma recomendação para on-prem.
- O título da página de download. Ele costuma ser o do bug interno.

Não coloque a **DB RU avulsa** quando for usar a GI RU, porque ela já vem dentro dela.

Para cada one-off atual, decida:
1. Ele está incluído na nova RU? (👤 oracle) `grep -l 'number="<BUG>"' <GI_RU>/*/etc/config/inventory.xml`. **Valide o método antes** com um bug que sabidamente está incluído (ex.: o primeiro `number=` do `inventory.xml` da DB RU). Se esse controle não aparecer, o padrão de busca está errado, e o resultado "não incluído" não vale.
2. Se não estiver: existe versão para a nova RU no MOS (dropdown Release; o arquivo vem como `p<patch>_<ru>DBRU_Linux-x86-64.zip`), ou um substituto na 555.1? Baixe.
3. Se não existir nenhum dos dois: SR de backport ou decisão consciente de ficar sem ele.

GoldenGate (👤 oracle, SQL): `SELECT con_id, capture_name, capture_type, purpose, status, source_database FROM cdb_capture;` (`GoldenGate Capture` = Integrated Extract), e as condições do bug citadas no KM (ex.: colunas `DEFAULT ON NULL` em `cdb_tab_cols` de schemas com `oracle_maintained='N'`).
- Pode ser consultado no **standby ADG**, porque o dicionário chega pelo redo. Assim o primário de produção não é tocado.
- **Não faça join com `v$pdbs`**: no multitenant, o Integrated Extract é registrado no **CDB$ROOT** (con_id 1), e o join esconde o capture.

**DB home compartilhada por vários standbys:** a home precisa receber a **união** dos one-offs dos primários que ela atende. Se um primário recebe um one-off (ex.: merge GG), o clone da home do standby dele também recebe, para manter os binários iguais em caso de troca de papéis (Standby-First, MOS 1265700.1).

**Validação dos zips no servidor** (👤 oracle):
- `unzip -l` de cada zip e `md5sum`/`sha256sum` para comparar com o MOS.
- OPatch do zip: `unzip -p p6880880_*.zip OPatch/version.txt`.
- Flags de cada one-off: `unzip -p <zip> <patch>/etc/config/inventory.xml | grep -E "online_rac_installable|instance_shutdown|run_as_root"`. No README, confira *RAC Rolling* e *Standby-First Installable* e os pré-requisitos (DB RU e OPatch mínimo).
- O diretório de download pode ter zips que não vão entrar no host (ex.: um one-off de outro host). No stage, extraia **só** os patches selecionados para aquele host.

**One-offs não rolling** ficam fora do switch rolling. Leve para uma janela com downtime (ex.: a do upgrade de DST).

Os patches precisam vir do contrato de suporte que cobre as licenças do ambiente (CSI da organização). Transfira os zips em modo binário (SFTP/SCP).

## Fase 3 — Pré-requisitos

- **OPatch:** a mesma versão, igual ou acima do mínimo do README, em **todas** as homes de todos os nós (👤 oracle). Versão antiga dá OPATCHAUTO-72043. Versões diferentes dão OPATCHAUTO-72088.
  - Guarde o atual como `OPatch_<versão>_<data>`. Não mexa em `OPatch_OLD` de ciclos anteriores.
  - **GI home:** depois do `root.sh`, o diretório da GI home é do root, e o `mv` como owner dá *Permission denied*. Faça o `mv` e o `unzip` como 👤 root e devolva a posse com `chown -R <owner>:oinstall <GH>/OPatch`. Na DB home, faça tudo como owner.
  - Confira com `opatch version -oh <HOME>` em cada home.
- **Espaço para 4 homes** no filesystem das homes (as atuais, que são o rollback, mais os clones). Meça com `du -sh` e `df -h` (👤 root). Livre necessário ≥ (soma das homes atuais) + 5 GB por home + 10 GB de margem. Libere espaço com adrci/purgeLogs. Nunca apague o `.patch_storage` das homes atuais.
- **Stage limpo** (👤 root): um diretório contendo **só** os diretórios dos patches, com `chown` para o owner das homes.
  - Cada zip traz um `PatchSearch.xml` na raiz. Extraia com `unzip -q <zip> -x PatchSearch.xml -d <stage>`. Sem isso, a partir do segundo zip o `unzip` pergunta se deve sobrescrever o arquivo.
  - Num script enviado por stdin (`ssh <host> 'bash -s' <<EOF`), esse prompt consome o resto do script como resposta, e os comandos seguintes não rodam. Em execução remota, passe os comandos como argumento do `ssh`, com `< /dev/null`.
  - Ao final, confira se a quantidade de arquivos de cada patch no stage é igual à do zip (`unzip -Z1`).
  - Com o stage num filesystem compartilhado (ACFS) em RAC, um único stage e um único `clone.properties` servem a todos os nós.
- **clone.properties** (👤 root), com uma linha `home_atual=home_nova` por home, com os destinos no padrão de Oracle Home. Exemplo:
  ```
  /u01/app/19.0.0/grid=/u01/app/19.33.0.0/grid
  /u01/app/oracle/product/19.0.0/db_1=/u01/app/oracle/product/19.33.0.0/db_1
  ```
  Use sempre `-silent <arquivo>`: o prompt interativo distorce o caminho da GI. Os destinos não podem existir (OPATCHAUTO-72126). No `Summary` do analyze, confira se o `Clone Home Path` saiu exatamente no padrão.

## Fase 4 — Analyze (sem alterar nada)

👤 root: `$GH/OPatch/opatchauto apply -phBaseDir <stage> -analyze -outofplace -silent <clone.properties>`

Confira os caminhos dos clones e os patches aplicados em cada home. É normal: patches de DB também aplicados na GI, one-offs do OCW aplicados nas duas homes, e ACFS/Tomcat/DBWLM aparecendo como SKIPPED na DB. O analyze **pode não mostrar** a remoção de um one-off substituído. Valide no `lspatches` do clone.

O conflict check manual (👤 oracle) com `opatch prereq CheckConflictAgainstOHWithDetail` deve ser feito **por sub-patch**. No bundle inteiro, dá error 21.

**One-off de mesmo número, com build antigo instalado.** Sintoma: *"OPatch will not roll back [<RU antiga>] until you have rolled back dependent patch(es) [<one-off>]"*. O build antigo do one-off depende da RU antiga, e o opatchauto não resolve a dependência sozinho, mesmo quando o log diz que o patch é *auto rollbackable*. Esse caso é diferente do de um one-off substituído por outro de número diferente.

Caminho:
1. Ensaio na origem (👤 oracle, não altera nada): `opatch rollback -id <one-off> -oh <HOME> -report`. Confira no log se não pede shutdown nem relink e quais arquivos troca. Depois confira se o patch continua no `lspatches`.
2. Rollback garantido antes de alterar:
   - o zip do **build antigo** no servidor, conferido pelo `unique_patch_id` do `inventory.xml` e pelo md5 dos arquivos contra os da home;
   - um tar com timestamp de `inventory`, `.patch_storage` e dos arquivos afetados de cada home, mais o `oraInventory`.
3. `opatch rollback -id <one-off> -oh <HOME> -silent` em cada home de origem, seguido de `lspatches`, `diff` contra o backup e o analyze de novo.
4. Se o rollback só troca arquivo, sem binário nem relink, ele não para nada. Mas o bug volta até o switch: diga ao usuário o que evitar nesse intervalo.
5. **Em RAC, a GI home fica travada pelo root** (`lib`, `.patch_storage`). O ensaio na GI falha com *"Destination directory ... is not writable"* e *"No read or write permission to ORACLE_HOME/.patch_storage"*, mesmo que a DB home passe. Isso não acontece no Oracle Restart.
   - Para desfazer o one-off na GI é preciso destravar a home com 👤 root `$GH/crs/install/rootcrs.sh -prepatch`, que **para o stack do nó**. Depois vêm o rollback (👤 oracle) e o `rootcrs.sh -postpatch`, que trava a home e sobe o stack.
   - É uma parada rolling, nó a nó. Planeje como janela antes da Preparação e aproveite a janela para outras ações que dependam de restart do nó.

## Fase 5 — Prepare-clone (sem downtime, dentro do tmux)

👤 root: `$GH/OPatch/opatchauto apply -phBaseDir <stage> -prepare-clone -silent <clone.properties>`. Em RAC, faça em cada nó.

- Rode em horário de baixa carga: o processo consome bastante CPU e I/O e pode aumentar o lag de apply num standby.
- Em standby read-only, o `datapatch -prereq failed` é esperado.
- **Patch que substitui o `bin/oradism`** (ex.: 38723830, VKTM) falha em `CheckApplicable`. Siga o README: 👤 root `chown <owner>` + `chmod 0750` no `oradism` **só dos clones** e depois `opatchauto resume`. Ao final, confira se ele voltou para `root` com `4750`. Nunca mexa no `oradism` das homes em uso.
- **Antes de qualquer resume ou nova execução** (👤 root): `ps -ef | grep -E "opatchauto|OPatchAuto" | grep -v grep`, **numa chamada separada**. Se estiver na mesma linha de comando que dispara o opatchauto (ex.: `ssh <host> 'ps ... | grep opatchauto && exit; opatchauto ...'`), o grep encontra o próprio comando e acusa um processo que não existe. Rode execuções longas com `nohup` ou dentro do tmux, com a saída num log. Um `NullPointerException` com `OiitTargetLockNotAvailableException` indica outro opatchauto ainda rodando (por exemplo, numa sessão que caiu). Não mate o processo nem apague locks: acompanhe pelo log (`tail -f` no `opatchauto*.log` mais recente). Se a sessão realmente morreu sem terminar: OPATCHAUTO-72115.

Validação (👤 oracle): `lspatches` nos clones. Deve aparecer a RU nova e os one-offs escolhidos, e nenhum one-off da RU antiga. Registre o tamanho real dos clones (👤 root `du -sh`) para dimensionar os próximos hosts.

**Fim da Preparação:** resuma o estado do host (homes clonadas, patches, oradism, espaço) e o que fica pendente para a janela.

## Fase 6 — Janela de mudança (switch-clone)

### 6.1 Checklist da janela (monte e apresente ANTES do primeiro comando)

**Pré-switch:**
- [ ] Clones validados na Preparação (`lspatches`, `oradism` root/4750).
- [ ] Ordem confirmada: standbys antes do primário (Standby-First, MOS 1265700.1).
- [ ] Usuários de Active Data Guard avisados (o switch derruba todas as standbys do host).
- [ ] Data Guard saudável (👤 oracle `dgmgrl / "show configuration"`).
- [ ] Primário: GoldenGate Integrated Extract parado de forma controlada no nó onde ele roda. Os mounts ACFS do nó vão cair.
- [ ] Sessão no tmux.
- [ ] HugePages: `HugePages_Total` ≥ a soma das SGAs de todas as instâncias que vão religar (Fase 1, item 7), com a tabela de pagesize de cada instância anotada como baseline.

**Switch:**
- [ ] 👤 root `opatchauto apply -switch-clone` (RAC: nó a nó, validando entre os nós).
- [ ] Primário: `datapatch -verbose` uma única vez, no último nó, com todas as PDBs abertas, em horário de baixa carga.

**Pós-switch:**
- [ ] 👤 root: `olr.loc` apontando para a GI nova; `crsctl stat res -t` com tudo ONLINE.
- [ ] 👤 oracle: `srvctl config database` com a home nova; `dgmgrl show configuration` SUCCESS, sem lag crescente.
- [ ] 👤 oracle: no alert log de cada instância, a tabela `Supported system pagesize(s)` do novo startup com toda a SGA em 2048K (4K com só algumas páginas). Se houver SGA em 4K, investigue antes de encerrar a janela.
- [ ] Primário: `dba_registry_sqlpatch` com a RU nova em SUCCESS; GoldenGate religado e replicando.
- [ ] oratab, scripts de ambiente, ferramentas de monitoração e agendamentos que tenham o caminho da home fixo atualizados.

**Critério de rollback** (definir com o usuário antes de começar): recursos que não sobem, apply do standby que não volta, datapatch com erro não resolvido dentro da janela, ou GoldenGate que não retoma. Se acontecer, vá para a Fase 8.

### 6.2 Execução

Siga o checklist **item por item**, um comando por vez, marcando o que foi concluído. Peça confirmação explícita antes do `-switch-clone` em cada host ou nó.

👤 root: `$GH/OPatch/opatchauto apply -switch-clone`

Duração: estime pelos timestamps (primeira e última linha) do log do `opatchauto` de um switch anterior em host parecido.

Em Oracle Restart, não use `gridSetup.sh -switchGridHome` (não é suportado, MOS 2764906.1).

## Fase 7 — DST (janela separada, com downtime)

A RU traz os arquivos de DST, mas o banco não atualiza a versão sozinho, e o datapatch não faz isso.
- Versão atual (👤 oracle, SQL, em cada container): `SELECT property_name, property_value FROM database_properties WHERE property_name LIKE 'DST_%';` e `SELECT * FROM v$timezone_file;`
- Impacto: colunas `TIMESTAMP WITH TIME ZONE` fora dos schemas da Oracle (`dba_tab_cols` + `dba_users.oracle_maintained='N'`), com `num_rows`.
- O upgrade (`utltz_upg_check.sql` online, depois `utltz_upg_apply.sql` com restart) roda **só no primário**, no CDB$ROOT e em cada PDB, e chega ao standby pelo redo. Só faça **depois que todos os standbys estiverem na RU nova**.
- Pare o GoldenGate durante a janela. One-offs não rolling podem entrar aqui.

## Fase 8 — Rollback

- **Antes do switch:** 👤 oracle `runInstaller -silent -detachHome ORACLE_HOME=<clone>`, depois 👤 root `rm -rf <clone>`. Sempre o detach antes do rm.
- **Depois do switch, no standby:** 👤 root `opatchauto rollback -switch-clone`, sem datapatch.
- **Depois do switch, no primário:** 👤 root `opatchauto rollback -switch-clone`, depois 👤 oracle o `datapatch -verbose` **a partir da home antiga**, e confira o `dba_registry_sqlpatch` (ROLLBACK/SUCCESS).
- Data Guard: o standby pode ficar à frente do primário, **nunca atrás**. Com o primário já com datapatch, o standby só volta junto.
- Remova as homes antigas só depois de alguns dias estáveis, com detach antes.

## Referências

- KB188772 (ex-555.1), KB136647, KB107134, KB260868
- MOS 1265700.1 (Standby-First Patch Apply), MOS 2764906.1 (`-switchGridHome` em Oracle Restart)
- README da RU e de cada one-off