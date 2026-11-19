#!/usr/bin/env bash
# Procura IP, hostname, e-mail, senha e token no que vai para o repositório público.
#
# Uso: ./scripts/verifica-sensivel.sh            (o que está no stage; usado pelo pre-commit)
#      ./scripts/verifica-sensivel.sh --tudo     (todos os arquivos versionados)
#      ./scripts/verifica-sensivel.sh --historico (todos os commits e mensagens, de todos os branches)
#      ./scripts/verifica-sensivel.sh --msg <arq> (mensagem de commit; usado pelo commit-msg)
#
# Sai com 1 se encontrar algo. O pre-commit bloqueia o commit nesse caso.
#
# Lista pessoal (fora do repositório, nunca versionada): hostnames, domínios, nomes de
# cliente e usuários reais, um por linha, comparados sem diferenciar maiúsculas.
#   ${CLAUDE_SKILLS_PROIBIDOS:-${XDG_CONFIG_HOME:-$HOME/.config}/claude-skills/proibidos.txt}
#
# Exceções do projeto (versionadas): .sensivel-permitido, uma regex por linha, comparada com
# o trecho encontrado inteiro. Ex.: números de versão Oracle que parecem IPv4 (12.1.0.2).
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)" || exit 2
cd "$ROOT" || exit 2
PROIBIDOS="${CLAUDE_SKILLS_PROIBIDOS:-${XDG_CONFIG_HOME:-$HOME/.config}/claude-skills/proibidos.txt}"
PERMITIDO="$ROOT/.sensivel-permitido"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
LOC="$tmp/loc"; TXT="$tmp/txt"; ACHADOS="$tmp/achados"; : > "$ACHADOS"

# --- Entrada: "local<TAB>texto", uma linha por linha adicionada -------------------------
modo="${1:---stage}"
case "$modo" in
  --stage)
    { git diff --cached --name-only --diff-filter=ACMR | sed 's/^/(nome do arquivo)\t/'
      git diff --cached -U0 --no-color --no-ext-diff --diff-filter=ACMR | awk '
        /^\+\+\+ /{ f=substr($0,7); next }
        /^@@/     { s=$0; sub(/^@@ -[0-9,]+ \+/,"",s); sub(/[, ].*/,"",s); n=s-1; next }
        /^\+/     { n++; print f ":" n "\t" substr($0,2) }'
    } > "$tmp/in" ;;
  --tudo)
    { git ls-files | sed 's/^/(nome do arquivo)\t/'
      git grep -nI --cached -e '' | sed -E 's/^([^:]*:[0-9]+):/\1\t/'
    } > "$tmp/in" ;;
  --historico)
    { git log --all --name-only --format='@@C %h' | awk '/^@@C /{c=$2;next} NF{print c ":(nome do arquivo)\t" $0}'
      git log --all -p -U0 --no-color --no-ext-diff --format='@@C %h' | awk '
        /^@@C /   { c=$2; next }
        /^\+\+\+ /{ f=substr($0,7); next }
        /^\+/     { print c ":" f "\t" substr($0,2) }'
      git log --all --format='@@C %h%n%B' | awk '/^@@C /{c=$2;next} {print c ":(mensagem)\t" $0}'
    } > "$tmp/in" ;;
  --msg)
    [ -f "${2:-}" ] || { echo "uso: $0 --msg <arquivo>"; exit 2; }
    grep -v '^#' "$2" | awk '{print "(mensagem de commit)\t" $0}' > "$tmp/in" ;;
  *) sed -n '2,8p' "$0"; exit 2 ;;
esac

cut -f1  "$tmp/in" > "$LOC"
cut -f2- "$tmp/in" > "$TXT"
[ -s "$TXT" ] || exit 0

# Procura uma regex no texto e registra "local<TAB>categoria<TAB>trecho".
# $3 = regex de exceções (comparada com o trecho inteiro); vazio = sem exceção.
procura() {
  local cat="$1" re="$2" exc="${3:-}" args
  if [ "${4:-}" = lista ]; then args=(-F -f "$re"); else args=(-E -e "$re"); fi
  grep -noi "${args[@]}" "$TXT" 2>/dev/null | while IFS= read -r l; do
    local n="${l%%:*}" m="${l#*:}"
    if [ -n "$exc" ] && printf '%s\n' "$m" | grep -qixE "$exc"; then continue; fi
    if [ -s "$PERMITIDO" ] && printf '%s\n' "$m" | grep -qixE -f <(grep -vE '^\s*(#|$)' "$PERMITIDO"); then continue; fi
    printf '%s\t%s\t%s\n' "$(sed -n "${n}p" "$LOC")" "$cat" "$m"
  done >> "$ACHADOS"
}

