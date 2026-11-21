#!/usr/bin/env bash
# ==============================================================================
# Cluster Language v1.0.0 Unified Installer (Linux & macOS)
# Installs 'zk' developer CLI, 'zkc2' native compiler, and core standard library.
# ==============================================================================

set -euo pipefail

REPO="cl-andro/cluster-lang"
VERSION="1.0.0"
BIN_NAME="zk"

# --- Detect OS and Architecture ---
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux)  OS="linux" ;;
  Darwin) OS="macos" ;;
  *)      echo "Unsupported OS: $OS"; exit 1 ;;
esac

case "$ARCH" in
  x86_64|amd64) ARCH="x86_64" ;;
  aarch64|arm64) ARCH="aarch64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "Detected Platform: $OS-$ARCH"

# --- Determine Install Directories ---
if [ -d "$HOME/.local/bin" ] && [ -w "$HOME/.local/bin" ]; then
    INSTALL_DIR="$HOME/.local/bin"
elif [ -d "$HOME/.local/bin" ]; then
    mkdir -p "$HOME/.local/bin"
    INSTALL_DIR="$HOME/.local/bin"
elif [ -w "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
else
    mkdir -p "$HOME/.local/bin"
    INSTALL_DIR="$HOME/.local/bin"
fi

SHARE_DIR="$HOME/.local/share/cluster"
mkdir -p "$INSTALL_DIR"
mkdir -p "$SHARE_DIR"

echo "Binary Target:  $INSTALL_DIR"
echo "Package Target: $SHARE_DIR"

# --- Ensure INSTALL_DIR is in PATH ---
case "${SHELL:-bash}" in
    */zsh)   RC_FILE="$HOME/.zshrc" ;;
    */fish)  RC_FILE="$HOME/.config/fish/config.fish" ;;
    *)       RC_FILE="$HOME/.bashrc" ;;
esac

case "${SHELL:-bash}" in
    */fish)  LINE="fish_add_path $INSTALL_DIR" ;;
    *)       LINE="export PATH=\"\$PATH:$INSTALL_DIR\"" ;;
esac

if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
    if [ -f "$RC_FILE" ] && ! grep -sq "$INSTALL_DIR" "$RC_FILE"; then
        echo "$LINE" >> "$RC_FILE"
        echo "Added $INSTALL_DIR to PATH in $RC_FILE"
    fi
fi

# --- Check Clang / LLVM Toolchain ---
if ! command -v clang &>/dev/null && ! command -v g++ &>/dev/null; then
    echo "Notice: Clang / LLVM is recommended for native compilation."
fi

# --- Check if installing from local repo ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/zk" ] && [ -f "$SCRIPT_DIR/cluster_compiler/v2/cl-binary/zkc2.out" ]; then
    echo "Found local Cluster repository. Installing directly from source tree..."
    
    # Copy binaries
    cp "$SCRIPT_DIR/zk" "$INSTALL_DIR/zk"
    cp "$SCRIPT_DIR/cluster_compiler/v2/cl-binary/zkc2.out" "$INSTALL_DIR/zkc2"
    chmod +x "$INSTALL_DIR/zk" "$INSTALL_DIR/zkc2"
    
    # Backwards compatibility symlink
    ln -sf "$INSTALL_DIR/zk" "$INSTALL_DIR/cluster-zk" 2>/dev/null || true
    
    # Copy runtime and standard library to share dir
    mkdir -p "$SHARE_DIR/lib/runtime"
    mkdir -p "$SHARE_DIR/std"
    cp "$SCRIPT_DIR/cluster_compiler/v2/runtime/concurrency.o" "$SHARE_DIR/lib/runtime/" 2>/dev/null || true
    cp "$SCRIPT_DIR/cluster_compiler/v2/runtime/concurrency.c" "$SHARE_DIR/lib/runtime/" 2>/dev/null || true
    cp -r "$SCRIPT_DIR/std/"* "$SHARE_DIR/std/" 2>/dev/null || true
    
    echo ""
    echo "======================================================"
    echo " Cluster v${VERSION} Installed Successfully!"
    echo "======================================================"
    "$INSTALL_DIR/zk" version
    exit 0
fi

# --- Download Standalone Distribution from GitHub Releases ---
TAR_NAME="cluster-v${VERSION}-${OS}-${ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/v${VERSION}/${TAR_NAME}"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "Downloading Cluster v${VERSION} (${TAR_NAME})..."
if command -v curl &>/dev/null; then
    curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_DIR/$TAR_NAME" || true
elif command -v wget &>/dev/null; then
    wget -q "$DOWNLOAD_URL" -O "$TEMP_DIR/$TAR_NAME" || true
fi

if [ ! -s "$TEMP_DIR/$TAR_NAME" ]; then
    echo "Notice: Release archive not found online. Please clone repo and run ./install.sh locally."
    exit 1
fi

tar -xzf "$TEMP_DIR/$TAR_NAME" -C "$TEMP_DIR"
EXTRACTED_DIR="$TEMP_DIR/cluster-v${VERSION}-${OS}-${ARCH}"

cp "$EXTRACTED_DIR/bin/zk" "$INSTALL_DIR/zk"
cp "$EXTRACTED_DIR/bin/zkc2" "$INSTALL_DIR/zkc2"
chmod +x "$INSTALL_DIR/zk" "$INSTALL_DIR/zkc2"
ln -sf "$INSTALL_DIR/zk" "$INSTALL_DIR/cluster-zk" 2>/dev/null || true

cp -r "$EXTRACTED_DIR/lib" "$SHARE_DIR/"
cp -r "$EXTRACTED_DIR/std" "$SHARE_DIR/"

echo ""
echo "======================================================"
echo " Cluster Language v${VERSION} Installed Successfully!"
echo "======================================================"
echo "  Run: zk --version"
echo "  Run: zk run hello.zk"
echo ""
echo "If 'zk' is not found in your terminal, run: source $RC_FILE"
