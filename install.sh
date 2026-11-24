#!/usr/bin/env bash
# ==============================================================================
# Cluster Language Toolchain & VS Code Extension Universal Installer
# Compatible with: Linux, macOS, Windows (Git Bash/MSYS2/WSL), and Android Termux
# Author: zk-mohammad <ZaidKhan-alamgir@proton.me>
# License: Cluster Community & Fair-Source License (CCFL v2.0)
# ==============================================================================

set -euo pipefail

REPO_OWNER="cluster-lang"
REPO_NAME="cluster"
EXT_REPO_NAME="vscode-cluster"
VERSION="1.0.0"

echo "=================================================================="
echo "    Installing Cluster Language Toolchain & Developer Tools       "
echo "=================================================================="

# --- 1. Detect OS, Environment, and Architecture ---
OS="$(uname -s 2>/dev/null || echo "Unknown")"
ARCH="$(uname -m 2>/dev/null || echo "Unknown")"
IS_TERMUX=0
IS_WINDOWS=0

if [ -n "${TERMUX_VERSION:-}" ] || [ -d "/data/data/com.termux" ] || [ -n "${PREFIX:-}" ]; then
    IS_TERMUX=1
    PLATFORM="termux"
elif [ -n "${WSL_DISTRO_NAME:-}" ]; then
    PLATFORM="linux-wsl"
else
    case "$OS" in
        Linux)   PLATFORM="linux" ;;
        Darwin)  PLATFORM="macos" ;;
        CYGWIN*|MINGW*|MSYS*|Windows_NT)
            PLATFORM="windows"
            IS_WINDOWS=1
            ;;
        *)
            PLATFORM="linux"
            ;;
    esac
fi

case "$ARCH" in
    x86_64|amd64)   ARCH_NAME="x86_64" ;;
    aarch64|arm64)  ARCH_NAME="aarch64" ;;
    armv7l|armhf)   ARCH_NAME="armv7" ;;
    i386|i686)      ARCH_NAME="x86" ;;
    *)              ARCH_NAME="$ARCH" ;;
esac

echo "[*] Detected Platform:     $PLATFORM"
echo "[*] Detected Architecture: $ARCH_NAME"

# --- 2. Determine Installation Directories ---
if [ "$IS_TERMUX" -eq 1 ]; then
    PREFIX_PATH="${PREFIX:-/data/data/com.termux/files/usr}"
    INSTALL_DIR="$PREFIX_PATH/bin"
    SHARE_DIR="$PREFIX_PATH/share/cluster"
