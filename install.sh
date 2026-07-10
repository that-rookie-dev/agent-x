#!/usr/bin/env bash
set -euo pipefail

# Agent-X Installer — Ground Control Edition
# Usage: curl -fsSL https://raw.githubusercontent.com/that-rookie-dev/agent-x/main/install.sh | bash

REPO="that-rookie-dev/agent-x"
INSTALL_DIR="${AGENTX_INSTALL_DIR:-$HOME/.agentx}"
BIN_DIR="${AGENTX_BIN_DIR:-$HOME/.local/bin}"
DATA_DIR="${AGENTX_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/agentx}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/agentx"
VERSION="${AGENTX_VERSION:-latest}"
MIN_NODE_VERSION=20
LOG_FILE="${INSTALL_DIR}/install.log"

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Animated spinner ─────────────────────────────────────────────────

SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
BRAILLE_FRAMES=('⣀' '⣄' '⣤' '⣦' '⣶' '⣷' '⣿' '⣷' '⣶' '⣦' '⣤' '⣄')
SPINNER_PID=""

start_spinner() {
  local msg="$1"
  (
    local i=0
    while true; do
      printf "\r  ${CYAN}${SPINNER_FRAMES[$((i % ${#SPINNER_FRAMES[@]}))]}${NC} ${msg}" >&2
      i=$((i + 1))
      sleep 0.08
    done
  ) &
  SPINNER_PID=$!
}

stop_spinner() {
  local success="${1:-true}"
  local msg="$2"
  if [ -n "$SPINNER_PID" ]; then
    kill "$SPINNER_PID" 2>/dev/null || true
    wait "$SPINNER_PID" 2>/dev/null || true
    SPINNER_PID=""
  fi
  if [ "$success" = "true" ]; then
    printf "\r  ${GREEN}✓${NC} ${msg}\033[K\n" >&2
  else
    printf "\r  ${RED}✗${NC} ${msg}\033[K\n" >&2
  fi
}

# ─── Animated progress bar (indeterminate) ────────────────────────────

PROGRESS_PID=""

