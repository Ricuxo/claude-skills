# Regras deste repositório

Repositório de skills do Claude. Fonte única: o claude.ai recebe os ZIPs de `dist/`,
o Claude Code lê `~/.claude/skills`, que aponta para `skills/` por symlink ou junction.

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