elif [ -w "/usr/local/bin" ] && [ -d "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
    SHARE_DIR="$HOME/.local/share/cluster"
else
    INSTALL_DIR="$HOME/.local/bin"
    SHARE_DIR="$HOME/.local/share/cluster"
fi

mkdir -p "$INSTALL_DIR"
mkdir -p "$SHARE_DIR"

echo "[*] Toolchain Binary Dir:  $INSTALL_DIR"
echo "[*] Core Libraries Dir:    $SHARE_DIR"

# --- 3. Install Compiler and Standard Library ---
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
fi
TEMP_DIR=""

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/bin/cl" ] && [ -d "$SCRIPT_DIR/std" ]; then
    echo "[*] Installing from local repository ($SCRIPT_DIR)..."
    SOURCE_DIR="$SCRIPT_DIR"
elif [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/cl" ] && [ -d "$SCRIPT_DIR/std" ]; then
    echo "[*] Installing from local repository ($SCRIPT_DIR)..."
    SOURCE_DIR="$SCRIPT_DIR"
else
    echo "[*] Fetching Cluster toolchain from GitHub ($REPO_OWNER/$REPO_NAME)..."
    TEMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'cluster_install')"
    trap 'if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then rm -rf "$TEMP_DIR"; fi' EXIT
    
    if command -v git &>/dev/null; then
        git clone --depth 1 "https://github.com/${REPO_OWNER}/${REPO_NAME}.git" "$TEMP_DIR/cluster"
        SOURCE_DIR="$TEMP_DIR/cluster"
    else
        TAR_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/main.tar.gz"
        curl -fsSL "$TAR_URL" -o "$TEMP_DIR/cluster.tar.gz"
        mkdir -p "$TEMP_DIR/cluster"
        tar -xzf "$TEMP_DIR/cluster.tar.gz" -C "$TEMP_DIR/cluster" --strip-components=1
        SOURCE_DIR="$TEMP_DIR/cluster"
    fi
fi

# Copy binary
if [ -f "$SOURCE_DIR/bin/cl" ]; then
    cp -f "$SOURCE_DIR/bin/cl" "$INSTALL_DIR/cl"
elif [ -f "$SOURCE_DIR/cl" ]; then
    cp -f "$SOURCE_DIR/cl" "$INSTALL_DIR/cl"
fi

# Copy cl2 compiler if present
if [ -f "$SOURCE_DIR/bin/cl2" ]; then
    cp -f "$SOURCE_DIR/bin/cl2" "$INSTALL_DIR/cl2"
    chmod +x "$INSTALL_DIR/cl2" 2>/dev/null || true
elif [ -f "$SOURCE_DIR/cl2" ]; then
    cp -f "$SOURCE_DIR/cl2" "$INSTALL_DIR/cl2"
    chmod +x "$INSTALL_DIR/cl2" 2>/dev/null || true
fi

# Copy companion tools & shared libraries if present
if [ -f "$SOURCE_DIR/bin/libclm_bridge.so" ]; then
    cp -f "$SOURCE_DIR/bin/libclm_bridge.so" "$INSTALL_DIR/libclm_bridge.so" 2>/dev/null || true
    mkdir -p "$SHARE_DIR/lib"
    cp -f "$SOURCE_DIR/bin/libclm_bridge.so" "$SHARE_DIR/lib/libclm_bridge.so" 2>/dev/null || true
fi
if [ -f "$SOURCE_DIR/bin/clang" ]; then
    mkdir -p "$SHARE_DIR/bin"
    cp -f "$SOURCE_DIR/bin/clang" "$SHARE_DIR/bin/clang" 2>/dev/null || true
    chmod +x "$SHARE_DIR/bin/clang" 2>/dev/null || true
fi
if [ -f "$SOURCE_DIR/bin/cl-link" ]; then
    mkdir -p "$SHARE_DIR/bin"
    cp -f "$SOURCE_DIR/bin/cl-link" "$SHARE_DIR/bin/cl-link" 2>/dev/null || true
    chmod +x "$SHARE_DIR/bin/cl-link" 2>/dev/null || true
fi
if [ -f "$SOURCE_DIR/bin/cl-strip" ]; then
    mkdir -p "$SHARE_DIR/bin"
    cp -f "$SOURCE_DIR/bin/cl-strip" "$SHARE_DIR/bin/cl-strip" 2>/dev/null || true
    chmod +x "$SHARE_DIR/bin/cl-strip" 2>/dev/null || true
fi

# Ensure executable permissions and compatibility symlinks
chmod +x "$INSTALL_DIR/cl" 2>/dev/null || true
ln -sf "$INSTALL_DIR/cl" "$INSTALL_DIR/cluster" 2>/dev/null || true
ln -sf "$INSTALL_DIR/cl" "$INSTALL_DIR/zk" 2>/dev/null || true

# Copy standard library and runtime
if [ -d "$SOURCE_DIR/std" ]; then
    mkdir -p "$SHARE_DIR/std"
    cp -rf "$SOURCE_DIR/std/"* "$SHARE_DIR/std/" 2>/dev/null || true
fi
if [ -d "$SOURCE_DIR/lib" ]; then
    mkdir -p "$SHARE_DIR/lib"
    cp -rf "$SOURCE_DIR/lib/"* "$SHARE_DIR/lib/" 2>/dev/null || true
fi
if [ -d "$SOURCE_DIR/cluster-packages" ]; then
    mkdir -p "$SHARE_DIR/packages"
    cp -rf "$SOURCE_DIR/cluster-packages/"* "$SHARE_DIR/packages/" 2>/dev/null || true
fi

# --- 4. Configure PATH in Shell Profile ---
ADD_PATH_LINE="export PATH=\"\$PATH:$INSTALL_DIR\""
if [ "$IS_TERMUX" -eq 0 ] && [ "$INSTALL_DIR" != "/usr/local/bin" ]; then
    case "${SHELL:-bash}" in
        */zsh)   TARGET_RC="$HOME/.zshrc" ;;
        */fish)  TARGET_RC="$HOME/.config/fish/config.fish" ;;
        *)       TARGET_RC="$HOME/.bashrc" ;;
    esac

    if [ -f "$TARGET_RC" ]; then
        if ! grep -sq "$INSTALL_DIR" "$TARGET_RC"; then
            echo "" >> "$TARGET_RC"
            echo "# Cluster Programming Language Toolchain" >> "$TARGET_RC"
            if [[ "$TARGET_RC" == *"fish"* ]]; then
                echo "fish_add_path $INSTALL_DIR" >> "$TARGET_RC"
            else
                echo "$ADD_PATH_LINE" >> "$TARGET_RC"
            fi
            echo "[*] Added $INSTALL_DIR to PATH in $TARGET_RC"
        fi
    fi
    
    # Also add to .profile if present
    if [ -f "$HOME/.profile" ] && ! grep -sq "$INSTALL_DIR" "$HOME/.profile"; then
        echo "$ADD_PATH_LINE" >> "$HOME/.profile"
    fi
