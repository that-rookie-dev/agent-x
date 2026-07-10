# Agent-X Installer for Windows — Ground Control Edition
# Usage: irm https://raw.githubusercontent.com/that-rookie-dev/agent-x/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$Repo = "that-rookie-dev/agent-x"
$InstallDir = if ($env:AGENTX_INSTALL_DIR) { $env:AGENTX_INSTALL_DIR } else { "$env:LOCALAPPDATA\agentx" }
$BinDir = if ($env:AGENTX_BIN_DIR) { $env:AGENTX_BIN_DIR } else { "$env:LOCALAPPDATA\agentx\bin" }
$RuntimeDataDir = if ($env:AGENTX_DATA_DIR) { $env:AGENTX_DATA_DIR } else { Join-Path $env:USERPROFILE ".local\share\agentx" }
$CacheDir = Join-Path $env:TEMP "agentx"
$MinNodeVersion = 20

# ─── Colours ─────────────────────────────────────────────────────────

function Write-Ground($msg) { Write-Host "  $msg" -ForegroundColor DarkGray }
function Write-Info($msg) { Write-Host "  ⏳ $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "  ✗ $msg" -ForegroundColor Red; exit 1 }
function Write-Cmd($msg) { Write-Host "  $msg" -ForegroundColor DarkGray }

# ─── Mission phrases ─────────────────────────────────────────────────

$MissionPhrases = @(
  "Calibrating orbital insertion vectors",
  "Synchronising quantum entanglement buffers",
  "Establishing neural handshake protocol",
  "Deploying phased-array telemetry array",
  "Running pre-flight diagnostic suite",
  "Engaging inertial dampeners",
  "Aligning main reflector dish",
  "Warming up magnetron spindles",
  "Initialising subspace transceiver",
  "Performing cross-check on nav computers",
  "Boosting signal gain on deep-space network",
  "Running parity check on uplink channel",
  "Calculating Lagrange point insertion burn",
  "Spooling up reaction control wheels",
  "Synchronising atomic clock array",
  "Pinging relay satellite constellation",
  "Verifying encryption handshake keys",
  "Charging capacitor banks for main bus",
  "Unfurling solar panel arrays",
  "Loading mission parameters into flight computer",
  "Cross-referencing star charts with telemetry",
  "Running final go/no-go poll",
  "Priming thruster ignition sequence",
  "Acquiring lock on navigation beacon",
  "Stabilising attitude control system",
  "Verifying life support telemetry downlink",
  "Cycling coolant through primary loop",
  "Performing burn-time calculation",
  "Calibrating star tracker against known reference",
  "Checking pressure seals on payload bay",
  "Uploading waypoint sequence to autopilot",
  "Running loopback test on comms channel"
)

function Get-MissionPhrase {
  $idx = (Get-Date).Millisecond % $MissionPhrases.Count
  return $MissionPhrases[$idx]
}

# ─── Signal meter ─────────────────────────────────────────────────────

function Show-SignalMeter {
  param([int]$level)
  $bars = ""
  1..5 | ForEach-Object {
    if ($_ -le $level) {
      $bars += "$([char]0x2588)"  # █
    } else {
      $bars += "$([char]0x2591)"  # ░
    }
  }
  $status = if ($level -le 1) { @{Color="Red"; Text="POOR"} } elseif ($level -le 3) { @{Color="Yellow"; Text="FAIR"} } else { @{Color="Green"; Text="LOCK"} }
  Write-Host "  SIG: $bars $($status.Text)" -ForegroundColor $status.Color
}

# ─── Countdown ──────────────────────────────────────────────────────

function Show-Countdown {
  Write-Host ""
  Write-Host "  T-minus:" -ForegroundColor Cyan
  3..1 | ForEach-Object {
    Write-Host "    $_ seconds to deployment..." -NoNewline -ForegroundColor DarkGray
    Start-Sleep -Seconds 1
    Write-Host "`r" -NoNewline
  }
  Write-Host "  ** LAUNCH **  All systems nominal." -ForegroundColor Green
  Start-Sleep -Milliseconds 500
}

# ─── Platform detection ─────────────────────────────────────────────

function Get-Platform {
  $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
  switch ($arch) {
    "X64" { return "win-x64" }
    "Arm64" { return "win-arm64" }
    default { Write-Err "Unsupported architecture: $arch" }
  }
}

# ─── Prerequisites ──────────────────────────────────────────────────

function Test-NodeVersion {
  $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
  if (-not $nodeCmd) {
    Write-Warn "Node.js not found. Attempting to install Node.js..."
    $choco = Get-Command choco -ErrorAction SilentlyContinue
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    $nodeInstalled = $false
    if ($choco) {
      Write-Info "Installing Node.js via Chocolatey..."
      choco install nodejs-lts -y
      $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
      if ($nodeCmd) { $nodeInstalled = $true }
    } elseif ($winget) {
      Write-Info "Installing Node.js via winget..."
      winget install OpenJS.NodeJS.LTS
      $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
      if ($nodeCmd) { $nodeInstalled = $true }
    }
    if (-not $nodeInstalled) {
      Write-Err "Node.js could not be installed automatically. Please install Node.js >= $MinNodeVersion manually:"
      Write-Host "    choco install nodejs-lts" -ForegroundColor Cyan
      Write-Host "    winget install OpenJS.NodeJS.LTS" -ForegroundColor Cyan
      Write-Host "    Or download from: https://nodejs.org/en/download" -ForegroundColor Cyan
    }
  }
  $version = (node -v) -replace '^v', ''
  $major = [int]($version.Split('.')[0])
  if ($major -lt $MinNodeVersion) {
    Write-Err "Node.js $MinNodeVersion+ required (found v$version). Upgrade: https://nodejs.org"
  }
  Write-Ok "Node.js v$version"
}

# ─── Version resolution ─────────────────────────────────────────────

function Get-LatestVersion {
  Write-Progress -Activity "Resolving latest release tag from GitHub..." -Status "downlinking" -PercentComplete -1
  $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -ErrorAction Stop
  Write-Progress -Activity "Resolving latest release tag from GitHub..." -Completed
  return $release.tag_name
}

# ─── Clean existing ─────────────────────────────────────────────────

function Stop-AgentXProcesses {
  $stopped = $false
  foreach ($proc in Get-Process node -ErrorAction SilentlyContinue) {
    try {
      $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.Id)" -ErrorAction SilentlyContinue).CommandLine
      if ($cmd -and ($cmd -match 'agentx|daemon\.js')) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        $stopped = $true
      }
    } catch { }
  }
  if ($stopped) {
    Start-Sleep -Seconds 1
  }
}

