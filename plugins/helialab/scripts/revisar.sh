#!/usr/bin/env bash
# Revisa el equipo para trabajar en Helialab (macOS / Linux). Solo lee; no instala ni cambia nada.
# Salida: JSON en una línea con herramientas, sesión de GitHub, equipos, VPN, Docker y espacio de trabajo.
# Uso: bash revisar.sh [carpeta-del-espacio]
ESPACIO="${1:-$HOME/Helialab}"

ver() { command -v "$1" >/dev/null 2>&1 && { "$@" 2>/dev/null | head -1 | tr -d '"\\' || echo instalado; } || echo ""; }
js() { [ -n "$1" ] && printf '"%s"' "$1" || printf 'null'; }

usuario=""; org=""; equipos=""
if command -v gh >/dev/null 2>&1 && usuario=$(gh api user --jq .login 2>/dev/null); then
  org=$(gh api user/memberships/orgs/Helialab --jq .state 2>/dev/null)
  equipos=$(gh api user/teams --jq '[.[] | select(.organization.login=="Helialab") | .slug] | join(",")' 2>/dev/null)
fi
warp=""; command -v warp-cli >/dev/null 2>&1 && warp=$(warp-cli status 2>/dev/null | tr '\n' ' ' | tr -d '"')
docker_corre=false; command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1 && docker_corre=true
kicad=""; { [ -d /Applications/KiCad ] || command -v kicad-cli >/dev/null 2>&1; } && kicad=instalado
repos=""; [ -d "$ESPACIO" ] && repos=$(for d in "$ESPACIO"/*/; do [ -d "$d/.git" ] && basename "$d"; done | paste -sd, -)
lista() { [ -n "$1" ] && printf '["%s"]' "$(echo "$1" | sed 's/,/","/g')" || printf '[]'; }

printf '{"sistema":"%s","herramientas":{"git":%s,"gh":%s,"node":%s,"pnpm":%s,"docker":%s,"python":%s,"kicad":%s,"warp":%s},' \
  "$(uname -s | tr 'A-Z' 'a-z')" "$(js "$(ver git --version)")" "$(js "$(ver gh --version)")" "$(js "$(ver node --version)")" \
  "$(js "$(ver pnpm --version)")" "$(js "$(ver docker --version)")" "$(js "$(ver python3 --version)")" "$(js "$kicad")" \
  "$(js "$(command -v warp-cli >/dev/null 2>&1 && echo instalado)")"
printf '"github":{"instalado":%s,"usuario":%s,"org":%s,"equipos":%s},"vpn":%s,"dockerCorre":%s,"espacio":{"ruta":"%s","existe":%s,"repos":%s}}\n' \
  "$(command -v gh >/dev/null 2>&1 && echo true || echo false)" "$(js "$usuario")" "$(js "$org")" "$(lista "$equipos")" \
  "$(js "$warp")" "$docker_corre" "$ESPACIO" "$([ -d "$ESPACIO" ] && echo true || echo false)" "$(lista "$repos")"