fi

# --- 5. Install Official VS Code Extension for Colorful Syntax Experience ---
echo "[*] Setting up official VS Code extension for Cluster (.cl, .zk, .cld)..."

VSCODE_EXT_DIRS=(
    "$HOME/.vscode/extensions"
    "$HOME/.vscode-server/extensions"
    "$HOME/.vscode-insiders/extensions"
    "$HOME/.cursor/extensions"
    "$HOME/.vscode-oss/extensions"
)

if [ -n "${USERPROFILE:-}" ] && [ -d "$USERPROFILE/.vscode" ]; then
    VSCODE_EXT_DIRS+=("$USERPROFILE/.vscode/extensions")
fi

EXT_DEST_NAME="cluster-lang.vscode-cluster-1.0.0"
INSTALLED_VSCODE_COUNT=0

# Locate extension source
VSCODE_EXT_TMP=""
if [ -d "$SOURCE_DIR/../vscode-cluster" ] && [ -f "$SOURCE_DIR/../vscode-cluster/package.json" ]; then
    VSCODE_EXT_SOURCE="$SOURCE_DIR/../vscode-cluster"
elif [ -d "/media/alamgir-zk/debian13-hdd/alamgir-zk/zk-company/cluster-lang-org/vscode-cluster" ]; then
    VSCODE_EXT_SOURCE="/media/alamgir-zk/debian13-hdd/alamgir-zk/zk-company/cluster-lang-org/vscode-cluster"
else
    VSCODE_EXT_TMP="$(mktemp -d 2>/dev/null || mktemp -d -t 'cluster_vscode')"
    if command -v git &>/dev/null; then
        git clone --depth 1 "https://github.com/${REPO_OWNER}/${EXT_REPO_NAME}.git" "$VSCODE_EXT_TMP" 2>/dev/null || true
    fi
    if [ ! -f "$VSCODE_EXT_TMP/package.json" ]; then
        EXT_TAR_URL="https://github.com/${REPO_OWNER}/${EXT_REPO_NAME}/archive/refs/heads/main.tar.gz"
        curl -fsSL "$EXT_TAR_URL" -o "$VSCODE_EXT_TMP/ext.tar.gz" 2>/dev/null || true
        tar -xzf "$VSCODE_EXT_TMP/ext.tar.gz" -C "$VSCODE_EXT_TMP" --strip-components=1 2>/dev/null || true
    fi
    VSCODE_EXT_SOURCE="$VSCODE_EXT_TMP"