# IPv4 (octetos até 255). Exceções: loopback, 0.0.0.0, máscaras e as faixas de documentação
# da RFC 5737 (192.0.2.x, 198.51.100.x, 203.0.113.x), próprias para exemplo. O trecho é
# capturado com o caractere anterior e o grupo seguinte, para ignorar números dentro de
# versão de kernel ou pacote (ex.: "-209.161.7.2.el8uek"), que vêm colados a "-" ou ".x".
OCT='(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])'
procura "IPv4" "[.-]?\\b$OCT\\.$OCT\\.$OCT\\.$OCT\\b(\\.[0-9a-z]+)?" \
  '[.-].*|[0-9a-z]+(\.[0-9a-z]+){4}|127\.0\.0\.1|0\.0\.0\.0|255\.255\.[0-9.]+|192\.0\.2\.[0-9]+|198\.51\.100\.[0-9]+|203\.0\.113\.[0-9]+'

# IPv6 e MAC. Exceções: ::1 e a faixa de documentação 2001:db8::/32 (RFC 3849).
procura "IPv6/MAC" '\b([0-9a-f]{1,4}:){3,7}[0-9a-f]{1,4}\b|\b([0-9a-f]{1,4}:){1,7}:([0-9a-f]{1,4}\b)?' \
  '::1|2001:db8:.*'

# E-mail. Exceções: example.* e endereços noreply.
procura "e-mail" '[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}' \
  '[^@]+@(example\.(com|net|org)|[a-z0-9.-]*noreply[a-z0-9.-]*)|noreply@[a-z0-9.-]+'

# Domínio com cara de interno ou de empresa. Exceções: fornecedores e sites públicos
# citados como fonte. Hostname sem domínio (nome curto do servidor) só a lista pessoal pega.
procura "domínio" '\b([a-z0-9-]+\.)+(com|net|org|br|io|local|localdomain|lan|corp|intra|intranet|internal|cloud|gov|edu)\b' \
  '(.+\.)?(oracle|github|githubusercontent|claude|anthropic|example|redhat|suse|kernel|microsoft|mysql|mariadb|postgresql|mongodb|ibm|sap|redis|python|gnu|ubuntu|debian|fedoraproject|centos|rockylinux|almalinux)\.(com|org|net|io)|localhost\.localdomain'

# Segredos.
procura "chave privada" '-----BEGIN ([A-Z]+ )*PRIVATE KEY-----'
procura "token"        '\b(gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|sk-ant-[A-Za-z0-9_-]{20,}|xox[abprs]-[A-Za-z0-9-]{10,})'
procura "senha"        '\b(password|passwd|pwd|senha|secret)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[^[:space:]"'"'"'<>$*{}()`]{4,}'
procura "senha SQL"    '\bidentified[[:space:]]+by[[:space:]]+["'"'"']?[^[:space:]"'"'"'<>$*;]{3,}'
procura "senha SQL"    '\b(sqlplus|conn|connect|rman|expdp|impdp)[[:space:]]+(-[a-z]+[[:space:]]+)*[a-z0-9_$#]+/[^[:space:]@/<>"'"'"']+'

# Lista pessoal: hostnames, domínios, clientes e usuários reais.
if [ -s "$PROIBIDOS" ]; then
  grep -vE '^\s*(#|$)' "$PROIBIDOS" > "$tmp/lista"
  if [ -s "$tmp/lista" ]; then procura "lista pessoal" "$tmp/lista" "" lista
  else echo "aviso: lista pessoal vazia ($PROIBIDOS)." >&2; fi
else
  echo "aviso: lista pessoal não encontrada ($PROIBIDOS)." >&2
  echo "       Hostnames sem domínio e nomes de cliente não serão detectados." >&2
fi

# Caminhos que nunca devem ir para o repositório: saídas de teste, chaves, relatórios.
if [ "$modo" = --stage ] || [ "$modo" = --tudo ]; then
  { [ "$modo" = --stage ] && git diff --cached --name-only --diff-filter=ACMR || git ls-files; } \
    | grep -iE '(-workspace/|(^|/)outputs/|evals/results/|\.(pem|key|p12|pfx)$|(^|/)id_(rsa|ecdsa|ed25519)|(^|/)relatorios?/|\.env$|(^|/)proibidos\.txt$)' \
    | while IFS= read -r p; do printf '%s\t%s\t%s\n' "(nome do arquivo)" "caminho proibido" "$p"; done >> "$ACHADOS"
fi

[ -s "$ACHADOS" ] || exit 0

sort -u "$ACHADOS" | awk -F'\t' '{printf "  %-14s %s\n                 %s\n", "[" $2 "]", $1, $3}'
echo
case "$modo" in
  --stage) echo "Commit bloqueado: possível dado sensível no que está no stage."
           echo "Remova o trecho, ou, se for falso positivo, acrescente uma regex em .sensivel-permitido." ;;
  --msg)   echo "Commit bloqueado: possível dado sensível na mensagem de commit." ;;
  *)       echo "Encontrado possível dado sensível. Confira cada item acima." ;;
esac
exit 1