start_progress() {
  local msg="$1"
  (
    local chars=('▱' '▱' '▱' '▱' '▱' '▰' '▰' '▰' '▰' '▰')
    local i=0
    while true; do
      local bar=""
      for j in {0..4}; do
        pos=$(( (i + j) % ${#chars[@]} ))
        bar="${bar}${chars[$pos]}"
      done
      local braile_idx=$(( i % ${#BRAILLE_FRAMES[@]} ))
      printf "\r  ${CYAN}${BRAILLE_FRAMES[$braile_idx]}${NC} ${msg} ${DIM}[${bar}]${NC}" >&2
      i=$((i + 1))
      sleep 0.15
    done
  ) &
  PROGRESS_PID=$!
}

stop_progress() {
  local success="${1:-true}"
  local msg="$2"
  if [ -n "$PROGRESS_PID" ]; then
    kill "$PROGRESS_PID" 2>/dev/null || true
    wait "$PROGRESS_PID" 2>/dev/null || true
    PROGRESS_PID=""
  fi
  if [ "$success" = "true" ]; then
    printf "\r  ${GREEN}✓${NC} ${msg}\033[K\n" >&2
  else
    printf "\r  ${RED}✗${NC} ${msg}\033[K\n" >&2
  fi
}

# ─── Rotating mission phrases ────────────────────────────────────────

MISSION_IDX=0
MISSION_PHRASES=(
  "Calibrating orbital insertion vectors"
  "Synchronising quantum entanglement buffers"
  "Establishing neural handshake protocol"
  "Deploying phased-array telemetry array"
  "Running pre-flight diagnostic suite"
  "Engaging inertial dampeners"
  "Aligning main reflector dish"
  "Warming up magnetron spindles"
  "Initialising subspace transceiver"
  "Performing cross-check on nav computers"
  "Boosting signal gain on deep-space network"
  "Running parity check on uplink channel"
  "Calculating Lagrange point insertion burn"
  "Spooling up reaction control wheels"
  "Synchronising atomic clock array"
  "Pinging relay satellite constellation"
  "Verifying encryption handshake keys"
  "Charging capacitor banks for main bus"
  "Unfurling solar panel arrays"
  "Loading mission parameters into flight computer"
  "Cross-referencing star charts with telemetry"
  "Running final go/no-go poll"
  "Priming thruster ignition sequence"
  "Acquiring lock on navigation beacon"
  "Stabilising attitude control system"
  "Verifying life support telemetry downlink"
  "Cycling coolant through primary loop"
  "Performing burn-time calculation"
  "Calibrating star tracker against known reference"
  "Checking pressure seals on payload bay"
  "Uploading waypoint sequence to autopilot"
  "Running loopback test on comms channel"
)

get_phrase() {
  MISSION_IDX=$(( (MISSION_IDX + 1) % ${#MISSION_PHRASES[@]} ))
  echo "${MISSION_PHRASES[$MISSION_IDX]}"
}

mission_phrase() {
  local phrase
  phrase=$(get_phrase)
  printf "  ${DIM}⟡ ${phrase}...${NC}"
}



# ─── Signal meter ────────────────────────────────────────────────────

signal_meter() {
  local level="${1:-0}"
  local bars=""
  for i in {1..5}; do
    if [ "$i" -le "$level" ]; then
      bars="${bars}${GREEN}█${NC}"
    else
      bars="${bars}${DIM}░${NC}"
    fi
  done
  case "$level" in
    0|1) printf "  ${DIM}SIG:${NC} ${bars} ${RED}POOR${NC}" ;;
    2|3) printf "  ${DIM}SIG:${NC} ${bars} ${YELLOW}FAIR${NC}" ;;
    4|5) printf "  ${DIM}SIG:${NC} ${bars} ${GREEN}LOCK${NC}" ;;
  esac
}

# ─── Telemetry header ────────────────────────────────────────────────

telemetry_header() {
  local phase="$1"
  printf "\n"
  printf "  ${CYAN}MISSION CONTROL${NC} ${DIM}•${NC} ${BOLD}AGENT-X DEPLOYMENT${NC}\n"
  printf "  ${DIM}───────────────────────────────────────────────────${NC}\n"
  printf "$(signal_meter $(( RANDOM % 3 + 3 )))\n"
  printf "  ${DIM}STAT:${NC} ${CYAN}${phase}${NC}\n"
  printf "  ${DIM}T+$(date +%s):${NC} $(date '+%H:%M:%S UTC')\n"
  printf "\n"
}

# ─── Countdown ───────────────────────────────────────────────────────

countdown() {
  local secs=3
  printf "\n"
  printf "  ${CYAN}T-minus:${NC}\n"
  while [ "$secs" -gt 0 ]; do
    printf "\r  ${BOLD}${secs}${NC}  ${DIM}seconds to deployment...${NC}" >&2
    sleep 1
    secs=$((secs - 1))
  done
  printf "\r  ${GREEN}LAUNCH${NC}  ${DIM}All systems nominal.${NC}\n"
  sleep 0.5
}

# ─── Errors / interrupts ─────────────────────────────────────────────

INSTALL_COMPLETE=0
INSTALL_ABORT_REASON=""
TMPDIR_INSTALL=""
CURL_PID=""

cleanup_animations() {
  stop_spinner "false" "" 2>/dev/null || true
  stop_progress "false" "" 2>/dev/null || true
}

ignore_failure_unless_interrupted() {
  local rc=$?
  if [ "$rc" -eq 130 ] || [ "$rc" -eq 143 ]; then
    exit "$rc"
  fi
  return 0
}

handle_interrupt() {
  INSTALL_ABORT_REASON="interrupt"
  cleanup_animations
  if [ -n "$CURL_PID" ]; then
    kill "$CURL_PID" 2>/dev/null || true
  fi
  exit 130
}

handle_exit() {
  local code=$?
  cleanup_animations

  if [ -n "$CURL_PID" ]; then
    kill "$CURL_PID" 2>/dev/null || true
    wait "$CURL_PID" 2>/dev/null || true
    CURL_PID=""
  fi

  if [ -n "$TMPDIR_INSTALL" ]; then
    rm -rf "$TMPDIR_INSTALL" 2>/dev/null || true
  fi

  if [ "$INSTALL_COMPLETE" -eq 1 ]; then
    return 0
  fi

  if [ "$INSTALL_ABORT_REASON" = "error" ]; then
    return "$code"
  fi

  if [ "$INSTALL_ABORT_REASON" = "interrupt" ] || [ "$code" -eq 130 ] || [ "$code" -eq 143 ]; then
    printf "\n  ${YELLOW}⚠  DEPLOYMENT INTERRUPTED${NC}\n" >&2
    printf "  ${DIM}Installation was cancelled before completion.${NC}\n" >&2
    if [ -f "$LOG_FILE" ]; then
      printf "  ${DIM}Telemetry log: %s${NC}\n" "$LOG_FILE" >&2
    fi
    printf "  ${DIM}Re-run the installer to try again.${NC}\n\n" >&2
  fi

  return "$code"
}

trap handle_interrupt INT TERM
trap handle_exit EXIT

die() {
  INSTALL_ABORT_REASON="error"
  stop_spinner "false" "$1" 2>/dev/null || true
  stop_progress "false" "$1" 2>/dev/null || true
  printf "\n  ${RED}⚠  MISSION ABORT${NC}\n" >&2
  printf "  ${RED}${1}${NC}\n" >&2
  if [ -f "$LOG_FILE" ]; then
    printf "  ${DIM}Full telemetry log: %s${NC}\n" "$LOG_FILE" >&2
  fi
  printf "\n" >&2
  exit 1
}

# ─── Platform detection ──────────────────────────────────────────────

detect_platform() {
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"

  case "$os" in
    linux)  OS="linux" ;;
    darwin) OS="darwin" ;;
    *)      die "Unsupported OS: $os" ;;
  esac

  case "$arch" in
    x86_64|amd64)  ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *)             die "Unsupported architecture: $arch" ;;
  esac

  PLATFORM="${OS}-${ARCH}"
}

# ─── Pre-requisite checks ────────────────────────────────────────────

check_command() {
  command -v "$1" >/dev/null 2>&1
}

check_node() {
  if ! check_command node; then
    printf "  ${YELLOW}Node.js is required but not found.${NC}\n" >&2
    printf "  Attempting to install Node.js now...\n"
    local installed=false
    if [ "$OS" = "darwin" ]; then
      if check_command brew; then
        brew install node && installed=true
      fi
    elif [ "$OS" = "linux" ]; then
      if check_command apt-get; then
        if can_sudo_noninteractive; then
          sudo -n apt-get update && sudo -n apt-get install -y nodejs npm && installed=true
        elif has_install_tty; then
          prompt_sudo_password "Node.js installation"
          sudo apt-get update </dev/tty >/dev/tty 2>&1 && \
            sudo apt-get install -y nodejs npm </dev/tty >/dev/tty 2>&1 && installed=true
        fi
      elif check_command dnf; then
        if can_sudo_noninteractive; then
          sudo -n dnf install -y nodejs && installed=true
        elif has_install_tty; then
          prompt_sudo_password "Node.js installation"
          sudo dnf install -y nodejs </dev/tty >/dev/tty 2>&1 && installed=true
        fi
      elif check_command pacman; then
        if can_sudo_noninteractive; then
          sudo -n pacman -S --noconfirm nodejs npm && installed=true
        elif has_install_tty; then
          prompt_sudo_password "Node.js installation"
          sudo pacman -S --noconfirm nodejs npm </dev/tty >/dev/tty 2>&1 && installed=true
        fi
      fi
    fi
    if ! $installed && ! check_command node; then
      printf "\n  ${RED}Node.js could not be installed automatically.${NC}\n" >&2
      if [ "$OS" = "darwin" ]; then
        printf "  Please install Node.js (v${MIN_NODE_VERSION}+) manually:\n"
        printf "    ${CYAN}brew install node${NC}\n"
        printf "    Or download from: https://nodejs.org/en/download${NC}\n"
      elif [ "$OS" = "linux" ]; then
        printf "  Please install Node.js (v${MIN_NODE_VERSION}+) manually.\n"
        printf "    ${CYAN}sudo apt-get install -y nodejs npm${NC}  (Debian/Ubuntu)\n"
        printf "    ${CYAN}sudo dnf install -y nodejs${NC}         (Fedora)\n"
        printf "    ${CYAN}sudo pacman -S nodejs npm${NC}          (Arch)\n"
        printf "    Or download from: https://nodejs.org/en/download${NC}\n"
      fi
      die "Node.js is required. Please install it and re-run this script."
    fi
  fi
  local node_major
  node_major=$(node -v | sed 's/^v//' | cut -d. -f1)
  if [ "$node_major" -lt "$MIN_NODE_VERSION" ]; then
    die "Node.js ${MIN_NODE_VERSION}+ required (found $(node -v)). Upgrade: https://nodejs.org"
  fi
}

check_curl() {
  if ! check_command curl; then
    die "curl is required. Install curl first."
  fi
}

# ─── Privileged command helpers ───────────────────────────────────────

has_install_tty() {
  [ -e /dev/tty ]
}

can_sudo_noninteractive() {
  command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null
}

prompt_sudo_password() {
  local description="$1"
  printf "\n" >&2
  printf "  ${YELLOW}Administrator access required${NC} — %s\n" "$description" >&2
  printf "  ${DIM}Enter your password when prompted below.${NC}\n" >&2
  printf "\n" >&2
}

run_with_sudo() {
  local description="$1"
  shift

  if ! command -v sudo >/dev/null 2>&1; then
    return 1
  fi

  if can_sudo_noninteractive; then
    sudo -n "$@"
    return $?
  fi

  if ! has_install_tty; then
    return 1
  fi

  prompt_sudo_password "$description"
  sudo "$@" </dev/tty >/dev/tty 2>&1
}

# ─── Version resolution ──────────────────────────────────────────────

get_version() {
  if [ "$VERSION" = "latest" ]; then
    start_progress "Resolving latest release tag from GitHub..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null \
      | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    stop_progress "true" "Latest release: ${VERSION}"
    if [ -z "$VERSION" ]; then
      die "Failed to determine latest version. Check your internet connection."
    fi
  fi
}

# ─── Clean existing installation ─────────────────────────────────────

stop_running_agentx() {
  if [ -f "${DATA_DIR}/agentx.pid" ]; then
    local pid
    pid="$(cat "${DATA_DIR}/agentx.pid" 2>/dev/null || true)"
    if [ -n "$pid" ] && [ "$pid" != "$$" ]; then
      kill "$pid" 2>/dev/null || true
      sleep 1
      kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "${DATA_DIR}/agentx.pid"
  fi

  local found=false
  local patterns=("${INSTALL_DIR}/index.js" "${INSTALL_DIR}/agentx")

  for pattern in "${patterns[@]}"; do
    local pids
    pids=$(pgrep -f "$pattern" 2>/dev/null || true)
    if [ -n "$pids" ]; then
      found=true
      for pid in $pids; do
        [ "$pid" = "$$" ] && continue
        kill "$pid" 2>/dev/null || true
      done
    fi
  done

  if [ "$found" = true ]; then
    sleep 1
    for pattern in "${patterns[@]}"; do
      pkill -9 -f "$pattern" 2>/dev/null || true
    done
  fi
}

clean_existing() {
  stop_running_agentx

  # Replace the application install only. User data (config, auth, brain DB, logs)
  # under DATA_DIR is preserved across upgrades/reinstalls. Use uninstall.sh for a wipe.
  if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
  fi

  if [ -e "$BIN_DIR/agentx" ]; then
    rm -f "$BIN_DIR/agentx"
  fi
  if [ -e "$BIN_DIR/agentx.cmd" ]; then
    rm -f "$BIN_DIR/agentx.cmd"
  fi

  if [ -d "$CACHE_DIR" ]; then
    rm -rf "$CACHE_DIR"
  fi

  # Drop a stale pid file if present; leave the rest of DATA_DIR intact.
  rm -f "${DATA_DIR}/agentx.pid" 2>/dev/null || true

  if check_command agentx; then
    local existing_path
    existing_path=$(command -v agentx)
    if [[ "$existing_path" == *"node_modules"* ]] || [[ "$existing_path" == *"npm"* ]]; then
      npm uninstall -g @agentx/cli >/dev/null 2>&1 || true
      pnpm remove -g @agentx/cli >/dev/null 2>&1 || true
    fi
  fi
}

# ─── Download server payload ─────────────────────────────────────────

file_size_bytes() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo 0
    return
  fi
  if stat -c%s "$path" >/dev/null 2>&1; then
    stat -c%s "$path"
  else
    stat -f%z "$path"
  fi
}

