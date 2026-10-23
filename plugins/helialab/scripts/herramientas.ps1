# Instala herramientas que faltan (Windows, con winget). Solo instala las pedidas; no actualiza las existentes.
# Uso: powershell -NoProfile -ExecutionPolicy Bypass -File herramientas.ps1 git gh node pnpm docker warp [python kicad]
$ErrorActionPreference = "Continue"
$ids = @{
  git    = "Git.Git"
  gh     = "GitHub.cli"
  node   = "OpenJS.NodeJS.LTS"
  docker = "Docker.DockerDesktop"
  warp   = "Cloudflare.Warp"
  python = "Python.Python.3.13"
  kicad  = "KiCad.KiCad"
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Write-Output "FALTA winget: instala 'App Installer' desde Microsoft Store y repite."; exit 1 }

$resultado = [ordered]@{}
foreach ($h in $args) {
  if ($h -eq "pnpm") { continue }
  if (-not $ids.ContainsKey($h)) { $resultado[$h] = "desconocida"; continue }
  Write-Output "Instalando $h ($($ids[$h]))..."
  winget install --id $ids[$h] -e --accept-source-agreements --accept-package-agreements --silent --disable-interactivity | Out-Null
  $resultado[$h] = $(if ($LASTEXITCODE -eq 0) { "ok" } else { "error $LASTEXITCODE" })
}
# Recargar PATH para usar lo recién instalado en esta misma ejecución.
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
if ($args -contains "pnpm") {
  if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm install -g pnpm@10 2>&1 | Out-Null
    $resultado["pnpm"] = $(if ($LASTEXITCODE -eq 0) { "ok" } else { "error $LASTEXITCODE" })
  } else { $resultado["pnpm"] = "falta node (instalarlo primero)" }
}
$resultado | ConvertTo-Json -Compress
Write-Output "Si algo no aparece en esta terminal, ciérrala y abre una nueva (PATH). Docker Desktop y WARP se abren desde el menú Inicio."
