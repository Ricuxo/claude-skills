# Changelog

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