format_bytes() {
  local bytes="$1"
  local whole rem
  if [ "$bytes" -ge 1073741824 ]; then
    whole=$((bytes / 1073741824))
    rem=$(((bytes % 1073741824) * 10 / 1073741824))
    printf "%d.%d GB" "$whole" "$rem"
  elif [ "$bytes" -ge 1048576 ]; then
    whole=$((bytes / 1048576))
    rem=$(((bytes % 1048576) * 10 / 1048576))
    printf "%d.%d MB" "$whole" "$rem"
  elif [ "$bytes" -ge 1024 ]; then
    printf "%d KB" $((bytes / 1024))
  else
    printf "%d B" "$bytes"
  fi
}

get_remote_size() {
  local url="$1"
  curl -fsSLI "$url" 2>/dev/null \
    | awk 'tolower($1)=="content-length:" {size=$2} END {gsub(/\r/, "", size); print size+0}'
}

render_download_progress() {
  local current="$1"
  local total="$2"
  local width=20
  local bar=""
  local status=""

  if [ "$total" -gt 0 ] 2>/dev/null; then
    local pct=$((current * 100 / total))
    if [ "$pct" -gt 100 ]; then pct=100; fi
    local filled=$((pct * width / 100))
    local empty=$((width - filled))
    for ((i=0; i<filled; i++)); do bar="${bar}${CYAN}█${NC}"; done
    for ((i=0; i<empty; i++)); do bar="${bar}${DIM}░${NC}"; done
    status="$(format_bytes "$current") / $(format_bytes "$total") (${pct}%)"
    printf "\r  ${DIM}RX:${NC} [${bar}] ${BOLD}%3d%%${NC} %s\033[K" "$pct" "$status" >&2
  else
    local pulse=$((current / 1048576 % width))
    for ((i=0; i<width; i++)); do
      if [ "$i" -eq "$pulse" ]; then
        bar="${bar}${CYAN}█${NC}"
      else
        bar="${bar}${DIM}░${NC}"
      fi
    done
    status="$(format_bytes "$current") received"
    printf "\r  ${DIM}RX:${NC} [${bar}] %s\033[K" "$status" >&2
  fi
}

