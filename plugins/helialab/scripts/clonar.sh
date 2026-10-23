#!/usr/bin/env bash
# Clona en el espacio de trabajo los repos de Helialab a los que la persona tiene acceso por sus equipos de GitHub
# (macOS / Linux). No hay lista pública de repos: se consulta a GitHub con la sesión de gh. Idempotente.
# Si un repo trae .helialab/carpeta, se usa ese nombre de carpeta (p. ej. HeliaOS).
# Uso: bash clonar.sh [carpeta-del-espacio]
ESPACIO="${1:-$HOME/Helialab}"
mkdir -p "$ESPACIO"
equipos=$(gh api user/teams --jq '.[] | select(.organization.login=="Helialab") | .slug' 2>/dev/null)
repos=""
for e in $equipos; do repos="$repos $(gh api "orgs/Helialab/teams/$e/repos" --paginate --jq '.[] | select(.archived | not) | .name' 2>/dev/null)"; done
[ -z "${repos// }" ] && repos=$(gh repo list Helialab --limit 200 --no-archived --json name,visibility --jq '.[] | select(.visibility != "PUBLIC") | .name' 2>/dev/null)
salida=""
for r in $(echo $repos | tr ' ' '\n' | grep -vx inicio | sort -u); do
  ya=""
  for d in "$ESPACIO"/*/; do
    [ -d "$d/.git" ] && git -C "$d" remote get-url origin 2>/dev/null | grep -Eq "Helialab/$r(\.git)?$" && ya=$(basename "$d") && break
  done
  if [ -n "$ya" ]; then salida="$salida{\"repo\":\"$r\",\"carpeta\":\"$ya\",\"estado\":\"ya estaba\"},"; continue; fi
  if ! gh repo clone "Helialab/$r" "$ESPACIO/$r" -- --quiet 2>/dev/null; then salida="$salida{\"repo\":\"$r\",\"carpeta\":null,\"estado\":\"error al clonar\"},"; continue; fi
  carpeta="$r"
  if [ -f "$ESPACIO/$r/.helialab/carpeta" ]; then
    nombre=$(head -1 "$ESPACIO/$r/.helialab/carpeta" | tr -d '\r ')
    [ -n "$nombre" ] && [ ! -e "$ESPACIO/$nombre" ] && mv "$ESPACIO/$r" "$ESPACIO/$nombre" && carpeta="$nombre"
  fi
  salida="$salida{\"repo\":\"$r\",\"carpeta\":\"$carpeta\",\"estado\":\"clonado\"},"
done
echo "{\"espacio\":\"$ESPACIO\",\"repos\":[${salida%,}]}"
