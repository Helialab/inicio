# Revisa el equipo para trabajar en Helialab (Windows). Solo lee; no instala ni cambia nada.
# Salida: JSON en una línea con herramientas, sesión de GitHub, equipos, VPN, Docker y espacio de trabajo.
# Uso: powershell -NoProfile -ExecutionPolicy Bypass -File revisar.ps1 [-Espacio <carpeta>]
param([string]$Espacio = (Join-Path $env:USERPROFILE "Helialab"))
$ErrorActionPreference = "SilentlyContinue"

function Version($cmd, $argumentos = "--version") {
  $c = Get-Command $cmd -ErrorAction SilentlyContinue
  if (-not $c) { return $null }
  $v = (& $cmd $argumentos 2>$null | Select-Object -First 1)
  if ($v) { return "$v".Trim() } else { return "instalado" }
}

$warp = $null
$warpCli = Get-Command warp-cli -ErrorAction SilentlyContinue
if (-not $warpCli -and (Test-Path "C:\Program Files\Cloudflare\Cloudflare WARP\warp-cli.exe")) { $warpCli = "C:\Program Files\Cloudflare\Cloudflare WARP\warp-cli.exe" }
if ($warpCli) { $warp = ("" + (& $warpCli status 2>$null | Out-String)).Trim() }

$gh = [ordered]@{ instalado = [bool](Get-Command gh -ErrorAction SilentlyContinue); usuario = $null; org = $null; equipos = @() }
if ($gh.instalado) {
  $u = gh api user --jq .login 2>$null
  if ($LASTEXITCODE -eq 0) {
    $gh.usuario = "$u".Trim()
    $gh.org = ("" + (gh api user/memberships/orgs/Helialab --jq .state 2>$null)).Trim()
    # Windows PowerShell 5.1 se come las comillas dobles al pasar argumentos a gh.exe, así que un
    # filtro --jq como select(.login=="Helialab") llega roto. Pedimos JSON crudo y filtramos acá.
    # equipos queda en null si GitHub no respondió, y en [] si de verdad no hay ninguno.
    $equiposJson = (gh api user/teams --paginate 2>$null | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { $gh.equipos = $null }
    elseif ($equiposJson) {
      try { $gh.equipos = @(($equiposJson | ConvertFrom-Json) | Where-Object { $_.organization.login -eq "Helialab" } | ForEach-Object { $_.slug }) }
      catch { $gh.equipos = $null }
    }
  }
}

$dockerCorre = $false
if (Get-Command docker -ErrorAction SilentlyContinue) { docker info *> $null; $dockerCorre = ($LASTEXITCODE -eq 0) }

$repos = @()
if (Test-Path $Espacio) { $repos = @(Get-ChildItem $Espacio -Directory | Where-Object { Test-Path (Join-Path $_.FullName ".git") } | ForEach-Object { $_.Name }) }

[ordered]@{
  sistema      = "windows"
  herramientas = [ordered]@{
    git    = Version git
    gh     = Version gh
    node   = Version node
    pnpm   = Version pnpm
    docker = Version docker
    python = Version python
    kicad  = $(if (Test-Path "C:\Program Files\KiCad") { "instalado" } else { $null })
    warp   = $(if ($warpCli) { "instalado" } else { $null })
  }
  github       = $gh
  vpn          = $warp
  dockerCorre  = $dockerCorre
  espacio      = [ordered]@{ ruta = $Espacio; existe = (Test-Path $Espacio); repos = $repos }
} | ConvertTo-Json -Compress -Depth 4
