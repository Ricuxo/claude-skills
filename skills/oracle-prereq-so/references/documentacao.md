# Documentação oficial por versão

Mapa conferido em 2026-11-12. **Antes de usar, confirme que a URL abre e mostra a versão
certa no título.** A Oracle reorganiza a documentação; se uma página mudar de lugar,
procure pelo título da página em `docs.oracle.com` restrito à versão e registre a URL nova
no relatório.

## Guias por versão

| Versão alvo | Database Installation Guide for Linux | Grid Infrastructure (Restart/RAC) |
|---|---|---|
| 19c | `https://docs.oracle.com/en/database/oracle/oracle-database/19/ladbi/` | `https://docs.oracle.com/en/database/oracle/oracle-database/19/cwlin/` |
| 21c | `https://docs.oracle.com/en/database/oracle/oracle-database/21/ladbi/` | `https://docs.oracle.com/en/database/oracle/oracle-database/21/cwlin/` |
| 23ai / 26ai | `https://docs.oracle.com/en/database/oracle/oracle-database/26/ladbi/` | `https://docs.oracle.com/en/database/oracle/oracle-database/26/cwlin/` |

**23ai e 26ai:** a Oracle renomeou a linha 23ai para "Oracle AI Database 26ai"; os Release
Updates seguem a numeração 23.x (ex.: 23.26.x). A documentação atual dessa linha fica em
`/26/`. O caminho `/23/ladbi/` ainda tem páginas antigas e não deve ser usado como fonte
principal. Se o usuário disser "23ai", use `/26/` e mencione isso no relatório.

Cada guia também existe em PDF no mesmo diretório (o nome do arquivo muda por revisão).
Registre a revisão (ex.: `E96432-53`) quando ler pelo PDF.

## Como localizar as páginas

As páginas ficam em **subpastas por capítulo** e o caminho muda entre revisões. Em
2026-11-12 os caminhos planos (`.../19/ladbi/<pagina>.html`) devolveram **HTTP 404** no 19c.
Não monte URL de memória. Ordem para localizar:

1. `<guia>/llm.txt` — índice legível por máquina com todas as páginas e caminhos
   (existe no 19c; conferir nas outras versões). Use o texto literal das URLs, não o resumo.
2. `<guia>/index.html` — sumário do guia.
3. Busca em `docs.oracle.com` pelo título da página, restrita à versão.

Registre no relatório a URL efetiva lida e o status HTTP.

## Páginas a abrir (títulos)

| Assunto | Título da página |
|---|---|
| Parâmetros de kernel (tabela mínima) | Minimum Parameter Settings for Installation (dentro de "Configuring Kernel Parameters for Linux") |
| Limits do usuário | Checking Resource Limits for Oracle Software Installation Users |
| RAM mínima | Server Hardware Checklist for Oracle Database Installation |
| Swap por faixa de RAM, `/tmp` | Server Configuration Checklist for Oracle Database Installation |
| Espaço em disco | Storage Checklist for Oracle Database Installation |
| Distros, kernels e pacotes | Supported Oracle Linux <N> Distributions for x86-64 (ou RHEL/SUSE) |
| THP | Setting and Disabling Transparent HugePages on UEK Kernels |
| HugePages | Configuring HugePages on Linux · Restrictions for HugePages and Transparent HugePages Configurations |
| RPM preinstall | Overview of Oracle Linux Configuration with Oracle RPMs |

### Caminhos conferidos (19c, 2026-11-12, HTTP 200)

Prefixo: `https://docs.oracle.com/en/database/oracle/oracle-database/19/ladbi/`

- `completing-preinstallation-tasks-manually/configuring-kernel-parameters-for-linux.html`
- `configuring-users-groups-and-environments-for-oracle-grid-infrastructure-and-oracle-database/checking-resource-limits-for-oracle-software-installation-users.html`
- `oracle-database-installation-checklist/server-hardware-checklist-for-oracle-database-installation.html`
- `oracle-database-installation-checklist/server-configuration-checklist-for-oracle-database-installation.html`
- `oracle-database-installation-checklist/storage-checklist-for-oracle-database-installation.html`
- `operating-system-requirements-for-x86-64-linux-platforms/supported-oracle-linux-8-distributions-for-x86-64.html`
- `configuring-operating-systems-for-oracle-database-on-linux/setting-and-disabling-transparent-hugepages-on-uek-kernels.html`
- `configuring-operating-systems-for-oracle-database-on-linux/configuring-hugepages-on-linux.html`
- `configuring-operating-systems-for-oracle-database-on-linux/restrictions-for-hugepages-and-transparent-hugepages-configurations.html`

### Caminhos conferidos (26ai, 2026-11-12, HTTP 200)

