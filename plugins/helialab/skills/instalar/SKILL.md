---
name: instalar
description: Prepara un computador para trabajar en Helialab - revisa e instala las herramientas (Git, GitHub CLI, Node, pnpm, Docker Desktop, Cloudflare WARP y, según el rol, Python y KiCad), inicia sesión en GitHub, crea la carpeta Helialab con los repos a los que la persona tiene acceso por sus equipos, prepara el entorno de cada repo, inscribe la VPN y termina en la primera tarea. Idempotente; también repara un entorno existente. Úsala con "/helialab:instalar", "instala Helialab", "prepara mi computador para Helialab", "onboarding".
---

# Instalar el entorno Helialab

Guía a la persona de punta a punta. **Hazlo tú** con las herramientas, y pide a la persona solo lo interactivo (iniciar sesión, abrir apps). Antes de cada paso, comprueba si ya está hecho y sáltalo si es así.

Los scripts están en `../../scripts/` respecto de la carpeta base de esta skill. En Windows usa los `.ps1` con `powershell -NoProfile -ExecutionPolicy Bypass -File <script>`; en macOS y Linux, los `.sh` con `bash <script>`. El espacio de trabajo es `~/Helialab` (`%USERPROFILE%\Helialab` en Windows), salvo que la persona pida otra carpeta.

## 1. Revisar
Corre `revisar.ps1` / `revisar.sh` (con la carpeta del espacio). Devuelve JSON: herramientas, sesión de GitHub, equipos, VPN, Docker y repos. Muestra a la persona una tabla corta de qué está y qué falta.

## 2. Herramientas
- **Siempre:** `git`, `gh`, `node` (24 LTS), `pnpm`, `docker` (Docker Desktop), `warp` (Cloudflare One Agent).
- **Equipo `hardware`:** además `python` y `kicad`. Si el paso 3 aún no se hizo, decide el rol después.

Di qué vas a instalar, pide **una** confirmación y corre `herramientas.ps1` / `herramientas.sh` con la lista de lo que falta, en este orden: `node` antes que `pnpm`. Si Windows pide permisos de administrador o reinicio, explícalo y retoma después. Vuelve a correr la revisión.

## 3. GitHub
- **Sin usuario en `github`:** pide a la persona que escriba en Claude Code `! gh auth login --web --git-protocol https --scopes read:org,project` y complete el navegador. Luego `gh auth setup-git`.
- **Revisa `github.org`:**
  - `active`: sigue.
  - `pending`: la invitación espera aceptación en https://github.com/orgs/Helialab/invitation (2FA obligatorio). Que la acepte y repite.
  - Vacío: **detente**. La persona aún no fue dada de alta. Dile que pida a un admin de Helialab el alta (grupos de Google + invitación a la org en su equipo) y que vuelva a correr `/helialab:instalar`.
- **Configura la identidad de git** si falta (`git config --global user.name` y `user.email`). Pregunta los datos; el correo debe ser el de su cuenta de GitHub.

## 4. Carpeta y repos
1. Crea la carpeta del espacio.
2. Si no existe `CLAUDE.md` en ella, copia `../../plantillas/CLAUDE.md`.
3. Corre `clonar.ps1` / `clonar.sh`. Clona los repos que sus equipos permiten (consulta a GitHub; no hay lista fija) y respeta `.helialab/carpeta` de cada repo.
4. Muestra qué quedó clonado.

## 5. Entorno de cada repo
Por cada repo clonado que tenga `scripts/dev/instalar-entorno.mjs`, corre `node scripts/dev/instalar-entorno.mjs` dentro de su carpeta. Es idempotente y al final imprime un JSON con los pasos.
- Si dice que Docker no responde: pide abrir Docker Desktop, espera a que diga "running" y repite.
- Si un paso falla, muestra el error y corrígelo: dependencias, puertos ocupados, etc. No sigas con errores.

## 6. VPN (Cloudflare WARP)
Si `vpn` no dice `Connected`:
1. Que la persona abra **Cloudflare One Agent** (WARP).
2. Preferencias → Cuenta → **Iniciar sesión en Cloudflare Zero Trust** → equipo **`helialab`** → iniciar sesión con **Google**, con la cuenta que dio de alta el admin.
3. Comprueba con `warp-cli status` (Windows: `"C:\Program Files\Cloudflare\Cloudflare WARP\warp-cli.exe" status`).
4. Luego prueba la wiki: `curl -s -o /dev/null -w "%{http_code}" https://wiki.helialab.com/`.
   - `200` o `302` = bien.
   - `403` = falta el grupo de Google o la VPN no está activa.

## 7. Listo
Resume en una tabla qué quedó listo y qué no. Luego indica:
1. Abrir Claude Code **dentro del repo**, por ejemplo `cd ~/Helialab/HeliaOS` y luego `claude`, para que carguen sus reglas y skills.
2. Escribir `/heliaos-empezar`: muestra novedades, el tablero y una primera tarea sugerida (`primera-tarea`).
3. Para revisar o reparar el entorno: `/helialab:doctor`. Para traer todo al día: `/helialab:actualizar`.

**Nunca** pidas ni guardes contraseñas, tokens o llaves: todo login lo hace la persona en su navegador. Los secretos de cada repo se generan en local (`pnpm preparar`) o los entrega un admin por los canales del repo.
