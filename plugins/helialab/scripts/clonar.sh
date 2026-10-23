#!/usr/bin/env bash
# Clona en el espacio de trabajo los repos de Helialab a los que la persona tiene acceso por sus equipos de GitHub
# (macOS / Linux). No hay lista pública de repos: se consulta a GitHub con la sesión de gh. Idempotente.
# Si un repo trae .helialab/carpeta, se usa ese nombre de carpeta (p. ej. HeliaOS).
# Uso: bash clonar.sh [carpeta-del-espacio]
# Salida: JSON en una línea; "fallos" lista las consultas a GitHub que no respondieron.
ESPACIO="${1:-$HOME/Helialab}"
mkdir -p "$ESPACIO"
# "fallos" distingue "GitHub no respondió" de "no hay repos": sin esto una consulta rota se veía
# igual que un espacio sin nada que clonar.
fallos=""
anota() { fallos="$fallos${fallos:+,}\"$1\""; }
if ! equipos=$(gh api user/teams --paginate --jq '.[] | select(.organization.login=="Helialab") | .slug' 2>/dev/null); then
  anota "equipos de GitHub"; equipos=""
fi
repos=""
for e in $equipos; do
  if del_equipo=$(gh api "orgs/Helialab/teams/$e/repos" --paginate --jq '.[] | select(.archived | not) | .name' 2>/dev/null)
  then repos="$repos $del_equipo"
  else anota "repos del equipo $e"
  fi
done
# Sin equipos (o sin repos en ellos): todos los repos privados de la org a los que haya acceso.
if [ -z "${repos// }" ] && ! repos=$(gh repo list Helialab --limit 200 --no-archived --json name,visibility --jq '.[] | select(.visibility != "PUBLIC") | .name' 2>/dev/null); then
  anota "repos de la organización"; repos=""
fi
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
    if [ -n "$nombre" ] && [ "$nombre" != "$r" ]; then
      if [ "$(printf %s "$nombre" | tr '[:upper:]' '[:lower:]')" = "$(printf %s "$r" | tr '[:upper:]' '[:lower:]')" ]; then
        # En macOS el disco suele ignorar mayúsculas, así que el destino "ya existe" (es esta misma
        # carpeta): hay que pasar por un nombre temporal para que el cambio llegue al disco.
        mv "$ESPACIO/$r" "$ESPACIO/$r-renombrando-$$" && mv "$ESPACIO/$r-renombrando-$$" "$ESPACIO/$nombre" && carpeta="$nombre"
      elif [ ! -e "$ESPACIO/$nombre" ]; then
        mv "$ESPACIO/$r" "$ESPACIO/$nombre" && carpeta="$nombre"
      fi
    fi
  fi
  salida="$salida{\"repo\":\"$r\",\"carpeta\":\"$carpeta\",\"estado\":\"clonado\"},"
done
echo "{\"espacio\":\"$ESPACIO\",\"repos\":[${salida%,}],\"fallos\":[$fallos]}"
