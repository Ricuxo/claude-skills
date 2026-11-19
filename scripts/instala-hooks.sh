#!/usr/bin/env bash
# Instala os hooks pre-commit e commit-msg que rodam scripts/verifica-sensivel.sh.
#
# Os hooks ficam fora do repositório, em ~/.config/claude-skills/hooks, e o clone aponta
# para eles com core.hooksPath. Assim funcionam mesmo com o repositório num disco montado
# com noexec, e no Git for Windows (Git Bash). Rode uma vez por clone.
# Uso: bash scripts/instala-hooks.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/claude-skills"
HOOKS="$CONF/hooks"
mkdir -p "$HOOKS"

cat > "$HOOKS/pre-commit" <<'EOF'
#!/usr/bin/env bash
# Instalado por scripts/instala-hooks.sh do repositório claude-skills.
s="$(git rev-parse --show-toplevel)/scripts/verifica-sensivel.sh"
[ -f "$s" ] || exit 0
exec bash "$s"
EOF

cat > "$HOOKS/commit-msg" <<'EOF'
#!/usr/bin/env bash
# Instalado por scripts/instala-hooks.sh do repositório claude-skills.
s="$(git rev-parse --show-toplevel)/scripts/verifica-sensivel.sh"
[ -f "$s" ] || exit 0
exec bash "$s" --msg "$1"
EOF
chmod +x "$HOOKS/pre-commit" "$HOOKS/commit-msg"

git -C "$ROOT" config core.hooksPath "$HOOKS"
echo "hooks instalados em $HOOKS (core.hooksPath deste clone)"

LISTA="$CONF/proibidos.txt"
if [ ! -e "$LISTA" ]; then
  cat > "$LISTA" <<'EOF'
# Lista pessoal do scripts/verifica-sensivel.sh. NUNCA vai para o repositório.
# Um termo por linha, sem diferenciar maiúsculas: hostnames curtos, domínios internos,
# nomes de cliente, usuários e nomes de conexão reais. Linhas com # são ignoradas.
EOF
  echo "lista pessoal criada em $LISTA: preencha com os seus termos"
fi
