---
name: actualizar
description: Trae al día el entorno Helialab - actualiza el plugin, hace pull de cada repo del espacio sin tocar trabajo en curso, reinstala dependencias y aplica migraciones si cambiaron, y clona repos nuevos a los que la persona tenga acceso. Úsala con "/helialab:actualizar", "actualiza todo", "trae lo último", al volver después de días.
---

# Actualizar el entorno Helialab

1. **Plugin:**
   ```bash
   claude plugin marketplace update helialab
   claude plugin update helialab@helialab
   ```
   Si cambió de versión, dile a la persona que reinicie Claude Code al terminar.
2. **Repos nuevos:** corre `../../scripts/clonar.ps1` o `clonar.sh` (relativo a esta skill). Solo clona lo que falta.
3. **Cada repo del espacio:**
   - `git fetch --quiet origin`.
   - Si está en `main` sin cambios: `git pull --ff-only`.
   - Si está en una rama de tarea o tiene cambios: **no lo toques**. Informa el atraso y sugiere rebase al entregar (`/heliaos-entregar` lo hace).
   - Si el pull trajo cambios en `pnpm-lock.yaml`, migraciones (`packages/db/prisma/migrations/`) o `scripts/dev/instalar-entorno.mjs`: corre `node scripts/dev/instalar-entorno.mjs` en ese repo.
4. **Resumen:** qué se actualizó, qué quedó sin tocar y por qué. Para ver qué cambió en HeliaOS: `/heliaos-empezar` dentro del repo.