function Remove-Existing {
  Stop-AgentXProcesses

  if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
  }

  $localBin = Join-Path $env:USERPROFILE ".local\bin"
  foreach ($wrapper in @("$BinDir\agentx.cmd", "$localBin\agentx.cmd", "$localBin\agentx")) {
    if (Test-Path $wrapper) {
      Remove-Item -Force $wrapper
    }
  }

  if (Test-Path $CacheDir) {
    Remove-Item -Recurse -Force $CacheDir
  }

  # Replace the application install only. User data (config, auth, brain DB, logs)
  # under RuntimeDataDir is preserved across upgrades/reinstalls. Use uninstall.ps1 to wipe.
  $pidFile = Join-Path $RuntimeDataDir 'agentx.pid'
  if (Test-Path $pidFile) {
    Remove-Item -Force $pidFile -ErrorAction SilentlyContinue
  }

  $npm = Get-Command npm -ErrorAction SilentlyContinue
  if ($npm) {
    npm uninstall -g @agentx/cli 2>$null | Out-Null
  }
  $pnpm = Get-Command pnpm -ErrorAction SilentlyContinue
  if ($pnpm) {
    pnpm remove -g @agentx/cli 2>$null | Out-Null
  }
}

# ─── Download server payload ────────────────────────────────────────

function Format-Bytes([long]$Bytes) {
  if ($Bytes -ge 1GB) { return "{0:N1} GB" -f ($Bytes / 1GB) }
  if ($Bytes -ge 1MB) { return "{0:N1} MB" -f ($Bytes / 1MB) }
  if ($Bytes -ge 1KB) { return "{0:N0} KB" -f ($Bytes / 1KB) }
  return "$Bytes B"
}

function Get-RemoteSize([string]$Url) {
  try {
    $response = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -ErrorAction Stop
    if ($response.Headers['Content-Length']) {
      return [long]$response.Headers['Content-Length']
    }
  } catch {}
  return 0
}