MAX_DOWNLOAD_RETRIES="${AGENTX_DOWNLOAD_RETRIES:-5}"

# Download with resume (-C -) and retries when the link drops or stalls.
run_curl_download() {
  local url="$1"
  local dest_file="$2"
  local total_bytes="$3"
  local exit_code=0

  curl -fSL -C - "$url" -o "$dest_file" >/dev/null 2>&1 &
  CURL_PID=$!
  local curl_pid=$CURL_PID
  local last_bytes=0
  local stalled=0

  while kill -0 "$curl_pid" 2>/dev/null; do
    local current_bytes
    current_bytes="$(file_size_bytes "$dest_file")"
    render_download_progress "$current_bytes" "$total_bytes"

    if [ "$current_bytes" -eq "$last_bytes" ]; then
      stalled=$((stalled + 1))
    else
      stalled=0
      last_bytes="$current_bytes"
    fi

    if [ "$stalled" -ge 150 ]; then
      kill "$curl_pid" 2>/dev/null || true
      wait "$curl_pid" 2>/dev/null || true
      CURL_PID=""
      printf "\n" >&2
      return 2
    fi

    sleep 0.2
  done

  if ! wait "$curl_pid"; then
    exit_code=$?
    CURL_PID=""
    printf "\n" >&2
    return 1
  fi
  CURL_PID=""

  local final_bytes
  final_bytes="$(file_size_bytes "$dest_file")"
  render_download_progress "$final_bytes" "$total_bytes"
  printf "\n" >&2

  if [ ! -s "$dest_file" ]; then
    return 1
  fi

  if [ "$total_bytes" -gt 0 ] 2>/dev/null && [ "$final_bytes" -lt "$total_bytes" ]; then
    return 1
  fi

  if ! gzip -t "$dest_file" 2>/dev/null; then
    return 1
  fi

  return 0
}