Prefixo DB: `https://docs.oracle.com/en/database/oracle/oracle-database/26/ladbi/`

- `operating-system-requirements-for-x86-64-linux-platforms/supported-oracle-linux-9-distributions-for-x86-64.html`
- `completing-preinstallation-tasks-manually/configuring-kernel-parameters-for-linux.html`
- `oracle-ai-database-installation-checklist/server-hardware-checklist-for-oracle-ai-database-installation.html`
- `oracle-ai-database-installation-checklist/server-configuration-checklist-for-oracle-ai-database-installation.html`
- `configuring-operating-systems-for-oracle-ai-database-on-linux/restrictions-for-hugepages-and-transparent-hugepages-configurations.html`
- `configuring-storage-for-oracle-grid-infrastructure-for-a-standalone-server/configuring-storage-for-oracle-automatic-storage-management.html`
- `configuring-users-groups-and-environments-for-oracle-grid-infrastructure-and-oracle-ai-database/required-operating-system-groups-and-users.html`

Prefixo Grid: `https://docs.oracle.com/en/database/oracle/oracle-database/26/cwlin/`

- `configuring-users-groups-and-environments-for-oracle-grid-infrastructure-and-oracle-ai-database/checking-resource-limits-for-oracle-software-installation-users.html`
- `oracle-grid-infrastructure-installation-checklist/server-configuration-checklist-for-oracle-grid-infrastructure.html`
- `configuring-operating-systems-for-oracle-grid-infrastructure-on-linux/setting-network-time-protocol-for-cluster-time-synchronization.html`

### Caminhos e lacunas (21c, 2026-11-12)

- `.../21/ladbi/llm.txt` e `.../21/cwlin/llm.txt`: **404**. `index.html` só tem a capa.
- No 21c os caminhos **planos** funcionam (HTTP 200), ao contrário do 19c:
  `server-hardware-checklist-for-oracle-database-installation.html`,
  `server-configuration-checklist-for-oracle-database-installation.html`,
  `storage-checklist-for-oracle-database-installation.html`,
  `operating-system-checklist-for-oracle-database-installation-on-linux.html`,
  `operating-system-requirements-for-x86-64-linux-platforms.html`.
- **SO suportado (revisão F31591-14, mar/2026):** a página de requisitos de SO do 21c lista
  apenas Oracle Linux 8, Oracle Linux 7, RHEL 8 e SUSE 15. **Oracle Linux 9 não aparece.**
  Servidor OL9 para 21c → `INFRA` (SO fora da certificação documentada); recomendar
  conferir a matriz de certificação do My Oracle Support.

### Lacunas conhecidas (19c)

- O guia de Grid 19c (`.../19/cwlin/llm.txt`) devolveu **404** em 2026-11-12. Localize as
  páginas de Grid pelo `index.html` do `cwlin` ou por busca restrita ao domínio; até lá,
  itens só do guia de Grid ficam NÃO VERIFICADO. Swap do Restart, `/tmp`, `/dev/shm` e RAM
  do Grid também estão no guia DB (`ladbi`) e podem ser citados de lá.
- Páginas de Grid/ASM 19c encontradas por busca (o `cwlin/index.html` só tem a capa):
  `.../19/ladbi/installing-oracle-grid-infrastructure-for-a-standalone-server-with-a-new-database-installation.html`,
  `.../19/ladbi/changes-in-this-release-for-oracle-database/deprecated-features.html` (ASMFD; Doc ID 2806979.1),
  `.../19/ladbi/configuring-storage-for-oracle-grid-infrastructure-for-a-standalone-server/migrating-from-oracle-asm-filter-driver-to-oracle-asmlib-for-oracle-restart.html`,
  `.../19/cwlin/identifying-storage-requirements-for-oracle-automatic-storage-management.html`.
  A tabela de espaço mínimo de ASM para servidor standalone 19c não foi localizada.
- **19c em OL9:** a página de OL9 do 19c exige DB **19.19+** (UEK7/RHCK) e **19.32+** para
  OL 9.6 com UEK 8 (kernel 6.12). Não cita RU mínimo do Grid nem OL 9.8.

Na 26ai os capítulos têm "oracle-ai-database" no nome (diferente do 19c). Para 21c,
localizar pelo `llm.txt`/índice. O `llm.txt` vem truncado (~40 mil caracteres): use as URLs
literais que aparecem e confirme cada página abrindo-a.

### Conflitos conhecidos (26ai)

- **Swap do Oracle Restart:** a tabela do guia DB começa em 8 GB de RAM; a do guia Grid
  começa em 4 GB ("Between 4 GB and 16 GB: Equal to RAM"). Reportar as duas.