function Download-WithProgress([string]$Url, [string]$Destination) {
  $maxRetries = if ($env:AGENTX_DOWNLOAD_RETRIES) { [int]$env:AGENTX_DOWNLOAD_RETRIES } else { 5 }
  $totalBytes = Get-RemoteSize $Url
  if ($totalBytes -gt 0) {
    Write-Ground "Payload size: $(Format-Bytes $totalBytes)"
  }

  $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
  if (-not $curl) {
    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
      if ($attempt -gt 1) {
        Write-Host "  ⟳ Retry $attempt/$maxRetries" -ForegroundColor Yellow
        Start-Sleep -Seconds 2
      }
      Write-Progress -Activity "Downlinking payload" -Status $Url -PercentComplete -1
      try {
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -ErrorAction Stop
        Write-Progress -Activity "Downlinking payload" -Completed
        return
      } catch {
        Write-Progress -Activity "Downlinking payload" -Completed
        if ($attempt -lt $maxRetries) {
          Write-Host "  ⚠ Download interrupted — will retry." -ForegroundColor Yellow
        }
      }
    }
    Write-Err "Download failed after $maxRetries attempts for $Url. Check your internet connection or set AGENTX_VERSION."
  }

  for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
    if ($attempt -gt 1) {
      $partial = if (Test-Path $Destination) { (Get-Item $Destination).Length } else { 0 }
      $partialLabel = if ($partial -gt 0) { " — resuming from $(Format-Bytes $partial)" } else { "" }
      Write-Host "  ⟳ Retry $attempt/$maxRetries$partialLabel" -ForegroundColor Yellow
      Start-Sleep -Seconds 2
    }

    $proc = Start-Process -FilePath $curl.Source -ArgumentList @('-fSL', '-C', '-', $Url, '-o', $Destination) -PassThru -NoNewWindow
    $lastBytes = 0
    $stalled = 0
    $failed = $false

    while (-not $proc.HasExited) {
      $currentBytes = if (Test-Path $Destination) { (Get-Item $Destination).Length } else { 0 }
      if ($totalBytes -gt 0) {
        $pct = [Math]::Min(100, [int](($currentBytes * 100) / $totalBytes))
        Write-Progress -Activity "Downlinking payload" -Status "$(Format-Bytes $currentBytes) / $(Format-Bytes $totalBytes) ($pct%)" -PercentComplete $pct
      } else {
        Write-Progress -Activity "Downlinking payload" -Status "$(Format-Bytes $currentBytes) received" -PercentComplete -1
      }

      if ($currentBytes -eq $lastBytes) {
        $stalled++
        if ($stalled -ge 150) {
          $proc | Stop-Process -Force -ErrorAction SilentlyContinue
          $failed = $true
          break
        }
      } else {
        $stalled = 0
        $lastBytes = $currentBytes
      }
      Start-Sleep -Milliseconds 200
    }

    Write-Progress -Activity "Downlinking payload" -Completed

    if (-not $failed -and $proc.ExitCode -eq 0) {
      $finalBytes = if (Test-Path $Destination) { (Get-Item $Destination).Length } else { 0 }
      if ($finalBytes -gt 0 -and ($totalBytes -le 0 -or $finalBytes -ge $totalBytes)) {
        return
      }
      $failed = $true
    }

    if ($attempt -lt $maxRetries) {
      if ($failed) {
        Write-Host "  ⚠ Download interrupted — will resume if connection returns." -ForegroundColor Yellow
      }
    }
  }

  Write-Err "Download failed after $maxRetries attempts for $Url. Check your internet connection or set AGENTX_VERSION."
}

