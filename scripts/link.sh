#!/usr/bin/env bash
# Liga cada skill do repositório em ~/.claude/skills por symlink (Linux/WSL).
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../skills" && pwd)"
TARGET="$HOME/.claude/skills"
mkdir -p "$TARGET"

for dir in "$REPO"/*/; do
  nome="$(basename "$dir")"
  link="$TARGET/$nome"
  if [ -L "$link" ]; then
    echo "já ligado: $nome"
  elif [ -e "$link" ]; then
    echo "AVISO: $link existe e não é link — remova ou renomeie e rode de novo"
  else
    ln -s "${dir%/}" "$link"
    echo "ligado: $nome"
  fi
done

# Hooks que barram commit com IP, hostname, senha ou token (repositório público).
bash "$(dirname "$0")/instala-hooks.sh"
