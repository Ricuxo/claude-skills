# Regras deste repositório

Repositório de skills do Claude. Fonte única: o claude.ai recebe os ZIPs de `dist/`,
o Claude Code lê `~/.claude/skills`, que aponta para `skills/` por symlink ou junction.

## Nomes de skill
Padrão: `<banco>-<domínio>-<objeto>[-<qualificador>]`. Ex.: `oracle-perf-os`, `mongo-adm-params`.
- **Idioma:** nome em inglês. `description` e corpo em português, com os termos técnicos do jeito
  que o usuário digita (`HugePages`, `iostat`, `log file sync`).
- **Banco:** `oracle`, `mongo`, `postgres`, `mysql`, `sqlserver`.
- **Domínios** (lista fechada):

  | Domínio | O que entra | Tipo |
  |---|---|---|
  | `perf` | diagnóstico de desempenho | somente leitura |
  | `sec` | auditoria de segurança | somente leitura |
  | `adm` | administração do dia a dia (parâmetros, usuários, healthcheck) | altera ou só lê, conforme a skill |
  | `install` | pré-requisito e instalação, uma skill por fase | prereq lê; instalação altera |
  | `patch` | patching e upgrade | altera |
  | `ha` | Data Guard, RAC, replica set | conforme a skill |
  | `bkp` | backup e recovery | conforme a skill |

- **Objetos** (vocabulário fechado; objeto novo entra nesta lista antes de ser usado): `os`, `db`,
  `instance`, `session`, `sql`, `objects`, `app`, `users`, `params`, `network`, `storage`,
  `prereq`, `oop`, `healthcheck`.
- **`sec` × `adm` no mesmo objeto:** `sec` audita, `adm` altera. Ex.: `oracle-sec-users` acha
  privilégio demais e senha padrão; `oracle-adm-users` cria usuários e concede privilégios.
- **`install` por fase:** `<banco>-install-prereq` verifica o SO, somente leitura.
  `<banco>-install-db`/`-gi` conduz a instalação: no primeiro passo confirma o pré-requisito (pelo
  relatório da prereq, chamando a skill ou, sem ela, com uma checagem mínima embutida, como o
  `-executePrereqs`/`cluvfy`); no último, verifica o resultado.
- **Desempenho Oracle em níveis:** `oracle-perf-os` (1), `-instance`, `-session`, `-sql`,
  `-objects`, `-app`.
- **Renomear uma skill** muda o diretório, o `name`, as referências nas outras skills, as `tags`
  dos evals e o `README.md`, e entra no `CHANGELOG.md`. No Claude Code, remova o link antigo com
  `cmd /c rmdir` (Windows; nunca `Remove-Item -Recurse` em junction) ou `rm` (symlink) e rode de
  novo o `link.ps1`/`link.sh`. No claude.ai, apague a skill antiga antes de enviar o ZIP novo,
  senão as duas disputam o mesmo pedido.

## Ao criar ou editar uma skill
- O diretório e o `name` do frontmatter são idênticos (minúsculas, hífen, até 64 caracteres).
- Frontmatter só com `name` e `description`. Nada mais, por portabilidade.
- `description` com no máximo 1024 caracteres. Rode `scripts/build.sh` para validar.
- `SKILL.md` abaixo de ~500 linhas. Passou disso, mova blocos para `references/`
  e deixe no corpo um ponteiro dizendo quando ler cada arquivo.
- Cada skill é autocontida: uma não lê o `references/` da outra. Duplicar consulta é aceitável.
- Skills de diagnóstico são somente leitura. Nenhuma instrução de ALTER, DDL ou mudança
  de sysctl dentro da coleta; mudança só como recomendação, marcada como tal.
- Skills que conduzem mudança (ex.: patching) executam leitura direto, mas cada alteração
  exige: mostrar comando, impacto e rollback; confirmação explícita; backup com timestamp
  (`<arquivo>.bak_YYYYMMDD_HHMMSS`) antes e `diff` depois.
- Escopo genérico: nunca incluir hostnames, domínios, IPs, nomes de banco, PDB, serviço ou
  conexão, usuários, senhas, e-mails, nomes de empresa ou cliente, CSI, nem ferramentas
  pessoais ou internas (Obsidian, Google Drive, pastas de blog, monitoração específica),
  nem em exemplos ou evals. Use placeholders; para IP e domínio de exemplo, `192.0.2.x`,
  `2001:db8::` e `example.com`.
- O pre-commit (`scripts/verifica-sensivel.sh`) barra commit com dado sensível. Não usar
  `--no-verify`; falso positivo comprovado vai em `.sensivel-permitido`.
- Relatórios e saídas de teste nunca ficam dentro do repositório.
- Toda mudança de comportamento entra no `CHANGELOG.md`.

## Testes
- `evals/<caso>/` em cada skill, no layout prompt.md + case.yaml + graders/.
- Ao mudar a `description`, revise os casos de disparo.
