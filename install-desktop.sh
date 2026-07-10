#!/usr/bin/env bash
set -euo pipefail

REPO="that-rookie-dev/agent-x"
VERSION="${AGENTX_VERSION:-latest}"
ARCH="arm64"

echo ""
echo "  Agent-X Desktop Installer"
echo "  ========================="
echo ""

# Stop a running desktop app and remove any previous install.
if pgrep -x "Agent-X" >/dev/null 2>&1 || pgrep -f "/Applications/Agent-X.app" >/dev/null 2>&1; then
  echo "  Stopping running Agent-X..."
  osascript -e 'quit app "Agent-X"' >/dev/null 2>&1 || true
  sleep 1
  pkill -x "Agent-X" 2>/dev/null || true
fi

if [ -d "/Applications/Agent-X.app" ]; then
  echo "  Removing previous installation..."
  rm -rf "/Applications/Agent-X.app"
fi

echo ""

# Resolve latest version
if [ "$VERSION" = "latest" ]; then
  VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
  if [ -z "$VERSION" ]; then
    echo "  Failed to determine latest version."
    exit 1
  fi
  echo "  Latest version: $VERSION"
fi

# Download DMG (resume + retries on flaky links)
DMG_URL="https://github.com/${REPO}/releases/download/${VERSION}/Agent-X-${VERSION#v}-${ARCH}.dmg"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
DMG_FILE="${TMP_DIR}/Agent-X.dmg"
MAX_DOWNLOAD_RETRIES="${AGENTX_DOWNLOAD_RETRIES:-5}"

echo "  Downloading..."
attempt=1
while [ "$attempt" -le "$MAX_DOWNLOAD_RETRIES" ]; do
  if [ "$attempt" -gt 1 ]; then
    partial=0
    [ -f "$DMG_FILE" ] && partial=$(stat -f%z "$DMG_FILE" 2>/dev/null || stat -c%s "$DMG_FILE" 2>/dev/null || echo 0)
    echo "  ⟳ Retry ${attempt}/${MAX_DOWNLOAD_RETRIES} — resuming from ${partial} bytes..."
    sleep 2
  fi
  if curl -fSL -C - "$DMG_URL" -o "$DMG_FILE"; then
    break
  fi
  if [ "$attempt" -eq "$MAX_DOWNLOAD_RETRIES" ]; then
    echo "  Download failed after ${MAX_DOWNLOAD_RETRIES} attempts."
    exit 1
  fi
  echo "  ⚠ Download interrupted — will resume if connection returns."
  attempt=$((attempt + 1))
done
echo "  ✓ Payload Received"

# Optional: Tesseract for image OCR (PDFs use bundled pdf.js inside the app)
if ! command -v tesseract >/dev/null 2>&1 && command -v brew >/dev/null 2>&1; then
  echo "  Installing Tesseract OCR (image text extraction)…"
  if HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install tesseract >/dev/null 2>&1; then
    echo "  ✓ Tesseract OCR installed"
  fi
fi

# Mount DMG
echo "  Installing..."
MOUNT_POINT=$(hdiutil attach "$DMG_FILE" -nobrowse 2>/dev/null | tail -1 | awk '{print $NF}')

# Remove existing app and copy new one
cp -R "$MOUNT_POINT/Agent-X.app" /Applications/

# Strip quarantine — this is the fix for the "damaged" / "unidentified developer" error
xattr -cr /Applications/Agent-X.app

# Detach DMG
hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null || true

echo ""
echo "  Agent-X Desktop installed successfully!"
echo ""
if ! command -v tesseract >/dev/null 2>&1; then
  echo "  Note: Tesseract OCR is not installed."
  echo "  PDFs and text files work without OCR; install Tesseract for image text extraction:"
  echo "    brew install tesseract"
  echo ""
fi

# Launch
echo "  Launching..."
open /Applications/Agent-X.app
