# Helialab · inicio

Deja un computador listo para trabajar en Helialab con **una línea**. Instala el plugin `helialab` de Claude Code y corre `/helialab:instalar`:

- revisa e instala las herramientas;
- inicia sesión en GitHub;
- crea la carpeta `Helialab` con los repos a los que tienes acceso;
- prepara cada repo;
- inscribe la VPN;
- termina en tu primera tarea.

**Antes:** tener [Claude Code](https://claude.com/claude-code) instalado y haber sido dado de alta por un admin de Helialab (grupos de Google + invitación a la organización de GitHub en tu equipo). Sin alta, el instalador se detiene al llegar a GitHub.

## La línea

**Windows (PowerShell):**

```powershell
claude plugin marketplace add Helialab/inicio; claude plugin install helialab@helialab; claude "/helialab:instalar"
```

**macOS / Linux:**

```bash
claude plugin marketplace add Helialab/inicio && claude plugin install helialab@helialab && claude "/helialab:instalar"
```

Dentro de Claude Code también sirve:

```
/plugin marketplace add Helialab/inicio
/plugin install helialab@helialab
/helialab:instalar
```

## Después

| Comando | Para qué |
|---|---|
| `/helialab:doctor` | Revisar el entorno y arreglar lo que falle |
| `/helialab:actualizar` | Traer al día el plugin, los repos, las dependencias y las migraciones |

## Qué hay aquí (y qué no)

Este es el **único repo público** de Helialab ligado al trabajo interno.

- **Contiene:** el plugin, scripts genéricos (`plugins/helialab/scripts/`) y una plantilla.
- **No contiene:** secretos, datos de clientes, direcciones internas ni la lista de repos privados. Los repos se consultan a GitHub después de que inicias sesión, según tus equipos.
- **Versión fija:** el marketplace instala una versión etiquetada (`helialab--vX.Y.Z`, fijada por commit). Cambiarla requiere una etiqueta nueva y un PR revisado por un admin.
