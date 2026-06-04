# Agent-X Uninstaller for Windows
# Usage: irm https://raw.githubusercontent.com/SlashpanOrg/agent-x/main/uninstall.ps1 | iex

$ErrorActionPreference = "Stop"

$InstallDir = if ($env:AGENTX_INSTALL_DIR) { $env:AGENTX_INSTALL_DIR } else { "$env:LOCALAPPDATA\agentx" }
$BinDir = if ($env:AGENTX_BIN_DIR) { $env:AGENTX_BIN_DIR } else { "$env:LOCALAPPDATA\agentx\bin" }
$ConfigDir = "$env:APPDATA\agentx"
$DataDir = "$env:LOCALAPPDATA\agentx"
$CacheDir = "$env:TEMP\agentx"

Write-Host ""
Write-Host "  Agent-X Uninstaller for Windows" -ForegroundColor Cyan
Write-Host ""

function Remove-Binary {
  $binPath = "$BinDir\agentx.cmd"
  if (Test-Path $binPath) {
    Remove-Item -Force $binPath
    Write-Host "  ✓ Removed binary: $binPath" -ForegroundColor Green
  } else {
    Write-Host "  ▸ No binary found at $binPath (skipped)" -ForegroundColor Cyan
  }
}

function Remove-Installation {
  if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
    Write-Host "  ✓ Removed installation: $InstallDir" -ForegroundColor Green
  } else {
    Write-Host "  ▸ No installation found at $InstallDir (skipped)" -ForegroundColor Cyan
  }
}

function Remove-GlobalPackage {
  $npm = Get-Command npm -ErrorAction SilentlyContinue
  if ($npm) {
    npm uninstall -g @agentx/cli 2>$null | Out-Null
    if ($?) { Write-Host "  ✓ Removed global npm package" -ForegroundColor Green }
  }
  $pnpm = Get-Command pnpm -ErrorAction SilentlyContinue
  if ($pnpm) {
    pnpm remove -g @agentx/cli 2>$null | Out-Null
    if ($?) { Write-Host "  ✓ Removed global pnpm package" -ForegroundColor Green }
  }
}

function Remove-Data {
  $removed = $false

  if (Test-Path $ConfigDir) {
    Remove-Item -Recurse -Force $ConfigDir
    Write-Host "  ✓ Removed config: $ConfigDir" -ForegroundColor Green
    $removed = $true
  }

  if (Test-Path $DataDir) {
    Remove-Item -Recurse -Force $DataDir
    Write-Host "  ✓ Removed data: $DataDir" -ForegroundColor Green
    $removed = $true
  }

  if (Test-Path $CacheDir) {
    Remove-Item -Recurse -Force $CacheDir
    Write-Host "  ✓ Removed cache: $CacheDir" -ForegroundColor Green
    $removed = $true
  }

  if (-not $removed) {
    Write-Host "  ▸ No user data found (skipped)" -ForegroundColor Cyan
  }
}

function Remove-FromPath {
  $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
  $newPath = ($userPath -split ";" | Where-Object { $_ -ne $BinDir }) -join ";"
  if ($newPath -ne $userPath) {
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-Host "  ✓ Removed $BinDir from PATH" -ForegroundColor Green
  } else {
    Write-Host "  ▸ $BinDir not found in PATH (skipped)" -ForegroundColor Cyan
  }
}

Write-Host "  Initiating decommission sequence..." -ForegroundColor Cyan
Write-Host ""

Remove-Binary
Remove-Installation
Remove-GlobalPackage
Write-Host ""

if ((Test-Path $ConfigDir) -or (Test-Path $DataDir) -or (Test-Path $CacheDir)) {
  Write-Host "  Orbital debris detected:" -ForegroundColor Yellow
  if (Test-Path $ConfigDir) { Write-Host "    • Config:  $ConfigDir" }
  if (Test-Path $DataDir)   { Write-Host "    • Data:    $DataDir" }
  if (Test-Path $CacheDir)  { Write-Host "    • Cache:   $CacheDir" }
  Write-Host ""
  if ($Host.UI.RawUI) {
    $answer = Read-Host "  Scrub orbital debris (sessions, config, memories)? [y/N]"
    if ($answer -match "^[Yy]") {
      Remove-Data
    } else {
      Write-Host "  ▸ Orbital debris preserved" -ForegroundColor Cyan
    }
  } else {
    Write-Host "  ⚠ Running non-interactively — preserving orbital debris" -ForegroundColor Yellow
    Write-Host "  To also scrub debris, run: Remove-Item -Recurse -Force `"$ConfigDir`", `"$DataDir`", `"$CacheDir`"" -ForegroundColor Cyan
  }
}

Write-Host ""
Remove-FromPath
Write-Host ""

Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "  ║                                              ║" -ForegroundColor Yellow
Write-Host "  ║       DECOMMISSION COMPLETE                  ║" -ForegroundColor Yellow
Write-Host "  ║       Agent-X has left the building.         ║" -ForegroundColor Yellow
Write-Host "  ║                                              ║" -ForegroundColor Yellow
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Open a new terminal for PATH changes to take effect." -ForegroundColor DarkGray
Write-Host ""