- **Espaço de software:** textos de índice divergem (DB: 4,2 GB Grid / 8,3 GB DB; Grid:
  12 GB Grid home / 10 GB DB EE). Abrir as páginas de storage checklist antes de concluir.
- **THP:** as páginas de restrições (DB e Grid) mandam `madvise` em UEK7+ e "não
  desabilitar"; um texto de checklist do Grid ainda fala em desabilitar e parece antigo.

### Conflitos conhecidos na própria documentação

- **THP (19c):** a página de UEK recomenda `madvise` em UEK7+ e diz que o RPM preinstall
  aplica `madvise`; a página de restrições recomenda desabilitar e diz que o RPM desabilita.
  Reportar o conflito com as duas URLs e usar a regra **específica do kernel** (UEK) como
  principal, deixando a decisão ao DBA.

Para Restart e RAC, abra no guia de Grid da versão: checklist de servidor, requisitos de
rede (RAC), configuração de storage ASM e requisitos de horário/NTP.

## Nome do RPM preinstall

Vem da documentação da versão. Já visto nas fontes oficiais:

| Versão | Pacote |
|---|---|
| 19c | `oracle-database-preinstall-19c` (citado em `changing-kernel-parameter-values.html` 19c) |
| 23ai | `oracle-database-preinstall-23ai` (tutorial oficial Oracle Database Free) |
| 26ai | `oracle-ai-database-preinstall-26ai` (guia 26ai) |

Para 21c, confirmar na página do RPM preinstall do guia 21c antes de checar.

## Cópia local

Para quando a máquina onde o Claude roda não alcança `docs.oracle.com` (proxy, firewall)
ou a ferramenta de leitura de páginas não está disponível.

**Onde fica.** O diretório que o usuário indicar, ou o padrão `~/oracle-docs/<versão>/`
(`19c`, `21c`, `26ai`; para "23ai", use `26ai`). Nunca dentro de um repositório git: a
documentação da Oracle tem copyright e não pode ir para repositório público. Se o caminho
indicado estiver num repositório (`git -C <dir> rev-parse --is-inside-work-tree`), avise e
sugira mover.

**Formatos aceitos.**
- **HTML** salvo pelo navegador ("Salvar como"), uma página por arquivo. É o mais leve.
- **PDF** do guia inteiro (centenas de páginas). Não leia o arquivo todo: localize a seção
  pelo índice do PDF ou por busca de texto (`pdftotext -layout <arq> - | grep -n
  '<título>'`, se o `pdftotext` existir) e leia só as páginas da seção.
- Texto colado ou anexado pelo usuário vale igual, com a mesma conferência de versão.

**Reconhecer cada arquivo.** Liste o diretório e, para cada arquivo, leia o começo:
- confira título e versão **no conteúdo**, não no nome do arquivo;
- arquivo de outra versão (ex.: guia 21c no diretório da 19c) **não é usado**: diga qual
  arquivo e qual versão ele mostra;
- ligue cada arquivo a um título da tabela "Páginas a abrir" e diga quais títulos ainda
  faltam. Item sem arquivo continua NÃO VERIFICADO.

**Idade da cópia.** Registre a revisão do guia (ex.: `E96432-53`, na capa do PDF ou no
rodapé da página) e a data do arquivo (`stat -c %y`). Com mais de 6 meses, avise no
relatório que pode existir revisão mais nova e, se a web estiver acessível, confira a
revisão atual antes de concluir.

**Baixar com `curl`** (só com aprovação do usuário). Quando a falha for só da ferramenta de
leitura e a rede da máquina alcançar o site, ofereça baixar as URLs exatas da tabela de
falhas:

```bash
mkdir -p ~/oracle-docs/<versão>
curl -fsSL --max-time 30 -o ~/oracle-docs/<versão>/<nome>.html '<URL da tabela>'
```

Um arquivo por URL da tabela, sem seguir links nem varrer o site. Se o `curl` também
falhar, a rede é que bloqueia: siga para "o usuário salva as páginas" ou NÃO VERIFICADO.

**No relatório**, a fonte de cada item lido localmente fica assim:
`<título da página> — cópia local: <arquivo>, revisão <rev>, arquivo de <data>`.

## Ferramentas oficiais de verificação

`runInstaller -executePrereqs` (Database) e `cluvfy` (Grid/RAC). Sintaxe e opções: guia da
versão e guia de Grid da versão. Somente o modo de verificação; fixup altera o sistema.

## Notas MOS

Notas do My Oracle Support exigem login; a skill não as baixa. Quando uma recomendação vier
de nota MOS, cite o Doc ID e diga que o usuário precisa conferir no MOS.
