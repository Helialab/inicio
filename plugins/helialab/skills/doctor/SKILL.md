---
name: doctor
description: Revisa el entorno Helialab de este computador y dice qué está mal y cómo arreglarlo - herramientas y versiones, sesión y equipos de GitHub, VPN, Docker, repos del espacio (rama, cambios, atraso con main) y versión del plugin. Úsala con "/helialab:doctor", "algo no funciona", "revisa mi entorno", "no me conecta", "no me levanta HeliaOS".
---

# Doctor del entorno Helialab

Solo diagnostica. Antes de cambiar algo, propone el arreglo y pide confirmación.

1. Corre `../../scripts/revisar.ps1` (Windows) o `../../scripts/revisar.sh` (relativo a esta skill) con la carpeta del espacio (`~/Helialab` por defecto).
2. Por cada repo del espacio:
   ```bash
   git -C <repo> fetch --quiet origin
   git -C <repo> status -sb
   git -C <repo> rev-list --count HEAD..origin/main
   git -C <repo> worktree list
   ```
3. Versión del plugin: `claude plugin list` (`helialab@helialab`) frente a `claude plugin marketplace update helialab`.
4. Entrega una tabla **Componente · Estado · Arreglo**:

   | Síntoma | Arreglo |
   |---|---|
   | Falta una herramienta | `/helialab:instalar` (solo instala lo que falta) |
   | Sin sesión de GitHub | `! gh auth login --web --scopes read:org,project` |
   | Docker no corre | Abrir Docker Desktop |
   | VPN desconectada o 403 en la wiki | Revisar WARP (equipo `helialab`) y el grupo de Google con un admin |
   | Repo atrasado | `/helialab:actualizar` |
   | Cambios sin subir en una rama de tarea | `/heliaos-traspaso` dentro del repo |
   | Puertos ocupados por otro worktree | `pnpm preparar --ranura <k>` en ese worktree |

5. Si la persona quiere, aplica los arreglos uno por uno y vuelve a revisar.
