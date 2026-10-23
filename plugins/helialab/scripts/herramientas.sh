#!/usr/bin/env bash
# Instala herramientas que faltan (macOS con Homebrew; Linux: mejor esfuerzo con apt y enlaces). Solo las pedidas.
# Uso: bash herramientas.sh git gh node pnpm docker warp [python kicad]
set -u
sistema=$(uname -s)
resultado=""
anota() { resultado="${resultado}\"$1\":\"$2\","; }

if [ "$sistema" = "Darwin" ]; then
  command -v brew >/dev/null 2>&1 || { echo 'FALTA Homebrew: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" y repite.'; exit 1; }
  for h in "$@"; do
    case "$h" in
      git|gh) brew install "$h" >/dev/null 2>&1 && anota "$h" ok || anota "$h" error ;;
      node) brew install node@24 >/dev/null 2>&1 && brew link --overwrite node@24 >/dev/null 2>&1 && anota node ok || anota node error ;;
      python) brew install python@3.13 >/dev/null 2>&1 && anota python ok || anota python error ;;
      docker) brew install --cask docker >/dev/null 2>&1 && anota docker ok || anota docker error ;;
      warp) brew install --cask cloudflare-warp >/dev/null 2>&1 && anota warp ok || anota warp error ;;
      kicad) brew install --cask kicad >/dev/null 2>&1 && anota kicad ok || anota kicad error ;;
      pnpm) ;;
      *) anota "$h" desconocida ;;
    esac
  done
else
  for h in "$@"; do
    case "$h" in
      git|python) sudo apt-get install -y -qq "$( [ "$h" = python ] && echo python3 || echo git)" >/dev/null 2>&1 && anota "$h" ok || anota "$h" error ;;
      gh) anota gh "manual: https://github.com/cli/cli/blob/trunk/docs/install_linux.md" ;;
      node) anota node "manual: https://nodejs.org/en/download (Node 24 LTS)" ;;
      docker) anota docker "manual: https://docs.docker.com/engine/install/" ;;
      warp) anota warp "manual: https://pkg.cloudflareclient.com/" ;;
      kicad) anota kicad "manual: https://www.kicad.org/download/linux/" ;;
      pnpm) ;;
      *) anota "$h" desconocida ;;
    esac
  done
fi
for h in "$@"; do
  if [ "$h" = pnpm ]; then
    command -v npm >/dev/null 2>&1 && npm install -g pnpm@10 >/dev/null 2>&1 && anota pnpm ok || anota pnpm "falta node o permisos de npm"
  fi
done
echo "{${resultado%,}}"
echo "Docker Desktop y WARP se abren desde Aplicaciones la primera vez."
