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

# ─── Shutdown ──────────────────────────────────────────────────────

function Stop-RunningProcesses {
  $found = $false
  $patterns = @("agentx", "daemon.js", "web-api.*index.js")

  foreach ($pattern in $patterns) {
    try {
      $procs = Get-Process | Where-Object { $_.CommandLine -match $pattern -and $_.Id -ne $pid }
      foreach ($proc in $procs) {
        $proc.Kill()
        $found = $true
      }
    } catch { }
  }

  if ($found) {
    Start-Sleep -Seconds 1
    # Force kill anything still alive
    foreach ($pattern in $patterns) {
      try {
        Get-Process | Where-Object { $_.CommandLine -match $pattern -and $_.Id -ne $pid } | ForEach-Object { $_.Kill() }
      } catch { }
    }
    Write-Host "  $([char]0x2713) Stopped all running Agent-X processes" -ForegroundColor Green
  } else {
    Write-Host "  $([char]0x25B8) No running Agent-X processes found" -ForegroundColor Cyan
  }
}

# ─── Removal Functions ─────────────────────────────────────────────

function Remove-Binary {
  $binPath = "$BinDir\agentx.cmd"
  if (Test-Path $binPath) {
    Remove-Item -Force $binPath
    Write-Host "  $([char]0x2713) Removed binary: $binPath" -ForegroundColor Green
  } else {
    Write-Host "  $([char]0x25B8) No binary found at $binPath (skipped)" -ForegroundColor Cyan
  }
}

function Remove-Installation {
  if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
    Write-Host "  $([char]0x2713) Removed installation: $InstallDir" -ForegroundColor Green
  } else {
    Write-Host "  $([char]0x25B8) No installation found at $InstallDir (skipped)" -ForegroundColor Cyan
  }
}

function Remove-GlobalPackage {
  $npm = Get-Command npm -ErrorAction SilentlyContinue
  if ($npm) {
    npm uninstall -g @agentx/cli 2>$null | Out-Null
    if ($?) { Write-Host "  $([char]0x2713) Removed global npm package" -ForegroundColor Green }
  }
  $pnpm = Get-Command pnpm -ErrorAction SilentlyContinue
  if ($pnpm) {
    pnpm remove -g @agentx/cli 2>$null | Out-Null
    if ($?) { Write-Host "  $([char]0x2713) Removed global pnpm package" -ForegroundColor Green }
  }
}

function Remove-AllData {
  $removed = $false

  # Core user directories
  if (Test-Path $ConfigDir) {
    Remove-Item -Recurse -Force $ConfigDir
    Write-Host "  $([char]0x2713) Removed config: $ConfigDir" -ForegroundColor Green
    $removed = $true
  }
  if (Test-Path $DataDir) {
    Remove-Item -Recurse -Force $DataDir
    Write-Host "  $([char]0x2713) Removed data: $DataDir" -ForegroundColor Green
    $removed = $true
  }
  if (Test-Path $CacheDir) {
    Remove-Item -Recurse -Force $CacheDir
    Write-Host "  $([char]0x2713) Removed cache: $CacheDir" -ForegroundColor Green
    $removed = $true
  }

  # Scrub lingering binary symlinks
  $localBin = "$env:USERPROFILE\.local\bin"
  if (Test-Path "$localBin\agentx")    { Remove-Item -Force "$localBin\agentx" }
  if (Test-Path "$localBin\agentx.cmd"){ Remove-Item -Force "$localBin\agentx.cmd" }

  # Clear PowerShell history entries referencing agentx
  $historyPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
  if (Test-Path $historyPath) {
    try {
      $content = Get-Content $historyPath -Raw
      $filtered = $content -split "`n" | Where-Object { $_ -notmatch 'agentx' }
      $filtered -join "`n" | Out-File $historyPath -Encoding utf8NoBOM
    } catch { }
  }

  if (-not $removed) {
    Write-Host "  $([char]0x25B8) No user data found (skipped)" -ForegroundColor Cyan
  }
}

function Remove-FromPath {
  $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
  $newPath = ($userPath -split ";" | Where-Object { $_ -ne $BinDir }) -join ";"
  if ($newPath -ne $userPath) {
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-Host "  $([char]0x2713) Removed $BinDir from PATH" -ForegroundColor Green
  } else {
    Write-Host "  $([char]0x25B8) $BinDir not found in PATH (skipped)" -ForegroundColor Cyan
  }
}

# ─── Main ───────────────────────────────────────────────────────────

$mode = "package"

if ($Host.UI.RawUI) {
  Write-Host "  What would you like to do?" -ForegroundColor White
  Write-Host ""
  Write-Host "    1) Delete Agent-X (Tool only)" -ForegroundColor White
  Write-Host "    2) Delete All (Tool + User Data)" -ForegroundColor White
  Write-Host ""
  $choice = Read-Host "  Enter choice [1/2]"
  if ($choice -match "^2|full|wipe|all$") {
    $mode = "full"
  }
  Write-Host ""
} else {
  # Non-interactive — check env var
  $mode = if ($env:AGENTX_UNINSTALL_MODE) { $env:AGENTX_UNINSTALL_MODE } else { "package" }
}

if ($mode -eq "full") {
  Write-Host "  Full wipe - removing Agent-X and all user data..." -ForegroundColor Cyan
} else {
  Write-Host "  Removing Agent-X (keeping config, credentials, and data)..." -ForegroundColor Cyan
}
Write-Host ""

Stop-RunningProcesses
Write-Host ""

Remove-Binary
Remove-Installation
Remove-GlobalPackage
Remove-FromPath
Write-Host ""

if ($mode -eq "full") {
  Write-Host "  Scrubbing all user data..." -ForegroundColor Cyan
  Remove-AllData
} else {
  Write-Host "  Preserved user data:" -ForegroundColor Cyan
  $found = $false
  if (Test-Path $ConfigDir) { Write-Host "    - Config:  $ConfigDir"; $found = $true }
  if (Test-Path $DataDir)   { Write-Host "    - Data:    $DataDir"; $found = $true }
  if (Test-Path $CacheDir)  { Write-Host "    - Cache:   $CacheDir"; $found = $true }
  if (-not $found) { Write-Host "    (none found)" }
}

Write-Host ""
Write-Host "  ** DECOMMISSION COMPLETE **" -ForegroundColor Yellow
Write-Host "  Open a new terminal for PATH changes to take effect." -ForegroundColor DarkGray
if ($mode -eq "full") {
  Write-Host "  All Agent-X artifacts have been removed from this system." -ForegroundColor DarkGray
}
Write-Host ""
