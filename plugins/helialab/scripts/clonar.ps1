# Clona en el espacio de trabajo los repos de Helialab a los que la persona tiene acceso por sus equipos de GitHub
# (Windows). No hay lista pública de repos: se consulta a GitHub con la sesión de gh. Idempotente.
# Si un repo trae .helialab/carpeta, se usa ese nombre de carpeta (p. ej. HeliaOS).
# Uso: powershell -NoProfile -ExecutionPolicy Bypass -File clonar.ps1 [-Espacio <carpeta>]
# Salida: JSON en una línea; "fallos" lista las consultas a GitHub que no respondieron.
param([string]$Espacio = (Join-Path $env:USERPROFILE "Helialab"))
$ErrorActionPreference = "Continue"
New-Item -ItemType Directory -Force $Espacio | Out-Null

# Windows PowerShell 5.1 se come las comillas dobles al pasar argumentos a gh.exe, así que un filtro
# --jq como select(.login=="Helialab") llega roto y jq falla. Pedimos JSON crudo y filtramos acá.
function GhJson {
  param([string[]]$Argumentos)
  $texto = (& gh @Argumentos 2>$null | Out-String).Trim()
  if ($LASTEXITCODE -ne 0) { return @{ ok = $false; datos = @() } }
  if (-not $texto) { return @{ ok = $true; datos = @() } }
  try { return @{ ok = $true; datos = @($texto | ConvertFrom-Json) } } catch { return @{ ok = $false; datos = @() } }
}

$fallos = @()
$consulta = GhJson @("api", "user/teams", "--paginate")
if (-not $consulta.ok) { $fallos += "equipos de GitHub" }
$equipos = @($consulta.datos | Where-Object { $_.organization.login -eq "Helialab" } | ForEach-Object { $_.slug })

$repos = @()
foreach ($e in $equipos) {
  $consulta = GhJson @("api", "orgs/Helialab/teams/$e/repos", "--paginate")
  if (-not $consulta.ok) { $fallos += "repos del equipo $e"; continue }
  $repos += @($consulta.datos | Where-Object { -not $_.archived } | ForEach-Object { $_.name })
}
# Sin equipos (o sin repos en ellos): todos los repos privados de la org a los que haya acceso.
if ($repos.Count -eq 0) {
  $consulta = GhJson @("repo", "list", "Helialab", "--limit", "200", "--no-archived", "--json", "name,visibility")
  if (-not $consulta.ok) { $fallos += "repos de la organización" }
  $repos = @($consulta.datos | Where-Object { $_.visibility -ne "PUBLIC" } | ForEach-Object { $_.name })
}
$repos = @($repos | Where-Object { $_ -ne "inicio" } | Sort-Object -Unique)

$resultado = @()
foreach ($r in $repos) {
  $existente = Get-ChildItem $Espacio -Directory | Where-Object {
    (Test-Path (Join-Path $_.FullName ".git")) -and ((git -C $_.FullName remote get-url origin 2>$null) -match "Helialab/$r(\.git)?$")
  } | Select-Object -First 1
  if ($existente) { $resultado += [ordered]@{ repo = $r; carpeta = $existente.Name; estado = "ya estaba" }; continue }
  $destino = Join-Path $Espacio $r
  gh repo clone "Helialab/$r" $destino -- --quiet 2>$null
  if ($LASTEXITCODE -ne 0) { $resultado += [ordered]@{ repo = $r; carpeta = $null; estado = "error al clonar" }; continue }
  $preferida = Join-Path $destino ".helialab\carpeta"
  $carpeta = $r
  if (Test-Path $preferida) {
    $nombre = (Get-Content $preferida -TotalCount 1).Trim()
    # -cne porque -ne ignora mayúsculas: heliaos y HeliaOS son nombres distintos para nosotros.
    if ($nombre -and $nombre -cne $r) {
      if ($nombre -ieq $r) {
        # NTFS ignora mayúsculas, así que el destino "ya existe" (es esta misma carpeta): hay que
        # pasar por un nombre temporal para que el cambio de capitalización llegue al disco.
        $temporal = "$r-renombrando-$PID"
        Rename-Item $destino $temporal
        Rename-Item (Join-Path $Espacio $temporal) $nombre
        $carpeta = $nombre
      } elseif (-not (Test-Path (Join-Path $Espacio $nombre))) {
        Rename-Item $destino $nombre
        $carpeta = $nombre
      }
    }
  }
  $resultado += [ordered]@{ repo = $r; carpeta = $carpeta; estado = "clonado" }
}
# "fallos" distingue "GitHub no respondió" de "no hay repos": sin esto una consulta rota se veía
# igual que un espacio sin nada que clonar.
[ordered]@{ espacio = $Espacio; equipos = $equipos; repos = $resultado; fallos = $fallos } | ConvertTo-Json -Compress -Depth 4
