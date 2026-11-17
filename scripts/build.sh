#!/usr/bin/env bash
# Valida e empacota as skills em dist/<nome>.zip para upload no claude.ai.
# Uso: ./scripts/build.sh            (todas)
#      ./scripts/build.sh <nome>     (uma)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS="$ROOT/skills"
DIST="$ROOT/dist"
command -v zip >/dev/null || { echo "erro: 'zip' não instalado"; exit 1; }
mkdir -p "$DIST"

alvos=("$@")
[ ${#alvos[@]} -eq 0 ] && mapfile -t alvos < <(ls -1 "$SKILLS")

falhas=0
for nome in "${alvos[@]}"; do
  dir="$SKILLS/$nome"
  md="$dir/SKILL.md"
  [ -f "$md" ] || { echo "✗ $nome: sem SKILL.md"; falhas=$((falhas+1)); continue; }

  fm_name=$(awk '/^---$/{n++; next} n==1 && /^name:/{sub(/^name:[ ]*/,""); print; exit}' "$md")
  desc=$(awk '/^---$/{n++; next} n==1 && /^description:/{sub(/^description:[ ]*/,""); print; exit}' "$md")
  extra=$(awk '/^---$/{n++; next} n==1 && /^[a-z_]+:/{split($0,a,":"); print a[1]}' "$md" | grep -vxE 'name|description' || true)
  ndesc=$(printf '%s' "$desc" | wc -m)

  erro=""
  [ "$fm_name" = "$nome" ] || erro+=" name '$fm_name' ≠ diretório;"
  [ "$ndesc" -le 1024 ]    || erro+=" description com $ndesc caracteres (máx 1024);"
  [ -z "$extra" ]          || erro+=" campos extras no frontmatter: $(echo $extra);"
  if [ -n "$erro" ]; then echo "✗ $nome:$erro"; falhas=$((falhas+1)); continue; fi

  rm -f "$DIST/$nome.zip"
  (cd "$SKILLS" && zip -qr "$DIST/$nome.zip" "$nome" -x "$nome/evals/*")
  echo "✓ $nome ($(wc -l < "$md") linhas, description $ndesc caracteres) → dist/$nome.zip"
done

exit $falhas
