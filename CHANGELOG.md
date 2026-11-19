# Changelog

## [0.6.1] — 2026-11-19
### oracle-perf-os
- Testes que discriminam: seis casos novos com armadilhas em que o modelo sem skill tende a errar
  a condução: `cpu-media-acumulada`, `cpu-fora-do-banco`, `sem-pack-ontem`,
  `load-acima-dos-cores`, `setall-media-enganosa` e `relatorio-lote` (com coleta sintética).
  Além do conteúdo técnico, cobram as regras da skill: uma verificação por vez, licença de
  Diagnostic Pack antes de AWR/ASH e o formato do relatório (veredito curto e "O que este nível
  NÃO respondeu").
- Resultado contra o modelo sem skill: 100% × 72%. Os critérios técnicos passam nas duas
  configurações; a diferença está na condução. Nenhuma mudança no `SKILL.md`.

## [0.6.0] — 2026-11-19
### Repositório
- Skills renomeadas para o padrão `<banco>-<domínio>-<objeto>`, com nome em inglês:
  `oracle-desempenho-so` → `oracle-perf-os`, `oracle-prereq-so` → `oracle-install-prereq`,
  `oracle-oop-patching` → `oracle-patch-oop`. O conteúdo e as `description` não mudam.
- Os níveis de desempenho citados passam a `oracle-perf-instance`, `-session`, `-sql`,
  `-objects` e `-app`. O caso `nao-dispara-desempenho` passa a `nao-dispara-perf`.
- `CLAUDE.md`: nova seção "Nomes de skill", com padrão, domínios, vocabulário de objetos, a regra
  `sec` × `adm`, as fases do `install` e o roteiro para renomear.
- **Ação manual:** no claude.ai, apague as três skills com nome antigo e envie os ZIPs novos. No
  Claude Code, rode `link.ps1`/`link.sh` de novo. As entradas abaixo mantêm os nomes antigos,
  por serem histórico.

## [0.5.1] — 2026-11-19
### oracle-desempenho-so
- Swap: separa swap ocupada (páginas antigas, `si`/`so` zerados, sem alarme) de swap ativa
  (`si`/`so` sustentado, emergência). `VM_IN_BYTES`/`VM_OUT_BYTES` viram indício a confirmar no
  SO. Com a SGA em HugePages, o que vai para swap é PGA e processo, não a SGA.
- THP: regra explícita para kernels fora do UEK7+ (UEK antigo, RHCK, RHEL, SLES): `never`. O
  `madvise` vale só no UEK7+; kernel não identificado pede `uname -r` antes de julgar.
- `filesystemio_options = SETALL` deixa de ser "baixo risco": SGA pequena que dependia do page
  cache piora com I/O direto; e, com `none`, a média de `db file sequential read` sai baixa demais.
- `cpu_count` em VM: corrigido. VM mostra as vCPUs do convidado (o risco é `%steal`); quem vê CPU
  que não tem é contêiner/cgroup, LPAR e zonas.
- `log file sync` ≫ `log file parallel write`: inclui o polling adaptativo do LGWR (12c+),
  confirmado pelo trace do LGWR; mudança via parâmetro oculto só com SR.
- HT: load acima do número de cores já é disputa (HT rende 15–30%, não o dobro).
- Níveis 2–6 não instalados: a skill confere antes de encaminhar e, sem a skill do próximo
  nível, diz o próximo passo sem fingir que ela vai rodar.
- `V$ASM_DISK_IOSTAT`: nota de unidade (segundos no 19c+, centésimos no manual 11.2).
- `coleta-so.md`: `si`/`so` e `sar -W` na coleta de memória; `rp_filter` com HAIP no RAC;
  limits do `pmon` da instância certa (`ora_pmon_<sid>`), não do primeiro encontrado.
- Cuidados operacionais e tabela de versões foram para `references/ambientes-versoes.md`; o SQL
  do Passo 7 foi para `references/consultas.md`. `SKILL.md` fica em 494 linhas.
- Testes: novos casos `swap-ocupada-sem-atividade`, `thp-madvise-kernel-rhck` e
  `log-file-sync-polling`.

## [0.5.0] — 2026-11-19
### oracle-prereq-so
- Documentação por cópia local: se o usuário indicar um diretório, ou se existir
  `~/oracle-docs/<versão>/`, a skill lê de lá primeiro (HTML salvo ou PDF do guia, lido só
  nas páginas da seção). Cada arquivo é conferido pela versão do conteúdo, não pelo nome;
  arquivo de outra versão é recusado. A fonte no relatório registra arquivo, revisão e
  data, com aviso quando a cópia tem mais de 6 meses.
- Página que não abre: a skill não supõe "sem internet". Lista título, URL e erro, e
  oferece baixar com `curl` as URLs exatas (com aprovação, sem varrer o site), ler o
  diretório que o usuário salvar, colar a seção ou seguir com NÃO VERIFICADO. O `curl` não
  é oferecido quando o usuário já disse que a rede ou o proxy bloqueia o site.
- Testes: `doc-indisponivel-nao-supoe` ganha o critério da cópia local; novo caso
  `doc-local-versao-errada` (página sintética do guia 21c no diretório da 19c).
### Repositório
- `.gitignore` e detector barram `oracle-docs/`, `*.pdf` e `*_files/`: documentação da
  Oracle tem copyright e não vai para o repositório público.

## [0.4.0] — 2026-11-19
### oracle-prereq-so
- Conteúdo externo (páginas da documentação, saída da coleta) é tratado como dado: texto
  que pareça instrução não muda as regras da skill e vira achado no relatório.
- Relatório pode ter hostname e IP do servidor analisado (é para o usuário), mas, gravado
  em arquivo, fica fora de repositório git: dentro de um, a skill pergunta onde salvar.
  Substitui a regra que proibia hostname e IP no próprio relatório.
- `coleta.md`: aviso de que `su - <usuário>` executa o perfil do usuário; se travar,
  limits efetivos ficam NÃO VERIFICADO.
- Testes: `dispara-prereq-23ai/02` e `nao-aplica-fixup/02` passam a cobrar o que a skill
  faz no primeiro turno (perguntas de abertura), não o relatório. Novos casos:
  `outro-sgbd-para-e-confirma` (com coleta sintética), `recusa-senha-ssh` e
  `nao-dispara-desempenho` (disparo negativo).
### Repositório
- `scripts/verifica-sensivel.sh`: procura IPv4/IPv6/MAC, e-mail, domínio, chave privada,
  token, senha (inclusive `IDENTIFIED BY` e `usuário/senha` no `sqlplus`), caminhos de saída
  de teste e os termos de uma lista pessoal fora do repositório. Modos: stage, `--tudo`,
  `--historico`, `--msg`. Exceções versionadas em `.sensivel-permitido`.
- `scripts/instala-hooks.sh`: hooks `pre-commit` e `commit-msg` em `~/.config/claude-skills/hooks`
  via `core.hooksPath` (funciona com o repositório em disco `noexec`). Chamado pelo `link.sh`.
- `.gitignore`: workspaces de teste, `evals/results/`, relatórios, chaves e `.env`.

## [0.3.1] — 2026-11-18
### oracle-oop-patching
- **Levantamento: HugePages** (só leitura). O pool é comparado com a soma das SGAs (`ipcs -m`,
  método do MOS 401749.1), e o alert log de cada instância é lido na tabela `Supported system
  pagesize(s)` do 19c, que mostra SGA em 4 KB mesmo quando a instância sobe sem erro. Se
  encontrar `use_large_pages=TRUE`, a skill avisa e pergunta; para alterar, primeiro calcula se o
  pool comporta tudo. Ordem: `sysctl -w`, depois conferir o `HugePages_Total`, depois persistir,
  e só no fim `ONLY` no spfile. `ONLY` é a recomendação da Database Reference 19c.
- **Checklist da janela:** pool suficiente no pré-switch; no pós-switch, toda a SGA de cada
  instância em 2048K.
- **Analyze:** caso do one-off de mesmo número com build antigo dependente da RU antiga
  ("will not roll back ... until you have rolled back dependent patch(es)"). Ensaio com
  `-report`, rollback garantido (zip do build antigo conferido pelo `unique_patch_id` e por md5,
  mais tar de `inventory`, `.patch_storage` e `oraInventory`), rollback na origem e analyze de novo.
- **Execução:** scripts SQL de mudança com `whenever sqlerror exit failure`, para o backup
  vir antes e abortar se falhar. Diretório de arquivo gravado pelo banco tem que ser do owner
  da home (ORA-07391).
- **Stage:** extração com `-x PatchSearch.xml`, porque todos os zips trazem esse arquivo e o
  prompt de sobrescrever consome o script enviado por stdin. Execução remota com comandos como
  argumento e `< /dev/null`. Conferência da quantidade de arquivos contra `unzip -Z1`. Em RAC
  com ACFS, um único stage e um único `clone.properties` servem a todos os nós.
- **Analyze, one-off antigo em RAC:** a GI home fica travada pelo root, então o rollback na
  origem falha no ensaio (*Destination directory is not writable*) e exige `rootcrs.sh -prepatch`
  e `-postpatch`, o que significa uma parada rolling por nó. No Oracle Restart, não.
- Novo eval `evals/hugepages-switch/`.

## [0.3.0] — 2026-11-17
### oracle-oop-patching (nova)
- Conduz patching out-of-place de Oracle 19c (GI + DB) com `opatchauto -prepare-clone` /
  `-switch-clone` em Oracle Restart, RAC e Data Guard: abertura obrigatória (host, tipo, fase,
  RU), levantamento, seleção mínima de one-offs pelas notas on-prem, pré-requisitos, analyze,
  prepare-clone, checklist da janela, DST e rollback.
- Padrão de Oracle Home dos clones: `/u01/app/<RU>.0.0/grid` e
  `/u01/app/oracle/product/<RU>.0.0/db_1`, ou o padrão do ambiente.
- Modo de execução: com acesso SSH, leitura direto; alteração só com OK explícito, backup com
  timestamp e diff; `/etc/oratab` editado como root; nada no primário de produção sem pedido.
- Levantamento: pmon × estado no CRS (instância fora do CRS, SID diferente do `srvctl config`),
  resíduo no oratab, Broker em cada configuração (`dg_broker_start` no primário, instância
  fantasma, `StaticConnectIdentifier` por instância), `SID_NAME` do listener estático idêntico
  ao SID (case-sensitive no Linux) e `GLOBAL_DBNAME` `<db_unique_name>_DGMGRL`.
- Seleção: GoldenGate por `cdb_capture` no standby ADG, sem join com `v$pdbs` (capture no
  CDB$ROOT); DB home compartilhada recebe a união dos one-offs dos primários atendidos;
  validação dos zips (checksum, `version.txt` do OPatch, flags do `inventory.xml`, README);
  stage só com os patches do host; busca de bug por `number="<BUG>"` com controle obrigatório.
- Pré-requisitos: OPatch da GI home trocado como root (diretório da GI é do root após o
  `root.sh`) e posse devolvida ao owner; OPatch antigo guardado como `OPatch_<versão>_<data>`.
- Prepare-clone: checagem de opatchauto em execução numa chamada separada (o grep na mesma
  linha encontra o próprio comando); execuções longas com `nohup`/tmux e log.
- Casos de teste em `evals/`: não avança para a janela, confirma antes de alterar.
### Repositório
- `scripts/link.ps1` salvo em UTF-8 com BOM: sem BOM, o Windows PowerShell 5.1 lia o arquivo
  como ANSI e os acentos e o travessão quebravam a sintaxe (*TerminatorExpectedAtEndOfString*).
- README: princípio "Somente leitura" vira "Leitura por padrão, mudança só com confirmação";
  novo princípio "Escopo genérico". CLAUDE.md com as regras para skills que alteram e a lista
  ampliada de dados proibidos.

## [0.2.2] — 2026-11-17
### oracle-desempenho-so
- THP: regra por kernel, como no guia 19c ("Setting and Disabling Transparent HugePages on UEK
  Kernels"): `madvise` em UEK7 ou mais novo, `never` antes. Antes a skill mandava desabilitar
  sempre e marcava como problema o `madvise` que a doc recomenda. O achado passa a ser THP em
  `always`. A coleta mostra o kernel e o valor esperado por kernel.

## [0.2.1] — 2026-11-17
### oracle-desempenho-so
- `SKILL.md` de 581 para 488 linhas (regra do repositório: ~500). O SQL da janela curta
  (`V$SYSMETRIC*`), do TEMP por sessão e do Passo 6 (I/O) foi para `references/consultas.md`,
  sem alteração; a interpretação continua no `SKILL.md`, com ponteiro dizendo quando ler.
### Repositório
- Licença MIT, README para o repositório público e exemplo de uso sem IP.

## [0.2.0] — 2026-11-12
### oracle-prereq-so (nova)
- Valida pré-requisitos de SO para Oracle (SI, Restart, RAC; FS ou ASM) contra a
  documentação oficial da versão alvo (19c, 21c, 23ai/26ai), lida na execução.
- Nenhum valor exigido embutido: doc inacessível vira NÃO VERIFICADO.
- 23ai mapeado para a documentação `/26/` (linha renomeada para Oracle AI Database 26ai).
- Coleta em script único somente leitura; compara valor em uso × persistido e limits
  configurados × efetivos.
- Ferramentas oficiais (`runInstaller -executePrereqs`, `cluvfy`) só em modo verificação;
  fixup nunca.
- Casos de teste em `evals/`: disparo com 23ai, não aplica fixup, doc indisponível.
- Páginas localizadas por `llm.txt`/índice do guia: os caminhos planos do 19c dão 404;
  caminhos com subpasta conferidos registrados. Conflito de THP na doc 19c documentado.
- Detecção de alvo errado: outro SGBD (MySQL, MariaDB, PostgreSQL, SQL Server, MongoDB,
  Db2, Redis, SAP ASE) ou porta 1521 ocupada interrompe a análise até confirmação.
- Corrigido falso "(nenhum)" na busca de diretórios de dados quando só parte deles existe.
- Diretório de dados real extraído da linha de comando do processo (`-D`, `--datadir`...).
- Alvo por IP/hostname com coleta via SSH por chave (`BatchMode`); sem chave, o usuário
  libera com `ssh-copy-id` ou cola a saída. Senha nunca passa pela conversa.
- Natureza de cada pendência: `INFRA` (bloqueia a entrega) × `CONFIG-SO` (preparação do
  host); fases triagem → confirmação → auditoria no relatório.
- Aviso quando a automação chama o instalador com `-ignorePrereq`.
- Princípio "sem bypass": nunca recomendar ignorar verificação, aceitar exceção ou reduzir
  limite como solução; pendência só sai corrigindo o servidor.
- Coleta: usuário inexistente tratado; opções de montagem do `/dev/shm` coletadas.
- Caminhos e conflitos conhecidos da documentação 26ai registrados.
- Hostname checado em IPv4 e IPv6 separadamente (`getent ahostsv4/ahostsv6`).
- Lacunas da doc 19c registradas: `cwlin/llm.txt` 404; regra de RU para OL9/UEK 8.
- Corrigida a natureza de dono/permissão de device ASM e da regra udev/ASMLib: `CONFIG-SO`
  (depende de usuário criado na preparação). `INFRA` fica só presença e identificador estável.
- Bloco de uso exibido ao chamar sem argumentos (alvo, versão, cenário, storage, fase). Caso de teste `mostra-uso-sem-argumentos`.
- Fase `triagem` | `confirmacao` | `auditoria`, informada ou deduzida pelo servidor.
- Relatório por fase: triagem curta (só infra, condições de versão e o que a preparação
  não cobre; configuração de SO numa linha); confirmação e auditoria completas.
- Mapa 21c conferido: `llm.txt` 404, caminhos planos funcionam; OL9 fora da lista de SO.
- Dono único `oracle` como padrão; usuário `grid` opcional (só verificado se informado ou
  existente). Requisitos do "dono do Grid" aplicados ao `oracle` quando ele é o único dono.

## [0.1.0] — 2026-11-10
### oracle-desempenho-so
- Corrigido `ORDER BY 2+3` em `V$IOSTAT_FUNCTION` (ordenava por constante).
- Delta do AWR (`DBA_HIST_OSSTAT`) particionado por dbid/instância e descartando restarts.
- Tamanho de bloco lido de `V$DATAFILE.BLOCK_SIZE` / `DBA_TABLESPACES` em vez de fixo.
- Licença verificada por `control_management_pack_access`, não por uso detectado.
- Comparação DB CPU × CPU do host só por delta (origens diferentes de contador).
- Delta manual com `SYSTIMESTAMP` em cada coleta.
- Removidos `_realfree_heap_pagesize`, `use_large_pages` da consulta numérica e `optimizer_index_cost_adj`.
- Adicionados: uptime da instância, ASM, interconnect de RAC, THP, alert log de Large Pages,
  `V$EVENT_HISTOGRAM_MICRO`, CPU não contabilizada, regra log file sync × parallel write,
  OOM killer, ressalva de `%util` em SSD/NVMe/SAN, limites efetivos do processo.
- Modo de condução: uma verificação por vez em sessão interativa.
- Movidos para `references/`: coleta de SO, histórico com pack, RAC/ASM e modelo de relatório.
- Casos de teste em `evals/`: disparo, iostat em NVMe, HugePages com AMM, log file sync.