download_and_install() {
  local url="https://github.com/${REPO}/releases/download/${VERSION}/agentx-${PLATFORM}-server.tar.gz"
  local dest_file=""
  TMPDIR_INSTALL="$(mktemp -d)"
  dest_file="${TMPDIR_INSTALL}/agentx.tar.gz"

  printf "  ${DIM}Downlinking from:${NC} ${CYAN}%s${NC}\n" "$url"
  mkdir -p "$INSTALL_DIR"

  local total_bytes
  total_bytes="$(get_remote_size "$url")"
  if [ "$total_bytes" -gt 0 ] 2>/dev/null; then
    printf "  ${DIM}Payload size:${NC} $(format_bytes "$total_bytes")\n"
  fi

  local attempt=1
  local rc=1
  while [ "$attempt" -le "$MAX_DOWNLOAD_RETRIES" ]; do
    if [ "$attempt" -gt 1 ]; then
      local partial_bytes
      partial_bytes="$(file_size_bytes "$dest_file")"
      printf "  ${YELLOW}⟳${NC} Retry ${attempt}/${MAX_DOWNLOAD_RETRIES}"
      if [ "$partial_bytes" -gt 0 ] 2>/dev/null; then
        printf " — resuming from $(format_bytes "$partial_bytes")"
      fi
      printf "\n"
      sleep 2
    fi

    run_curl_download "$url" "$dest_file" "$total_bytes"
    rc=$?
    if [ "$rc" -eq 0 ]; then
      break
    fi

    if [ "$rc" -eq 2 ]; then
      printf "  ${YELLOW}⚠${NC}  Download stalled — will resume if connection returns.\n" >&2
    else
      printf "  ${YELLOW}⚠${NC}  Download interrupted — will resume if connection returns.\n" >&2
    fi
    attempt=$((attempt + 1))
  done

  if [ "$rc" -ne 0 ]; then
    die "Download failed after ${MAX_DOWNLOAD_RETRIES} attempts for ${url}. Check your internet connection or try AGENTX_VERSION=<tag>."
  fi

  printf "  ${GREEN}✓${NC} ${GREEN}Payload Received${NC}\n"
  printf "  ${DIM}Unpacking payload...${NC}\n"
  tar -xzf "$dest_file" -C "$INSTALL_DIR"
  printf "  ${GREEN}✓${NC} Payload extracted to ${CYAN}%s${NC}\n" "$INSTALL_DIR"
  repair_bundled_python_symlinks
}

