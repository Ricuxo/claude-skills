# Changelog

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