fi

if [ -d "$VSCODE_EXT_SOURCE" ] && [ -f "$VSCODE_EXT_SOURCE/package.json" ]; then
    for ext_dir in "${VSCODE_EXT_DIRS[@]}"; do
        if [ -d "$(dirname "$ext_dir")" ]; then
            mkdir -p "$ext_dir/$EXT_DEST_NAME"
            cp -rf "$VSCODE_EXT_SOURCE/package.json" "$ext_dir/$EXT_DEST_NAME/" 2>/dev/null || true
            cp -rf "$VSCODE_EXT_SOURCE/language-configuration.json" "$ext_dir/$EXT_DEST_NAME/" 2>/dev/null || true
            if [ -d "$VSCODE_EXT_SOURCE/syntaxes" ]; then
                mkdir -p "$ext_dir/$EXT_DEST_NAME/syntaxes"
                cp -rf "$VSCODE_EXT_SOURCE/syntaxes/"* "$ext_dir/$EXT_DEST_NAME/syntaxes/" 2>/dev/null || true
            fi
            if [ -d "$VSCODE_EXT_SOURCE/icons" ]; then
                mkdir -p "$ext_dir/$EXT_DEST_NAME/icons"
                cp -rf "$VSCODE_EXT_SOURCE/icons/"* "$ext_dir/$EXT_DEST_NAME/icons/" 2>/dev/null || true
            fi
            INSTALLED_VSCODE_COUNT=$((INSTALLED_VSCODE_COUNT + 1))
        fi
    done
fi

VSIX_FILE="$VSCODE_EXT_SOURCE/vscode-cluster-1.0.0.vsix"
if [ -f "$VSIX_FILE" ]; then
    if command -v code &>/dev/null; then
        code --install-extension "$VSIX_FILE" --force &>/dev/null || true
        INSTALLED_VSCODE_COUNT=$((INSTALLED_VSCODE_COUNT + 1))
    fi
    if command -v cursor &>/dev/null; then
        cursor --install-extension "$VSIX_FILE" --force &>/dev/null || true
        INSTALLED_VSCODE_COUNT=$((INSTALLED_VSCODE_COUNT + 1))
    fi
    if command -v codium &>/dev/null; then
        codium --install-extension "$VSIX_FILE" --force &>/dev/null || true
        INSTALLED_VSCODE_COUNT=$((INSTALLED_VSCODE_COUNT + 1))
    fi
fi

if [ -n "$VSCODE_EXT_TMP" ] && [ -d "$VSCODE_EXT_TMP" ]; then
    rm -rf "$VSCODE_EXT_TMP"
fi

if [ "$INSTALLED_VSCODE_COUNT" -gt 0 ]; then
    echo "[✓] VS Code Cluster extension installed and activated!"
else
    echo "[!] Notice: VS Code directory not found yet. Extension will activate as soon as VS Code is opened."
fi

echo ""
echo "=================================================================="
echo "    ✓ Cluster Language v${VERSION} Installed Successfully!       "
echo "=================================================================="
echo "  Compiler Binary: $INSTALL_DIR/cl"
echo "  Standard Lib:    $SHARE_DIR/std"
echo "  VS Code Theme:   Full syntax highlighting ready for .cl, .zk, .cld"
echo ""
echo "Quick Test:"
echo "  $INSTALL_DIR/cl --version"
echo ""
echo "To activate in your current terminal, run:"
if [ "$IS_TERMUX" -eq 1 ] || [ "$INSTALL_DIR" = "/usr/local/bin" ]; then
    echo "  cl --version"
else
    echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
fi
echo "=================================================================="