# Older release tarballs shipped absolute CI symlinks for python3 → /Users/runner/...
# Rewrite them to relative links against the real python3.12 binary in the same bin/.
repair_bundled_python_symlinks() {
  local bin_dir="${INSTALL_DIR}/resources/python/bin"
  local real_py=""
  local name tgt

  [ -d "$bin_dir" ] || return 0

  if [ -x "${bin_dir}/python3.12" ]; then
    real_py="python3.12"
  elif [ -x "${bin_dir}/python3.11" ]; then
    real_py="python3.11"
  elif [ -x "${bin_dir}/python3.13" ]; then
    real_py="python3.13"
  else
    return 0
  fi

  for name in python python3 python3-config 2to3 idle3 pydoc3; do
    if [ -L "${bin_dir}/${name}" ]; then
      tgt="$(readlink "${bin_dir}/${name}" 2>/dev/null || true)"
      case "$tgt" in
        /*)
          rm -f "${bin_dir}/${name}"
          ;;
      esac
    fi
  done

  if [ ! -e "${bin_dir}/python3" ]; then
    ln -sf "$real_py" "${bin_dir}/python3"
  fi
  if [ ! -e "${bin_dir}/python" ]; then
    ln -sf "$real_py" "${bin_dir}/python"
  fi
  if [ -e "${bin_dir}/${real_py}-config" ] && [ ! -e "${bin_dir}/python3-config" ]; then
    ln -sf "${real_py}-config" "${bin_dir}/python3-config"
  fi

  if "${bin_dir}/python3" --version >/dev/null 2>&1; then
    printf "  ${GREEN}✓${NC} Bundled Python ready (${CYAN}%s${NC})\n" "$("${bin_dir}/python3" --version 2>&1 | tr -d '\r')"
  else
    printf "  ${YELLOW}⚠${NC}  Bundled Python present but not executable — voice setup may need a system python3\n"
  fi
}

# ─── Rebuild native modules ──────────────────────────────────────────

rebuild_native() {
  mkdir -p "$(dirname "$LOG_FILE")"
  cd "$INSTALL_DIR"
  if [ -f package.json ] && grep -q 'better-sqlite3' package.json 2>/dev/null; then
    npm install --omit=dev --ignore-scripts >> "$LOG_FILE" 2>&1 || ignore_failure_unless_interrupted
    npx --yes node-gyp rebuild --directory=node_modules/better-sqlite3 >> "$LOG_FILE" 2>&1 || \
      npm rebuild better-sqlite3 >> "$LOG_FILE" 2>&1 || ignore_failure_unless_interrupted
    if [ -f node_modules/better-sqlite3/build/Release/better_sqlite3.node ]; then
      mkdir -p build/Release
      cp node_modules/better-sqlite3/build/Release/better_sqlite3.node build/Release/
    elif [ -f "node_modules/better-sqlite3/prebuilds/$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)/node.napi.node" ]; then
      mkdir -p build/Release
      cp "node_modules/better-sqlite3/prebuilds/$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)/node.napi.node" build/Release/better_sqlite3.node
    fi
  fi
  cd - >/dev/null
}

create_symlink() {
  mkdir -p "$BIN_DIR"

  cat > "$BIN_DIR/agentx" << EOF
#!/usr/bin/env bash
exec "$INSTALL_DIR/agentx" "\$@"
EOF
  chmod +x "$BIN_DIR/agentx"
}

shell_profile_for_path() {
  case "$(basename "${SHELL:-bash}")" in
    zsh)  printf '%s\n' "$HOME/.zshrc" ;;
    bash) printf '%s\n' "$HOME/.bashrc" "$HOME/.profile" ;;
    fish) printf '%s\n' "$HOME/.config/fish/config.fish" ;;
    *)    printf '%s\n' "$HOME/.profile" ;;
  esac
}

append_path_to_profile() {
  local profile="$1"
  [ -n "$profile" ] || return 0
  if [ ! -f "$profile" ]; then
    touch "$profile"
  fi
  if grep -q "# Agent-X" "$profile" 2>/dev/null; then
    return 0
  fi

  case "$(basename "$profile")" in
    config.fish)
      {
        printf '\n# Agent-X\n'
        printf 'fish_add_path "%s"\n' "$BIN_DIR"
      } >> "$profile"
      ;;
    *)
      {
        printf '\n# Agent-X\n'
        printf 'export PATH="%s:$PATH"\n' "$BIN_DIR"
      } >> "$profile"
      ;;
  esac
  printf "  ${DIM}Added %s to PATH via %s${NC}\n" "$BIN_DIR" "$profile"
}

is_piped_install() {
  [ ! -t 1 ]
}

ensure_path() {
  if [ ! -x "$BIN_DIR/agentx" ]; then
    die "CLI wrapper missing at $BIN_DIR/agentx"
  fi

  local profile
  while IFS= read -r profile; do
    append_path_to_profile "$profile"
  done < <(shell_profile_for_path)

  printf "  ${GREEN}✓${NC} CLI available at ${CYAN}%s${NC}\n" "$BIN_DIR/agentx"
}

print_activation_instructions() {
  echo ""
  printf "  ${CYAN}Activate the agentx command${NC}\n"
  printf "  ${DIM}──────────────────────────────────────────────────${NC}\n"

  if is_piped_install; then
    printf "  ${YELLOW}Note:${NC} This installer ran via ${DIM}curl | bash${NC}, so your current shell\n"
    printf "  was not updated automatically. Run one of the following:\n"
    echo ""
  fi

  printf "    ${BOLD}export PATH=\"%s:\$PATH\"${NC}\n" "$BIN_DIR"
  printf "    ${DIM}# or${NC}\n"
  printf "    ${BOLD}source ~/.bashrc${NC}   ${DIM}(if you use bash)${NC}\n"
  echo ""
  printf "  ${DIM}You can also run the CLI directly without updating PATH:${NC}\n"
  printf "    ${BOLD}%s/agentx start${NC}\n" "$BIN_DIR"
  echo ""
}

# ─── Verify ──────────────────────────────────────────────────────────

verify_install() {
  if [ ! -f "$INSTALL_DIR/index.js" ] || [ ! -x "$INSTALL_DIR/agentx" ]; then
    die "Installation failed — payload integrity check failed in $INSTALL_DIR"
  fi
  if [ ! -x "$BIN_DIR/agentx" ]; then
    die "Installation failed — CLI wrapper missing at $BIN_DIR/agentx"
  fi
}

# ─── Install Tesseract OCR (image text extraction; PDFs use bundled pdf.js) ──

OCR_SCOPE_MSG="PDFs and text files work without OCR; Tesseract is for image text extraction (screenshots, photos, scanned images)."

install_tesseract_macos() {
  if ! check_command brew; then
    printf "  ${YELLOW}⚠${NC}  Tesseract OCR not installed (Homebrew not found)\n"
    printf "  ${DIM}  %s${NC}\n" "$OCR_SCOPE_MSG"
    printf "  ${DIM}  Install manually: brew install tesseract${NC}\n"
    return 0
  fi

  printf "  ${DIM}Installing Tesseract OCR via Homebrew…${NC}\n"
  if HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install tesseract >>"$LOG_FILE" 2>&1; then
    printf "  ${GREEN}✓${NC} Tesseract OCR installed\n"
    return 0
  fi

  printf "  ${YELLOW}⚠${NC}  Tesseract OCR install via Homebrew did not complete\n"
  printf "  ${DIM}  %s${NC}\n" "$OCR_SCOPE_MSG"
  printf "  ${DIM}  Install manually: brew install tesseract${NC}\n"
  return 0
}

install_optional_deps() {
  if check_command tesseract; then
    printf "  ${GREEN}✓${NC} Tesseract OCR already available\n"
    return 0
  fi

  if [ "$OS" = "darwin" ]; then
    install_tesseract_macos
    return 0
  fi

  if [ "$OS" = "linux" ]; then
    if check_command apt-get; then
      run_with_sudo "Tesseract OCR (tesseract-ocr)" apt-get install -y tesseract-ocr || ignore_failure_unless_interrupted
    elif check_command dnf; then
      run_with_sudo "Tesseract OCR" dnf install -y tesseract || ignore_failure_unless_interrupted
    elif check_command pacman; then
      run_with_sudo "Tesseract OCR" pacman -S --noconfirm tesseract || ignore_failure_unless_interrupted
    fi
  fi

  if check_command tesseract; then
    printf "  ${GREEN}✓${NC} Tesseract OCR installed\n"
    return 0
  fi

  printf "  ${YELLOW}⚠${NC}  Tesseract OCR not installed\n"
  printf "  ${DIM}  %s${NC}\n" "$OCR_SCOPE_MSG"
  if can_sudo_noninteractive || has_install_tty; then
    printf "  ${DIM}  Install manually: sudo apt install tesseract-ocr (Ubuntu)${NC}\n"
  else
    printf "  ${DIM}  Re-run in an interactive terminal, or install manually: sudo apt install tesseract-ocr${NC}\n"
  fi
  return 0
}

# ─── Animated step runner ────────────────────────────────────────────

run_step() {
  local msg="$1"
  shift
  local interactive=false
  if [ "${1:-}" = "--interactive" ]; then
    interactive=true
    shift
  fi

  if $interactive; then
    printf "  ${CYAN}⟡${NC} %s\n" "$msg" >&2
    if "$@"; then
      printf "  ${GREEN}✓${NC} %s\n" "$msg" >&2
    else
      local rc=$?
      if [ "$rc" -eq 130 ] || [ "$rc" -eq 143 ]; then
        exit "$rc"
      fi
      die "$msg failed"
    fi
    return
  fi

  mission_phrase > /dev/null
  start_progress "$msg"
  if "$@"; then
    stop_progress "true" "$msg"
  else
    local rc=$?
    stop_progress "false" "$msg"
    if [ "$rc" -eq 130 ] || [ "$rc" -eq 143 ]; then
      exit "$rc"
    fi
    die "$msg failed"
  fi
}

# ─── Main ────────────────────────────────────────────────────────────

main() {
  clear 2>/dev/null || printf "\033c" 2>/dev/null || true
  telemetry_header "PRE-LAUNCH"

  printf "  ${DIM}Running pre-flight checks...${NC}\n"
  detect_platform
  check_curl
  check_node
  get_version

  printf "  ${DIM}Telemetry:${NC} ${CYAN}%s${NC} • ${CYAN}Node %s${NC} • ${CYAN}%s${NC}\n\n" "$PLATFORM" "$(node -v)" "$VERSION"
  printf "  ${DIM}Payload:${NC} ${CYAN}Server (headless Web UI)${NC}\n"

  run_step "Clearing previous installation artifacts" clean_existing

  countdown

  printf "\n"

  download_and_install
  run_step "Assembling native modules" rebuild_native
  run_step "Locking navigation coordinates" create_symlink
  run_step "Running payload integrity check" verify_install
  run_step "Installing Tesseract OCR (image text extraction)" --interactive install_optional_deps

  ensure_path
  print_activation_instructions

  INSTALL_COMPLETE=1

  echo ""
  printf "  ${BOLD}✦  DEPLOYMENT COMPLETE  ✦${NC}\n"
  printf "  ${DIM}Agent-X server is now operational.${NC}\n"
  echo ""
  printf "  ${CYAN}Payload:${NC}  ${BOLD}Server (Web UI)${NC}\n"
  echo ""
  printf "  ${CYAN}Engage:${NC}\n"
  printf "    ${BOLD}agentx start${NC}                       Start server daemon\n"
  printf "    ${BOLD}agentx status${NC}                      Check server health\n"
  printf "    ${BOLD}agentx stop${NC}                        Stop server daemon\n"
  printf "    ${BOLD}agentx --help${NC}                      Show CLI help\n"
  echo ""
  printf "  ${DIM}Web UI:${NC} http://127.0.0.1:3333 (or your server IP)\n"
  echo ""
}

main "$@"
