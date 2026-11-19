# claude-skills

Skills do [Claude](https://claude.ai) para DBAs Oracle. Cada skill conduz uma tarefa de
administração em Linux, passo a passo, sempre contra a documentação oficial da Oracle.

## Skills

| Skill | O que faz |
|---|---|
| [`oracle-install-prereq`](skills/oracle-install-prereq/SKILL.md) | Confere se um servidor Linux está pronto para instalar Oracle 19c, 21c ou 23ai/26ai (Single Instance, Oracle Restart ou RAC; filesystem ou ASM). Compara SO, kernel, pacotes, sysctl, limits, memória, swap, HugePages, THP e storage com o guia de instalação da versão, lido na hora |
| [`oracle-perf-os`](skills/oracle-perf-os/SKILL.md) | Analisa desempenho de banco Oracle na camada de SO e infraestrutura: CPU, memória, HugePages, I/O, rede e interconnect de RAC. Interpreta `vmstat`, `iostat`, `sar` e os eventos de espera ligados a I/O |
| [`oracle-patch-oop`](skills/oracle-patch-oop/SKILL.md) | Conduz o patching out-of-place de Oracle 19c (GI e DB) com `opatchauto -prepare-clone` / `-switch-clone`, em Oracle Restart, RAC e Data Guard: levantamento do host, seleção mínima de one-offs, pré-requisitos, analyze, preparação dos clones sem downtime, checklist da janela de troca, DST e rollback |

## Princípios

As skills seguem as mesmas regras:

- **Doc oficial como fonte.** Nenhum valor exigido sai de memória. Cada requisito vem da
  documentação da versão alvo, com o link da página. Se a página não abre, o item fica como
  **NÃO VERIFICADO**, e a skill não preenche o valor por conta própria.
- **Leitura por padrão, mudança só com confirmação.** A maioria das skills (diagnóstico e
  pré-requisitos) só coleta e compara. Elas não aplicam fixup, `sysctl -w`, pacote, usuário nem
  regra udev; a correção aparece como recomendação, com a fonte, para o DBA decidir. As skills
  que conduzem uma mudança, como o patching, fazem as verificações de leitura direto. Antes de
  qualquer alteração, elas mostram o comando, o impacto e como desfazer, fazem backup do que vão
  mudar e só seguem com a confirmação explícita de quem está conduzindo.
- **Escopo genérico.** Nenhuma skill traz hostname, IP, domínio, nome de banco ou de conexão,
  usuário, empresa ou ferramenta interna, nem em exemplos. Os exemplos usam placeholders
  (`<host>`, `<db_unique_name>`, `<HOME>`), para servir a qualquer ambiente.
- **Sem bypass.** Requisito não atendido se corrige no servidor. As skills nunca recomendam
  `-ignorePrereq` nem aceitar o item como exceção.
- **Sem senha na conversa.** O acesso ao servidor é por chave SSH que já existe
  (`ssh -o BatchMode=yes`), ou a skill entrega o script para alguém rodar e colar a saída.

## Instalação

### Claude Code (Linux, WSL, macOS)

```bash
git clone https://github.com/Ricuxo/claude-skills.git ~/claude-skills
cd ~/claude-skills
./scripts/link.sh
```

O script liga cada skill em `~/.claude/skills` por symlink e instala os hooks de commit
(ver [Contribuindo](#contribuindo)). Um `git pull` atualiza todas. Quando entrar uma skill
nova, rode o script de novo: ele pula as que já estão ligadas.

### Claude Code (Windows, usuário comum)

```powershell
git clone https://github.com/Ricuxo/claude-skills.git $env:USERPROFILE\claude-skills
cd $env:USERPROFILE\claude-skills
powershell -ExecutionPolicy Bypass -File .\scripts\link.ps1
```

O script usa junction, que não exige administrador. O clone precisa estar em disco local,
porque junction não aponta para unidade de rede.

### claude.ai

```bash
./scripts/build.sh
```

O script valida o frontmatter de cada skill e gera `dist/<skill>.zip`. Envie o ZIP na área de
Skills das configurações do claude.ai.

## Uso

As skills disparam pelo assunto da conversa ("o servidor está pronto para o Oracle?", "o
banco está lento e a CPU está alta"). Também dá para chamar pelo nome, no Claude Code:

```
/oracle-install-prereq <ip> 19c restart asm
```

Chamada sem argumentos, a `oracle-install-prereq` mostra as opções e pergunta o que faltar.

## Estrutura

```
skills/<nome>/
├── SKILL.md        # instruções (obrigatório)
├── references/     # consultas, scripts de coleta e modelos de relatório, lidos sob demanda
└── evals/          # casos de teste: prompt.md + case.yaml + graders/
scripts/            # build.sh (ZIPs), link.sh e link.ps1 (instalação), verifica-sensivel.sh e instala-hooks.sh
dist/               # ZIPs gerados (fora do git)
```

## Contribuindo

1. Edite em `skills/<nome>/` e siga as regras do [`CLAUDE.md`](CLAUDE.md): frontmatter só
   com `name` e `description`, `SKILL.md` abaixo de ~500 linhas, nenhum host, IP, usuário ou
   dado de cliente, nem em exemplos.
2. Rode `./scripts/build.sh` para validar.
3. Registre a mudança no [`CHANGELOG.md`](CHANGELOG.md).

### Proteção contra dado sensível

O repositório é público. Antes de cada commit, um hook roda `scripts/verifica-sensivel.sh`
no que está no stage e na mensagem, e bloqueia se achar IP, e-mail, domínio interno, chave
privada, token ou senha. Instale uma vez por clone (o `link.sh` já faz isso; no Windows,
rode no Git Bash):

```bash
bash scripts/instala-hooks.sh
```

Hostname curto e nome de cliente não têm padrão reconhecível. Liste os seus em
`~/.config/claude-skills/proibidos.txt`, um por linha. Esse arquivo fica fora do repositório
e nunca é versionado.

Para exemplos, use as faixas de documentação (`192.0.2.x`, `198.51.100.x`, `203.0.113.x`,
`2001:db8::`) e `example.com`, que o detector aceita. Falso positivo comprovado vai em
`.sensivel-permitido`. Para conferir o repositório inteiro ou todo o histórico:

```bash
bash scripts/verifica-sensivel.sh --tudo
bash scripts/verifica-sensivel.sh --historico
```

## Licença

MIT. Veja [`LICENSE`](LICENSE).
