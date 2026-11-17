# claude-skills

Skills do Claude para administração de bancos de dados. Uma fonte, dois destinos:

| Destino | Como recebe |
|---|---|
| Claude Code (Linux/WSL) | symlink em `~/.claude/skills` → `scripts/link.sh` |
| Claude Code (Windows sem admin) | junction em `%USERPROFILE%\.claude\skills` → `scripts/link.ps1` |
| claude.ai | ZIP gerado por `scripts/build.sh`, enviado em Configurações |

## Estrutura

```
skills/<nome>/
├── SKILL.md        # obrigatório
├── references/     # carregado sob demanda
└── evals/          # casos de teste
scripts/            # build e links
dist/               # ZIPs gerados (fora do git)
```

## Instalação numa máquina nova

```bash
git clone <remoto> ~/desenvolvimento/claude-skills
cd ~/desenvolvimento/claude-skills
./scripts/link.sh
```

Windows (usuário comum):

```powershell
git clone <remoto> $env:USERPROFILE\desenvolvimento\claude-skills
cd $env:USERPROFILE\desenvolvimento\claude-skills
powershell -ExecutionPolicy Bypass -File .\scripts\link.ps1
```

O repositório precisa estar em disco local (junction não aponta para rede).
Skill nova: rode o script de link de novo — ele pula as já ligadas.

## Fluxo de atualização

1. Editar em `skills/<nome>/`.
2. `./scripts/build.sh` — valida frontmatter e gera `dist/<nome>.zip`.
3. Registrar no `CHANGELOG.md`, commit, `git tag vX.Y.Z`, push.
4. Outras máquinas: `git pull` (os links já apontam para o repo).
5. claude.ai: reenviar o ZIP só quando houver tag nova.

## Skills

| Skill | Escopo |
|---|---|
| `oracle-desempenho-so` | Nível 1 — SO e infraestrutura (CPU, memória, I/O, rede, ASM, interconnect) |
