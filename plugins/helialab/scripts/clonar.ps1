# Clona en el espacio de trabajo los repos de Helialab a los que la persona tiene acceso por sus equipos de GitHub
# (Windows). No hay lista pública de repos: se consulta a GitHub con la sesión de gh. Idempotente.
# Si un repo trae .helialab/carpeta, se usa ese nombre de carpeta (p. ej. HeliaOS).
# Uso: powershell -NoProfile -ExecutionPolicy Bypass -File clonar.ps1 [-Espacio <carpeta>]
param([string]$Espacio = (Join-Path $env:USERPROFILE "Helialab"))
$ErrorActionPreference = "Continue"
New-Item -ItemType Directory -Force $Espacio | Out-Null

$equipos = @(gh api user/teams --jq '.[] | select(.organization.login=="Helialab") | .slug' 2>$null | Where-Object { $_ })
$repos = @()
foreach ($e in $equipos) { $repos += @(gh api "orgs/Helialab/teams/$e/repos" --paginate --jq '.[] | select(.archived | not) | .name' 2>$null | Where-Object { $_ }) }
if ($repos.Count -eq 0) { $repos = @(gh repo list Helialab --limit 200 --no-archived --json name,visibility --jq '.[] | select(.visibility != "PUBLIC") | .name' 2>$null | Where-Object { $_ }) }
$repos = $repos | Where-Object { $_ -ne "inicio" } | Sort-Object -Unique

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
    if ($nombre -and -not (Test-Path (Join-Path $Espacio $nombre))) { Rename-Item $destino $nombre; $carpeta = $nombre }
  }
  $resultado += [ordered]@{ repo = $r; carpeta = $carpeta; estado = "clonado" }
}
[ordered]@{ espacio = $Espacio; equipos = $equipos; repos = $resultado } | ConvertTo-Json -Compress -Depth 4