function Install-AgentX {
  $platform = Get-Platform
  if ($platform -ne "win-x64") {
    Write-Err "Server install is only available for win-x64 (found $platform)."
  }
  $version = Get-LatestVersion
  Write-Ok "Latest release: $version"
  Write-Ground "Telemetry: $platform | Node $(node -v) | $version"
  Write-Ground "Payload: Server (headless Web UI)"

  $url = "https://github.com/$Repo/releases/download/$version/agentx-$platform-server.tar.gz"
  $tmpFile = Join-Path $env:TEMP "agentx-$platform-server.tar.gz"

  Write-Cmd "Downlinking from: $url"

  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

  Download-WithProgress -Url $url -Destination $tmpFile

  if (-not (Test-Path $tmpFile) -or (Get-Item $tmpFile).Length -eq 0) {
    Write-Err "Download failed. Check your internet connection."
  }

  Write-Ok "Payload Received"

  $header = Get-Content -Path $tmpFile -Encoding Byte -TotalCount 2
  if ($header[0] -ne 0x1f -or $header[1] -ne 0x8b) {
    Write-Err "Downloaded file is not a valid server package (expected gzip). Asset may be missing for $platform in $version."
  }

  Write-Cmd "Unpacking payload..."
  tar -xzf $tmpFile -C $InstallDir
  Remove-Item $tmpFile -Force

  New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
  if (Test-Path "$InstallDir\agentx.cmd") {
    Copy-Item "$InstallDir\agentx.cmd" "$BinDir\agentx.cmd" -Force
  } else {
    $cmdContent = "@echo off`r`nnode `"$InstallDir\index.js`" %*"
    Set-Content -Path "$BinDir\agentx.cmd" -Value $cmdContent -Encoding ASCII
  }

  Write-Ok "Payload extracted to $InstallDir"
}

# ─── PATH management ────────────────────────────────────────────────

function Add-ToPath {
  if (-not (Test-Path "$BinDir\agentx.cmd")) {
    Write-Err "CLI wrapper missing at $BinDir\agentx.cmd"
  }

  $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
  if (-not ($userPath -split ";" | Where-Object { $_ -eq $BinDir })) {
    [Environment]::SetEnvironmentVariable("PATH", "$BinDir;$userPath", "User")
    Write-Ok "Added $BinDir to user PATH"
  }

  Write-Ok "CLI available at $BinDir\agentx.cmd"
}

function Print-ActivationInstructions {
  Write-Host ""
  Write-Host "  Activate the agentx command" -ForegroundColor Cyan
  Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
  Write-Host "  Note: If you installed via irm | iex, reload PATH in this window:" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "    `$env:PATH = [Environment]::GetEnvironmentVariable('PATH','User')" -ForegroundColor White
  Write-Host "    # or open a new terminal" -ForegroundColor DarkGray
  Write-Host ""
  Write-Host "  Or run directly without updating PATH:" -ForegroundColor DarkGray
  Write-Host "    $BinDir\agentx.cmd start" -ForegroundColor White
  Write-Host ""
}

# ─── Verify ─────────────────────────────────────────────────────────

function Test-Installation {
  if ((Test-Path "$InstallDir\index.js") -and (Test-Path "$BinDir\agentx.cmd")) {
    Write-Ok "Payload integrity verified"
  } else {
    Write-Err "Installation failed - payload integrity check failed"
  }
}

# ─── Install Tesseract OCR (image text extraction; PDFs use bundled pdf.js) ──

function Install-OptionalDeps {
  $tesseract = Get-Command tesseract -ErrorAction SilentlyContinue
  if ($tesseract) {
    Write-Ok "Tesseract OCR already available"
    return
  }

  $choco = Get-Command choco -ErrorAction SilentlyContinue
  $winget = Get-Command winget -ErrorAction SilentlyContinue

  if ($choco) {
    Write-Info "Installing Tesseract OCR via Chocolatey..."
    choco install tesseract -y 2>$null | Out-Null
    if ($?) { Write-Ok "Tesseract OCR installed"; return }
  }
  if ($winget) {
    Write-Info "Installing Tesseract OCR via winget..."
    winget install UB-Mannheim.TesseractOCR --silent 2>$null | Out-Null
    if ($?) { Write-Ok "Tesseract OCR installed"; return }
  }

  Write-Warn "Tesseract OCR not installed"
  Write-Host "    PDFs and text files work without OCR; Tesseract is for image text extraction (screenshots, photos, scanned images)." -ForegroundColor DarkGray
  Write-Host "    Install manually: choco install tesseract  OR  winget install UB-Mannheim.TesseractOCR" -ForegroundColor DarkGray
}

# ─── Animated step runner ───────────────────────────────────────────

function Run-Step($msg, [ScriptBlock]$block) {
  Write-Progress -Activity $msg -Status "$(Get-MissionPhrase)" -PercentComplete -1
  try {
    & $block
    Write-Progress -Activity $msg -Completed
    Write-Ok $msg
  } catch {
    Write-Progress -Activity $msg -Completed
    Write-Err "$msg failed: $_"
  }
}

# ─── Main ───────────────────────────────────────────────────────────

Clear-Host
Write-Host ""
Write-Host "  MISSION CONTROL • AGENT-X DEPLOYMENT" -ForegroundColor Cyan
Write-Host "  ------------------------------------" -ForegroundColor DarkGray
Show-SignalMeter -level (Get-Random -Minimum 3 -Maximum 6)
Write-Host "  STAT: PRE-LAUNCH" -ForegroundColor Cyan
Write-Host "  T+$([DateTimeOffset]::Now.ToUnixTimeSeconds()): $(Get-Date -Format 'HH:mm:ss UTC')" -ForegroundColor DarkGray
Write-Host ""

Run-Step "Running pre-flight diagnostics" {
  Test-NodeVersion
}

Run-Step "Clearing previous installation artifacts" {
  Remove-Existing
}

Show-Countdown

Install-AgentX

Run-Step "Locking navigation coordinates" {
  Add-ToPath
}

Run-Step "Running payload integrity check" {
  Test-Installation
}

Run-Step "Installing Tesseract OCR (image text extraction)" {
  Install-OptionalDeps
}

Print-ActivationInstructions

Write-Host ""
Write-Host "  ** DEPLOYMENT COMPLETE **" -ForegroundColor Green
Write-Host "  Agent-X server is now operational." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Payload:     Server (Web UI)" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Engage:      agentx start"
Write-Host "  Status:      agentx status"
Write-Host "  Stop:        agentx stop"
Write-Host "  Web UI:      http://127.0.0.1:3333"
Write-Host "  Help:        agentx --help"
Write-Host ""
