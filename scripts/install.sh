#!/usr/bin/env bash
set -euo pipefail

REPO="bananacoffeecode/tempo-time-tracker"
APP_NAME="Tempo"
INSTALL_DIR="/Applications"

# Colours
GREEN='\033[0;32m'
GREY='\033[0;90m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${GREEN}Installing Tempo...${NC}"
echo ""

# Detect architecture
VERSION="1.1.0"
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
  ASSET="Tempo-${VERSION}-arm64.dmg"
else
  ASSET="Tempo-${VERSION}.dmg"
fi

echo -e "${GREY}→ Detected architecture: $ARCH${NC}"
echo -e "${GREY}→ Downloading $ASSET from latest release...${NC}"

TMP_DIR=$(mktemp -d)
DMG_PATH="$TMP_DIR/$ASSET"

curl -fsSL "https://github.com/$REPO/releases/latest/download/$ASSET" -o "$DMG_PATH"

echo -e "${GREY}→ Mounting disk image...${NC}"
MOUNT_DIR=$(mktemp -d)
hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_DIR" -quiet -nobrowse

echo -e "${GREY}→ Installing to $INSTALL_DIR...${NC}"
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
  rm -rf "$INSTALL_DIR/$APP_NAME.app"
fi
cp -R "$MOUNT_DIR/$APP_NAME.app" "$INSTALL_DIR/"

hdiutil detach "$MOUNT_DIR" -quiet
rm -rf "$TMP_DIR"

echo -e "${GREY}→ Removing macOS quarantine flag...${NC}"
xattr -dr com.apple.quarantine "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ Tempo installed successfully.${NC}"
echo -e "${GREY}  Open it from /Applications or search Spotlight for \"Tempo\".${NC}"
echo ""
